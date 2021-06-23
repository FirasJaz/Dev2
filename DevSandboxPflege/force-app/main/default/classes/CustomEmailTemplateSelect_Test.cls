@isTest
private class CustomEmailTemplateSelect_Test {

    static testMethod void myUnitTest() {
        PageReference pageRef = Page.CustomEmailTemplateSelect;
        pageRef.getParameters().put('returnURL', '/apex/Brief_Schreiben_Form');
        Test.setCurrentPage(pageRef);
        CustomEmailTemplateSelect_Controller cets = new CustomEmailTemplateSelect_Controller();
        PageReference pr = cets.PassTemplateIdToReturnURL();
        ID etid = cets.etid;
        EmailTemplate[] ets = cets.EmailTemplates;
    }
}