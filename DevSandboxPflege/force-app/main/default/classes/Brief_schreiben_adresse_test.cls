@isTest
private class Brief_schreiben_adresse_test {
    static testMethod void briefSchreibenUnitTest(){
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.Art_des_Kontakts__c='kein';
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        a.Kategorie__c = '01 Ambulante Pflegedienste';
        a.Anzahl_der_Patienten__c = 'monatliche Anforderungsliste';
        insert a;
        c.AccountId=a.Id;
        insert c;
        k.Betreuer__c = c.ID;
        k.Pflegedienst__c = a.Id;
        insert k;        
        Brief_schreiben_controller_class bc = new Brief_schreiben_controller_class();
         
        
    }
    
    static testMethod void myUnitTest() {
        Brief_schreiben_adresse b = new Brief_schreiben_adresse();       
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.Art_des_Kontakts__c='kein';
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        a.Kategorie__c = '01 Ambulante Pflegedienste';
        a.Anzahl_der_Patienten__c = 'monatliche Anforderungsliste';
        insert a;
        c.AccountId=a.Id;
        insert c;
        k.Betreuer__c = c.ID;
        k.Pflegedienst__c = a.Id;
        insert k;

        b = new Brief_schreiben_adresse(k.Id);
        
        b.hatFehler();
        b.getHasMail();
        b.getHasAddr();
        b.getmailHinweis();
        b.getAddrHinweis();
        b.getAnredeformel();
        b.getKunde();
        b.getMailTo();
        b.getSelectedRcpt();
        b.getAddressRecord();
    }
    
    
}