@isTest //(seealldata=false)
public with sharing class abrechnung_pflegekassen_test {
    static testMethod void myUnitTest() {         
        abrechnung_pflegekassen ext1 = new abrechnung_pflegekassen();
        PageReference tpageRef = Page.abrechnung_pflegekassen;
        Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('call', 'los');
        ApexPages.currentPage().getParameters().put('kk', 'test ziaei');
        ext1.getAufruf();
        ext1.getKkName();       
        ext1.goBack();
        ext1.startBatch();
        ext1.setKkName('test');
        ext1.createAndSend();
        ext1.getnoOfRecords();
        ext1.setMfKunden('Medifox');
        ext1.getMfKunden();
        list<SelectOption> mfKundenSelect = ext1.mfKundenSelect;
    }
}