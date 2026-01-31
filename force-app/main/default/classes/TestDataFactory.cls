/**
 * @description Factory for creating shared test data.
 */
@IsTest
public class TestDataFactory {
    /**
     * @description Creates baseline Contact records for tests.
     */
    public static void createContacts() {
        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'Test',
                LastName = 'US Address',
                MailingStreet = '1428 Post Aly',
                MailingCity = 'Seattle',
                MailingState = 'WA',
                MailingPostalCode = '98101',
                MailingCountry = 'US',
                AddressValid__c = false
            ),
            new Contact(
                FirstName = 'Test',
                LastName = 'Intl Address',
                MailingStreet = 'De Bleek 7',
                MailingCity = 'Woerden',
                MailingState = null,
                MailingPostalCode = '3447 GV',
                MailingCountry = 'NL',
                AddressValid__c = false
            )
        };

        insert contacts;
    }
}
