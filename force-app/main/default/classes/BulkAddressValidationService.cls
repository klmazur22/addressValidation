/**
 * @description Service class to handle bulk address validation for Contact records.
 */
public with sharing class BulkAddressValidationService {

    /**
     * @description Validates addresses for a set of Contact records in bulk by enqueuing a Queueable job.
     *
     * @param contactIdSet Set of Contact record IDs to validate.
     */
    public static void validateContacts(Set<Id> contactIdSet) {
        if (contactIdSet?.size() > 0) {
            List<Contact> contactList = [
                SELECT Id,
                       MailingStreet,
                       MailingCity,
                       MailingState,
                       MailingPostalCode,
                       MailingCountry
                FROM Contact
                WHERE Id IN :contactIdSet
            ];

            if (!contactList.isEmpty()) {
                List<AddressValidationDTO> payload = new List<AddressValidationDTO>();
                for (Contact contact : contactList) {
                    payload.add(new AddressValidationDTO(contact));
                }
                System.enqueueJob(new BulkAddressValidationQueueable(payload));
                System.debug('Enqueued job for ' + contactIdSet.size() + ' contacts at time: ' + Datetime.now());
            }
        }
    }

    /**
     * @description Aura-enabled entry point that accepts Contact Ids, deduplicates, and delegates to validateContacts.
     *
     * @param contactIdList List of Contact record IDs to validate.
     */
    @AuraEnabled
    public static void validateContactsAura(List<Id> contactIdList) {
        if (contactIdList?.size() > 0) {
            Set<Id> contactIdSet = new Set<Id>(contactIdList);
            validateContacts(contactIdSet);
        }
    }

    /**
     * @description Invocable method for validating Contact addresses in bulk via Flow.
     *
     * @param contactIdList List of Contact record IDs to validate.
     */
    @InvocableMethod(label='Validate Contact Addresses' description='Enqueue bulk address validation for Contact records.')
    public static void validateContactsInvocable(List<Id> contactIdList) {
        if (contactIdList?.size() > 0) {
            validateContacts(new Set<Id>(contactIdList));
        }
    }
}
