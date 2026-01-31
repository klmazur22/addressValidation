List<Contact> validatedContactList = [
    SELECT Id
    FROM Contact
    WHERE AddressValid__c = true
];
for(Contact contact : validatedContactList){
    contact.AddressValid__c = false;
}
update validatedContactList;
System.debug('Script start time: ' + Datetime.now());
Map<Id, Contact> contactMap = new Map<Id, Contact>([
    SELECT Id
    FROM Contact
    WHERE MailingCountry != null
    LIMIT 60
]);
BulkAddressValidationService.validateContacts(contactMap.keyset());