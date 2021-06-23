@isTest//(SeeAllData=true)
public with sharing class AuftragAbgelaufenBatchClass_test {

    static testMethod void myUnitTest() {
        
        Account KK = new Account(name = 'TestKundenKrankenkasse', industry='Krankenkassen');
        insert KK;
        Kunde__c KU = new Kunde__c(Name__c = 'TestKunde', Krankenkasse__c = KK.Id, Produktgruppe__c = 'PG54');
        insert KU;
        
        Kundenstatus__c ks = new Kundenstatus__c( Kunde__c = KU.id,
                                                   Status__c = 'Kündigung',
                                                   Produktgruppe__c = 'PG54');
                                                   
                                                   
        Artikel__c art = new Artikel__c();
        insert art;
        date genehmigt_bis = date.today().addMonths(-1);
        Auftrag__c AU = new Auftrag__c(Kunde__c = KU.id,
                                        Bezeichnung__c = 'CB1', 
                                        unbefristet_genehmigt__c = false, 
                                        Genehmigungsstatus__c = 'genemigt',
                                        genehmigt_bis__c = genehmigt_bis);
        insert AU;
        Auftragsposition__c AP  = new Auftragsposition__c(Kunde__c = KU.id,
                                                            Auftrag__c = AU.id,
                                                            Restmenge__c = 10 );
        insert AP;
        Lieferscheinposition__c LP = new Lieferscheinposition__c(Kunde__c = KU.id,
                                                                Artikel__c = Data_For_Tests_Class.createArtikel(1).Id,
                                                                Auftragsposition__c = AP.id, 
                                                                Status__c = 'Bedarf',
                                                                Menge__c = 10);
            insert LP;
 
    
          
        ID batchprocessid = Database.executeBatch(new AuftragAbgelaufenBatchClass() ,200);
         
             
        
    }
}