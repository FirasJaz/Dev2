@isTest
private class Bedarfsmeldung_Test {
/*    static testMethod void Bedarfsmeldung_method_Test(){
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        a.Kategorie__c = '01 Ambulante Pflegedienste';
        a.Anzahl_der_Patienten__c = 'monatliche Anforderungsliste';
        insert a;
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.AccountId=a.Id;
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        k.Pflegedienst__c = a.Id;
        insert k;
        Auftrag__c testAuftrag = new Auftrag__c();
        testAuftrag.Kunde__c = k.Id;
        insert testAuftrag;
            
        Bedarfsmeldung_method bedarfsmeldung_method = new Bedarfsmeldung_method();
        bedarfsmeldung_method.monatsNamenFuellen();
        integer testNumber = 12;
        bedarfsmeldung_method = new Bedarfsmeldung_method(testNumber);
    }
    */
    
    static testMethod void Bedarfsmeldung_aufruf_Test(){
    Bedarfsmeldung_method bedarfsmeldung_method = new Bedarfsmeldung_method('dummy');
    bedarfsmeldung_method.setLeereZeilen();
        Bedarfsmeldung_aufruf b = new Bedarfsmeldung_aufruf();
        b.abbrechen();
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        a.Kategorie__c = '01 Ambulante Pflegedienste';
        a.Anzahl_der_Patienten__c = 'monatliche Anforderungsliste';
        insert a;
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.AccountId=a.Id;
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        k.Pflegedienst__c = a.Id;
        insert k;
        Auftrag__c testAuftrag = new Auftrag__c(Bezeichnung__c = 'CB1');
        testAuftrag.Kunde__c = k.Id;
        insert testAuftrag;
        ApexPages.StandardController sc = new ApexPages.standardController(testAuftrag);
      b = new Bedarfsmeldung_aufruf(sc);
        b.getZeilen();
        b.fillBedarfMonat(2);
        b.readBedarfMonat(2);
        b.getBedarfJahr();
        b.getBedarfMonat();
        b.getPb7();
        b.getAnzahlPD();
        b.setLeereZeilen();
    }
    
    static testMethod void Bedarfsmeldung_aufruf_perEmail(){
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        insert a;
   
        
        ApexPages.StandardController sc = new ApexPages.standardController(a);
      Bedarfsmeldung_aufruf b = new Bedarfsmeldung_aufruf(sc);
       b.setLeereZeilen();
        asMAil__c asMail = new asMail__c(name = 'Bedarfsmeldung');
        asMail.toAddr__c = 'mansoure.ziaei@gmail.com';
        asMail.toCC__c = 'mansoure.ziaei@gmail.com';
        
        insert asMail;
        try{
            b.perEmail();
        }catch(Exception e){}
    }
        
    
    static testMethod void Bedarfsmeldung_Test(){
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        a.Kategorie__c = '01 Ambulante Pflegedienste';
        a.Anzahl_der_Patienten__c = 'monatliche Anforderungsliste';
        insert a;
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.AccountId=a.Id;
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        k.Pflegedienst__c = a.Id;
        insert k;
        Auftrag__c testAuftrag = new Auftrag__c(Bezeichnung__c = 'CB1');
        testAuftrag.Kunde__c = k.Id;
        insert testAuftrag;
        PageReference tpageRef = Page.Bedarfsmeldung;
      Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('von', '0');

      ApexPages.StandardController sc = new ApexPages.standardController(testAuftrag);
      Bedarfsmeldung b = new Bedarfsmeldung(sc);
        b = new Bedarfsmeldung();
        b.setLeereZeilen();
    }

}