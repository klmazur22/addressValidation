/**
 * @description Wrapper class for Smarty International address validation response.
 */
public with sharing class SmartyAddressValidationINTWrapper {
    public Analysis analysis;

    public class Analysis {
        public String verification_status;
    }
}