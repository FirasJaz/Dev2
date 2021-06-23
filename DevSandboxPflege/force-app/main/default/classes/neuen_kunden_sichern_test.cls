// wds 21.01.2013
@isTest
private class neuen_kunden_sichern_test {

    static testMethod void myUnitTest() { 
        Boolean error = false;
        
        Account b=new Account(Name = 'Test KK');
        b.industry='Krankenkassen';
        insert b;
        Kunde__c c = new Kunde__c(Name__c='Testkunde', Produktgruppe__c='PG54');
        
        c.KdNummerfreibis__c='59999';
        c.Kundennummer__c=12345;
        c.Krankenkasse__c=b.id;
        insert c;
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde');
        
        k.Zuzahlung_befreit__c = true;
        k.Produktgruppe__c = 'PG54';
        error = neuen_kunden_sichern_class.neuen_kunden_sichern_func(k);
        system.assert(true==error);
        k.Zuzahlung_befreit_von__c = date.today();
        Account kk = new Account(Name = 'Test Hamburg');
        kk.Industry='kein';
        insert kk;
        k.Krankenkasse__c = kk.ID;
        k.Vorname__c = 'Test';
        k.Zuzahlung_befreit__c = false;
        neuen_kunden_sichern_class.neuen_kunden_sichern_func(k);
        k.Anrede__c = 'Test';
        neuen_kunden_sichern_class.neuen_kunden_sichern_func(k);
        k.Zuzahlung_befreit__c = true;
        k.Vorname__c = null;
        neuen_kunden_sichern_class.neuen_kunden_sichern_func(k);
    }
}