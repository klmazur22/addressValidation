public with sharing class BulkAddressValidationService {

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
