/**
 * @description Service class to handle bulk address validation for Contact records.
 */
public with sharing class BulkAddressValidationService {

    /**
     * @description Validates addresses for a set of Contact records in bulk by enqueuing a Queueable job.
     *
     * @param contactIdSet Set of Contact record IDs to validate.
     */
    @AuraEnabled
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
            }
        }
    }
}
