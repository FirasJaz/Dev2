@isTest(seealldata=false)
private class ksgRecreatePDF_test {

    static testMethod void myUnitTest() {
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        k.Name = 'Testkunde';
        insert k;
        Rechnung__c r = new Rechnung__c(Rechnungsnummer_shop__c = 'testrn');
        r.Kunde__c = k.id;
        insert r;
        Rechnungsposition__c rp = new Rechnungsposition__c();
        rp.Rechnung__c = r.Id;
        rp.Kunde__c = k.id;
        insert rp;
        Rechnungsposition__c rpv = new Rechnungsposition__c();
        rpv.Rechnung__c = r.Id;
        rpv.Kunde__c = k.id;
        rpv.Versandkosten__c = true;
        insert rpv;     
        PageReference pRef1 = Page.ksgRecreatePDF;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', r.id);
        
        ApexPages.StandardController con1 = new ApexPages.StandardController(r);
        ksgRecreatePDF ext1 = new ksgRecreatePDF(con1);
        
        ext1.createInvoicePDF();    
    
    }

}