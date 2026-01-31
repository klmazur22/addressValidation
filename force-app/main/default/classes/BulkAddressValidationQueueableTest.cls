/**
 * @description Test coverage for BulkAddressValidationQueueable.
 */
@IsTest
public with sharing class BulkAddressValidationQueueableTest {
    /**
     * @description Creates test data for all test methods.
     */
    @testSetup
    private static void setup() {
        TestDataFactory.createContacts();
    }

    /**
     * @description Returns a single Contact for the provided mailing country.
     *
     * @param country MailingCountry to filter by.
     */
    private static Contact getContactByCountry(String country) {
        return [
            SELECT Id,
                   FirstName,
                   LastName,
                   AddressValid__c,
                   MailingStreet,
                   MailingCity,
                   MailingState,
                   MailingPostalCode,
                   MailingCountry
            FROM Contact
            WHERE MailingCountry = :country
            LIMIT 1
        ];
    }

    /**
     * @description Returns a Contact by Id with AddressValid__c only.
     *
     * @param contactId Contact Id to query.
     */
    private static Contact getContactById(Id contactId) {
        return [
            SELECT Id,
                   AddressValid__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
    }

    /**
     * @description Validates US bulk processing with multiple records.
     */
    @IsTest
    private static void testQueueableUSBulk() {
        Contact contact = getContactByCountry('US');
        Contact clonedContact = contact.clone(false, true, false, false);
        insert clonedContact;

        TestMockFactory.setSmartyAPIMock(true, true, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(
            new List<AddressValidationDTO>{
                new AddressValidationDTO(contact),
                new AddressValidationDTO(clonedContact)
            }
        ));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Contact clonedAfterQueueableJob = getContactById(clonedContact.Id);
        Assert.isTrue(
            contactAfterQueueableJob.AddressValid__c,
            'Expected US bulk record to be marked valid when precision is not "none".'
        );
        Assert.isTrue(
            clonedAfterQueueableJob.AddressValid__c,
            'Expected cloned US bulk record to be marked valid when precision is not "none".'
        );
    }

    /**
     * @description Validates international bulk processing with multiple records.
     */
    @IsTest
    private static void testQueueableInternationalBulk() {
        Contact contact = getContactByCountry('NL');
        Contact clonedContact = contact.clone(false, true, false, false);
        insert clonedContact;

        TestMockFactory.setSmartyAPIMock(false, true, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(
            new List<AddressValidationDTO>{
                new AddressValidationDTO(contact),
                new AddressValidationDTO(clonedContact)
            }
        ));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Contact clonedAfterQueueableJob = getContactById(clonedContact.Id);
        Assert.isTrue(
            contactAfterQueueableJob.AddressValid__c,
            'Expected international bulk record to be marked valid when verification_status is "Verified".'
        );
        Assert.isTrue(
            clonedAfterQueueableJob.AddressValid__c,
            'Expected cloned international bulk record to be marked valid when verification_status is "Verified".'
        );
    }

    /**
     * @description Skeleton for mixed US and international bulk validation.
     */
    @IsTest
    private static void testQueueableValidInternationalAndUSBulk() {
        // TODO: Implement mixed US + non-US bulk validation in one queueable run.
        // This requires a combined mock that can return different responses
        // for US and international endpoints in the same test execution.
        // The test should cover different combinations of valid/invalid US and non-US
        // records within a single bulk payload.
    }

    /**
     * @description Validates US address failure path.
     */
    @IsTest
    private static void testQueueableInvalidUSAddressMock() {
        Contact contact = getContactByCountry('US');

        TestMockFactory.setSmartyAPIMock(true, false, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(new List<AddressValidationDTO>{ new AddressValidationDTO(contact) }));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected US address to be marked invalid when precision is "none".'
        );
    }

    /**
     * @description Validates international address failure path.
     */
    @IsTest
    private static void testQueueableInvalidInternationalAddress() {
        Contact contact = getContactByCountry('NL');

        TestMockFactory.setSmartyAPIMock(false, false, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(new List<AddressValidationDTO>{ new AddressValidationDTO(contact) }));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected international address to be marked invalid when verification_status is not "Verified".'
        );
    }

    /**
     * @description Validates missing street does not mark address as valid.
     */
    @IsTest
    private static void testQueueableMissingStreet() {
        Contact contact = getContactByCountry('US');
        contact.MailingStreet = null;
        update contact;

        TestMockFactory.setSmartyAPIMock(true, true, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(new List<AddressValidationDTO>{ new AddressValidationDTO(contact) }));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected address to be marked invalid when MailingStreet is missing.'
        );
    }

    /**
     * @description Validates missing country does not mark address as valid.
     */
    @IsTest
    private static void testQueueableMissingCountry() {
        Contact contact = getContactByCountry('US');
        contact.MailingCountry = null;
        update contact;

        TestMockFactory.setSmartyAPIMock(true, true, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(new List<AddressValidationDTO>{ new AddressValidationDTO(contact) }));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected address to be marked invalid when MailingCountry is missing.'
        );
    }

    /**
     * @description Validates missing record Id in DTO does not update address validity.
     */
    @IsTest
    private static void testQueueableMissingRecordId() {
        Contact contact = getContactByCountry('US');
        AddressValidationDTO dto = new AddressValidationDTO(contact);
        dto.recordId = null;

        TestMockFactory.setSmartyAPIMock(true, true, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(
            new List<AddressValidationDTO>{ dto }
        ));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected address to remain invalid when DTO recordId is missing.'
        );
    }

    /**
     * @description Validates missing US state does not mark address as valid.
     */
    @IsTest
    private static void testQueueableUSMissingState() {
        Contact contact = getContactByCountry('US');
        contact.MailingState = null;
        update contact;

        TestMockFactory.setSmartyAPIMock(true, true, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(new List<AddressValidationDTO>{ new AddressValidationDTO(contact) }));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected US address to be marked invalid when MailingState is missing.'
        );
    }

    /**
     * @description Validates missing US city does not mark address as valid.
     */
    @IsTest
    private static void testQueueableUSMissingCity() {
        Contact contact = getContactByCountry('US');
        contact.MailingCity = null;
        update contact;

        TestMockFactory.setSmartyAPIMock(true, true, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(new List<AddressValidationDTO>{ new AddressValidationDTO(contact) }));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected US address to be marked invalid when MailingCity is missing.'
        );
    }

    /**
     * @description Validates missing international postal code does not mark address as valid.
     */
    @IsTest
    private static void testQueueableMissingPostalCode() {
        Contact contact = getContactByCountry('NL');
        contact.MailingPostalCode = null;
        update contact;

        TestMockFactory.setSmartyAPIMock(false, true, 200);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(new List<AddressValidationDTO>{ new AddressValidationDTO(contact) }));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected international address to be marked invalid when MailingPostalCode is missing.'
        );
    }

    /**
     * @description Validates non-200 response results in invalid address.
     */
    @IsTest
    private static void testQueueableNon200Response() {
        Contact contact = getContactByCountry('US');

        TestMockFactory.setSmartyAPIMock(true, true, 500);

        Test.startTest();
        System.enqueueJob(new BulkAddressValidationQueueable(new List<AddressValidationDTO>{ new AddressValidationDTO(contact) }));
        Test.stopTest();

        Contact contactAfterQueueableJob = getContactById(contact.Id);
        Assert.isFalse(
            contactAfterQueueableJob.AddressValid__c,
            'Expected address to be marked invalid when API response status is not 200.'
        );
    }
}
