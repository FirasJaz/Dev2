// wds 21.01.2013
@isTest
private class neuenKundenerfassenController_test {

    static testMethod void myUnitTest() {
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c='PG54');
        insert k;
        ApexPages.StandardController sc = new ApexPages.StandardController(k);
        neuenKundenerfassenController nkec = new neuenKundenerfassenController(sc);
        try{
            nkec.neuenKundensichern();
        }catch(Exception e){}
        try{
            nkec.neuerKundeZurueck();
        }catch(Exception e){}
        nkec.getRetPage();
        try{
            nkec.changedZuzahlungBefreit();
        }catch(Exception e){}
        
        k.Zuzahlung_befreit__c=true;
        update k;
        ApexPages.StandardController sc1 = new ApexPages.StandardController(k);
        neuenKundenerfassenController nkec1 = new neuenKundenerfassenController(sc1);
        
        try{
            nkec.changedZuzahlungBefreit();
        }catch(Exception e){}
        
    }
}