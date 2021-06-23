@isTest
private class LS_XML_generieren_test {
    static testMethod void myUnitTest() {
        LS_XML_generieren_batch LS_XML_generieren_cl = new LS_XML_generieren_batch('dummy');
        LS_XML_generieren_cl.setLeereZeilen();
        LS_XML_nachbearbeiten_batch LS_XML_nachbearbeiten_batch_cl = new LS_XML_nachbearbeiten_batch();
        LS_XML_nachbearbeiten_batch_cl.setLeereZeilen();
    }
}