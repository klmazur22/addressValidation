/**
 * @description Queueable job to validate addresses in chunks using Smarty US/International APIs.
 * Can be improved to work with different API providers and SObjects via interfaces.
 */
public with sharing class BulkAddressValidationQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer CHUNK_SIZE = 90;
    private static final Set<String> COUNTRY_US_VARIANTS = new Set<String>{ 'US', 'USA', 'United States' };
    private static final String STATUS_VERIFIED = 'Verified';
    private static final String STATUS_PRECISION_NONE = 'none';
    private static final String ENDPOINT_US = 'callout:SmartyUS/street-address';
    private static final String ENDPOINT_INTERNATIONAL = 'callout:SmartyInternational/verify';
    private static final String PARAM_LICENSE = 'license=us-core-cloud';
    private static final String PARAM_STREET = 'street=';
    private static final String PARAM_CITY = 'city=';
    private static final String PARAM_STATE = 'state=';
    private static final String PARAM_ADDRESS1 = 'address1=';
    private static final String PARAM_POSTAL = 'postal_code=';
    private static final String PARAM_COUNTRY = 'country=';

    private List<AddressValidationDTO> payload;

    /**
     * @description Creates a new queueable instance.
     *
     * @param payload List of address DTOs to process.
     */
    public BulkAddressValidationQueueable(List<AddressValidationDTO> payload) {
        this.payload = payload;
    }

    /**
     * @description Executes the queueable job: processes a chunk of addresses, performs callouts, processes response, and enqueues the next chunk if needed.
     *
     * @param context Queueable context.
     */
    public void execute(QueueableContext context) {
        System.debug('Starting address validation at time: ' + Datetime.now());
        if (payload?.size() > 0) {
            Integer total = payload.size();
            Integer chunkLimit = Math.min(CHUNK_SIZE, total);
            List<AddressValidationDTO> current = new List<AddressValidationDTO>();
            List<AddressValidationDTO> remaining = new List<AddressValidationDTO>();

            for (Integer i = 0; i < total; i++) {
                if (i < chunkLimit) {
                    current.add(payload[i]);
                } else {
                    remaining.add(payload[i]);
                }
            }

            Map<Id, Boolean> results = performCallouts(current);
            processResponse(results);

            if (!remaining.isEmpty()) {
                System.enqueueJob(new BulkAddressValidationQueueable(remaining));
                System.debug('Enqueued next job for ' + remaining.size() + ' addresses at time: ' + Datetime.now());
            }
            else {
                System.debug('Completed processing all address validations at time: ' + Datetime.now());
            }
        }
    }

    /**
     * @description Performs callouts for a chunk of DTOs and returns validation results.
     *
     * @param chunk List of DTOs to validate.
     * @return Map of Contact Id to validation result.
     */
    private static Map<Id, Boolean> performCallouts(List<AddressValidationDTO> chunk) {
        Map<Id, Boolean> results = new Map<Id, Boolean>();
        Http http = new Http();

        if (chunk?.size() > 0) {
            for (AddressValidationDTO record : chunk) {
                if (record?.recordId == null) {
                    continue;
                }

                if (String.isBlank(record.street) || String.isBlank(record.country)) {
                    results.put(record.recordId, false);
                    continue;
                }

                HttpRequest request = new HttpRequest();
                request.setMethod('GET');

                // compare country to US/USA/United States variants
                String endpoint = COUNTRY_US_VARIANTS.contains(record.country)
                    ? buildUsEndpoint(record)
                    : buildInternationalEndpoint(record);

                if (endpoint == null) {
                    results.put(record.recordId, false);
                    continue;
                }

                request.setEndpoint(endpoint);

                try {
                    HttpResponse response = http.send(request);
                    Boolean isValid = parseResponse(response, record.country);
                    results.put(record.recordId, isValid);
                } catch (Exception ex) {
                    System.debug('Smarty Adress Verification API Exception: ' + ex.getMessage());
                    // In case of callout failure, mark address as invalid
                    results.put(record.recordId, false);
                }
            }
        }

        return results;
    }

    /**
     * @description Builds the US endpoint URL for a record.
     *
     * @param record Address DTO.
     * @return Fully formed endpoint for US address.
     */
    private static String buildUsEndpoint(AddressValidationDTO record) {
        if (record == null || record.street == null || record.city == null || record.state == null) {
            return null;
        }

        List<String> params = new List<String>{
            PARAM_LICENSE,
            PARAM_STREET + EncodingUtil.urlEncode(record.street, 'UTF-8'),
            PARAM_CITY + EncodingUtil.urlEncode(record.city, 'UTF-8'),
            PARAM_STATE + EncodingUtil.urlEncode(record.state, 'UTF-8')
        };
        return ENDPOINT_US + '?' + String.join(params, '&');
    }

    /**
     * @description Builds the international endpoint URL for a record.
     *
     * @param record Address DTO.
     * @return Fully formed endpoint for international address.
     */
    private static String buildInternationalEndpoint(AddressValidationDTO record) {
        if (record == null || record.street == null || record.postalCode == null || record.country == null) {
            return null;
        }

        List<String> params = new List<String>{
            PARAM_ADDRESS1 + EncodingUtil.urlEncode(record.street, 'UTF-8'),
            PARAM_POSTAL + EncodingUtil.urlEncode(record.postalCode, 'UTF-8'),
            PARAM_COUNTRY + EncodingUtil.urlEncode(record.country, 'UTF-8')
        };
        return ENDPOINT_INTERNATIONAL + '?' + String.join(params, '&');
    }

    /**
     * @description Parses Smarty API response based on country.
     *
     * @param response HTTP response.
     * @param country Country value from the DTO.
     * @return True when validation passes, otherwise false.
     */
    private static Boolean parseResponse(HttpResponse response, String country) {
        if (response?.getStatusCode() != 200) {
            return false;
        }

        if (COUNTRY_US_VARIANTS.contains(country)) {
            SmartyAddressValidationUSWrapper[] items = (SmartyAddressValidationUSWrapper[]) JSON.deserialize(response.getBody(), SmartyAddressValidationUSWrapper[].class);
            if (items?.size() != 1) {
                return false;
            }
            return items[0]?.metadata?.precision != STATUS_PRECISION_NONE;
        }

        SmartyAddressValidationINTWrapper[] items = (SmartyAddressValidationINTWrapper[]) JSON.deserialize(response.getBody(), SmartyAddressValidationINTWrapper[].class);
        if (items?.size() != 1) {
            return false;
        }
        return items[0].analysis?.verification_status == STATUS_VERIFIED;
    }

    /**
     * @description Updates records with validation results.
     *
     * @param results Map of record Id to validation result.
     */
    private static void processResponse(Map<Id, Boolean> results) {
        // For now, we only update Contact records
        // As an improvement, we can create the interface and make this more generic
        // e.g. to handle different SObjects and fields
        if (results?.size() > 0) {
            List<Contact> contactsToUpdate = new List<Contact>();
            for (Id recordId : results.keySet()) {
                contactsToUpdate.add(new Contact(
                    Id = recordId,
                    AddressValid__c = results.get(recordId)
                ));
                System.debug('Contact Id: ' + recordId + ', AddressValid__c: ' + results.get(recordId));
            }

            if (!contactsToUpdate.isEmpty()) {
                update contactsToUpdate;
            }
        }
    }
}
