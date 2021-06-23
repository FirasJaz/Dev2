@isTest
public with sharing class AuftragAbgelaufenBatchClassStart_test {

    static testMethod void myUnitTest() {
        Account KK = new Account(name = 'TestKundenKrankenkasse', industry='Krankenkassen');
        insert KK;
        Kunde__c KU = new Kunde__c(Name__c = 'TestKunde', Krankenkasse__c = KK.Id, Produktgruppe__c = 'PG54');
        insert KU;
        Artikel__c art = new Artikel__c();
        insert art;
        date genehmigt_bis = date.today().addMonths(-1);
        Auftrag__c AU = new Auftrag__c(Kunde__c = KU.id, 
                                        unbefristet_genehmigt__c = false, 
                                        Genehmigungsstatus__c = 'genemigt',
                                        genehmigt_bis__c = genehmigt_bis);
        insert AU;
        Auftragsposition__c AP  = new Auftragsposition__c(Kunde__c = KU.id,
                                                            Auftrag__c = AU.id,
                                                            Restmenge__c = 10 );
        insert AP;
        Lieferscheinposition__c LP = new Lieferscheinposition__c(Kunde__c = KU.id,
                                                                Artikel__c = art.Id,
                                                                Auftragsposition__c = AP.id, 
                                                                Status__c = 'Bedarf',
                                                                Menge__c = 10);
        insert LP;
 
        Test.startTest();
        AuftragAbgelaufenBatchClassStart mobject = new AuftragAbgelaufenBatchClassStart();
        String sch = '0 0 5 * * ?';
        system.schedule('Schedule TEST', sch, mobject);
        Test.stopTest();       
        
    }
}