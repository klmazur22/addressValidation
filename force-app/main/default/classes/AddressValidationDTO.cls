/**
 * @description Data Transfer Object for Bulk Address Validation process.
 */
public with sharing class AddressValidationDTO {
    public Id recordId;
    public String street;
    public String city;
    public String state;
    public String postalCode;
    public String country;

    /**
     * @description Constructor to initialize DTO from Contact record.
     *
     * @param contact Contact record.
     */
    public AddressValidationDTO(Contact contact) {
        recordId = contact.Id;
        street = contact.MailingStreet;
        city = contact.MailingCity;
        state = contact.MailingState;
        postalCode = contact.MailingPostalCode;
        country = contact.MailingCountry;
    }
}