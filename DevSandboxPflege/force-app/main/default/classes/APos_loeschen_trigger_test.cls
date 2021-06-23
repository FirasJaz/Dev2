@isTest
private class APos_loeschen_trigger_test {
    static testMethod void mainTest(){
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c ='Inko');
        insert k;
        Kundenstatus__c ks = new Kundenstatus__c(Kunde__c = k.id, Produktgruppe__c ='Inko');
        insert ks;
        
        Auftrag__c a = new Auftrag__c(Kunde__c = k.Id, Bezeichnung__c = 'Muster-Artikel');
        insert a;
        Auftragsposition__c AP = new Auftragsposition__c(Kunde__c = k.Id,Auftrag__c = a.Id);
        insert AP;
        delete AP;
    }
}