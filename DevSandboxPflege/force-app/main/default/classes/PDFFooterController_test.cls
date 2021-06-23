@isTest
private class PDFFooterController_test {
    static testMethod void main(){
        CompanyInfo__c CI = new CompanyInfo__c (Name = 'Default', GF__c = 'Name Eins, Name Zwei');
        insert CI;
        Test.startTest();
        PDFFooterController PFC = new PDFFooterController();
        CompanyInfo__c CI_test = PFC.getFirmenInfo();
        Test.stopTest();
    }
}