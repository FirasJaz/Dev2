@isTest
public class InvoiceBatchGeneration_test{

    public static testMethod void myUnitTest(){
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        k.Name = 'Testkunde';
        insert k;
        Rechnung__c r = new Rechnung__c();
        r.Kunde__c = k.id;
        r.PDF_generiert__c = false;
        insert r;
        PageReference tpageRef = Page.invoice_batch_generation;
        Test.setCurrentPage(tpageRef);
        InvoiceBatchGeneration ibg = new InvoiceBatchGeneration();
        List<Rechnung__c> RG_List = ibg.zumAbrechnen;
        ibg.generatePdf();
        ibg.first();
        ibg.last();
        ibg.next();
        ibg.previous();
        boolean b =ibg.hasNext;
        b = ibg.hasPrevious;
        ibg.getButtonGenerate();
        integer i = ibg.pageNumber;
    }
}