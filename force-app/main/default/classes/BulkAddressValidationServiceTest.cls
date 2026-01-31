/**
 * @description Test coverage for BulkAddressValidationService.
 */
@IsTest
public class BulkAddressValidationServiceTest {
    /**
     * @description Creates test data for all test methods.
     */
    @testSetup
    private static void setup() {
        TestDataFactory.createContacts();
    }

    /**
     * @description Ensures the Aura-enabled entry point enqueues the queueable job.
     */
    @IsTest
    private static void testValidateContactsAuraEnqueuesJob() {
        Contact contact = [
            SELECT Id,
                   AddressValid__c,
                   MailingStreet,
                   MailingCity,
                   MailingState,
                   MailingPostalCode,
                   MailingCountry
            FROM Contact
            WHERE MailingCountry = 'US'
            LIMIT 1
        ];
        List<Id> contactIds = new List<Id>{ contact.Id };

        TestMockFactory.setSmartyAPIMock(true, true, 200);

        Test.startTest();
        BulkAddressValidationService.validateContactsAura(contactIds);
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id,
                   ApexClass.Name,
                   JobType,
                   Status
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
              AND ApexClass.Name = 'BulkAddressValidationQueueable'
        ];
        Assert.isTrue(
            jobs.size() == 1,
            'Expected one BulkAddressValidationQueueable job to be enqueued, but found ' + jobs.size()
        );
    }
}
