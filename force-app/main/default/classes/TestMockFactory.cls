@IsTest
public class TestMockFactory {
    private class AddressValidationCalloutMock implements HttpCalloutMock {
        private final String responseBody;
        private final Integer statusCode;

        private AddressValidationCalloutMock(String responseBody, Integer statusCode) {
            this.responseBody = responseBody;
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setHeader('Content-Type', 'application/json;charset=UTF-8');
            response.setBody(responseBody);
            return response;
        }
    }

    public static void setSmartyAPIMock(Boolean isUs, Boolean isValid, Integer statusCode) {
        String body = isUs ? buildUsBody(isValid) : buildInternationalBody(isValid);
        Test.setMock(HttpCalloutMock.class, new AddressValidationCalloutMock(body, statusCode));
    }

    private static String buildUsBody(Boolean isValid) {
        SmartyAddressValidationUSWrapper item = new SmartyAddressValidationUSWrapper();
        item.metadata = new SmartyAddressValidationUSWrapper.Metadata();
        item.metadata.precision = isValid ? 'Rooftop' : 'none';
        return JSON.serialize(new List<SmartyAddressValidationUSWrapper>{ item });
    }

    private static String buildInternationalBody(Boolean isValid) {
        SmartyAddressValidationINTWrapper item = new SmartyAddressValidationINTWrapper();
        item.analysis = new SmartyAddressValidationINTWrapper.Analysis();
        item.analysis.verification_status = isValid ? 'Verified' : 'None';
        return JSON.serialize(new List<SmartyAddressValidationINTWrapper>{ item });
    }
}
