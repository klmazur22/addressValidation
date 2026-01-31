/**
 * @description Factory for registering HTTP callout mocks.
 */
@IsTest
public class TestMockFactory {
    /**
     * @description Callout mock that returns a static JSON body.
     */
    private class AddressValidationCalloutMock implements HttpCalloutMock {
        private final String responseBody;
        private final Integer statusCode;

        /**
         * @description Creates a mock with the given body and status.
         *
         * @param responseBody JSON response body.
         * @param statusCode HTTP status code to return.
         */
        private AddressValidationCalloutMock(String responseBody, Integer statusCode) {
            this.responseBody = responseBody;
            this.statusCode = statusCode;
        }

        /**
         * @description Returns a mocked HTTP response.
         *
         * @param request HTTP request.
         */
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setHeader('Content-Type', 'application/json;charset=UTF-8');
            response.setBody(responseBody);
            return response;
        }
    }

    /**
     * @description Registers a Smarty API mock response.
     *
     * @param isUs True for US response, false for international.
     * @param isValid True for valid response, false for invalid.
     * @param statusCode HTTP status code to return.
     */
    public static void setSmartyAPIMock(Boolean isUs, Boolean isValid, Integer statusCode) {
        String body = isUs ? buildUsBody(isValid) : buildInternationalBody(isValid);
        Test.setMock(HttpCalloutMock.class, new AddressValidationCalloutMock(body, statusCode));
    }

    /**
     * @description Builds a US JSON response body with the desired validity.
     *
     * @param isValid True for valid response, false for invalid.
     */
    private static String buildUsBody(Boolean isValid) {
        SmartyAddressValidationUSWrapper item = new SmartyAddressValidationUSWrapper();
        item.metadata = new SmartyAddressValidationUSWrapper.Metadata();
        item.metadata.precision = isValid ? 'Rooftop' : 'none';
        return JSON.serialize(new List<SmartyAddressValidationUSWrapper>{ item });
    }

    /**
     * @description Builds an International JSON response body with the desired validity.
     *
     * @param isValid True for valid response, false for invalid.
     */
    private static String buildInternationalBody(Boolean isValid) {
        SmartyAddressValidationINTWrapper item = new SmartyAddressValidationINTWrapper();
        item.analysis = new SmartyAddressValidationINTWrapper.Analysis();
        item.analysis.verification_status = isValid ? 'Verified' : 'None';
        return JSON.serialize(new List<SmartyAddressValidationINTWrapper>{ item });
    }
}
