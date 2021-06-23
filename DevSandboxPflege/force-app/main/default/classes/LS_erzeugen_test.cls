/****************************************************************************************************************************
// Erstellt 23.04.2018 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  040 23882986
//                         Fax.:  040 23882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: no
//
//****************************************************************************************************************************
//
// Beschreibung: test for LS_erzeugen
//****************************************************************************************************************************
//  Änderungen
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
private class LS_erzeugen_test {
    @testSetup static void setup() {
            // Create common test data
        Account KK = new Account(industry='Krankenkassen');
        KK.Name = 'AOK';
        KK.BillingCity = 'Hamburg';
        KK.BillingState = 'DE';
        KK.BillingStreet = 'Reeperbahn';
        KK.BillingPostalCode = '20301';        
        insert KK;

        Kunde__c kd = new Kunde__c (Anrede__c = 'Herr', Vorname__c = 'Test', Name__c = 'Kunde', 
                                    Kundennummer__c = 10, Krankenkasse__c = KK.id,
                                    Produktgruppe__c = 'PG51;PG54',
                                    Zuzahlung_befreit_von__c = date.Today().addDays(-10),
                                    Zuzahlung_befreit_bis__c = date.Today().addYears(2)
                                    );
        insert kd;

        Anschrift__c an = new Anschrift__c(Kunde__c = kd.id, name='Kunde, Test',  Ort__c='Hamburg', PLZ__c='22222', Stra_e__c='Strasse', 
                                            Kundenadresse__c=true, Standardlieferanschrift__c= true, Shoplieferanschrift__c = true, Art_der_Anschrift__c = 'Kundenadresse' );
        insert an;

        Lieferschein__c LS1 = new Lieferschein__c(Kunde__c = kd.id, Lieferdatum__c = date.Today(), Liefertext__c='PG54');
        insert ls1;
        Lieferschein__c LS2 = new Lieferschein__c(Kunde__c = kd.id, Lieferdatum__c = date.Today(), Liefertext__c='PG54');
        insert ls2;
        Lieferschein__c LS3 = new Lieferschein__c(Kunde__c = kd.id, Lieferdatum__c = date.Today(), Liefertext__c='PG54');
        insert ls3;

        Lieferbest_tigung__c LB1 = new Lieferbest_tigung__c(Lieferschein__c = LS1.id);
        insert LB1;
        Lieferbest_tigung__c LB2 = new Lieferbest_tigung__c(Lieferschein__c = LS2.id, an_abena_versendet__c = true);
        insert LB2;
        Lieferbest_tigung__c LB3 = new Lieferbest_tigung__c(Lieferschein__c = LS3.id, an_abena_versendet__c = true, ABENA_EMPFANG__C = true);
        insert LB3;
        CompanyInfo__c cu = new CompanyInfo__c(name='Default', KDNR_bei_Lieferant__c='0999', Telefon__c='123', Fax__c='123' );
        insert cu;           

    }    
    
    static testMethod void myUnitTest() {
    

        
        LS_erzeugen lse = new LS_erzeugen();
        PageReference pRef1 = Page.LS_erzeugen;
        Test.setCurrentPage(pRef1); 

        lse.getlbList();

        lse.qrySelect = '1';
        lse.initPage();

        pRef1.getParameters().put('qrySelect', '2');
        lse.qrySelect = '2';
        lse.initPage();

        pRef1.getParameters().put('qrySelect', '3');
        lse.qrySelect = '3';
        lse.initPage();

        lse.SortToggle();

        pRef1.getParameters().put('sortToggleParam', 'Lieferschein__r.Liefertext__c DESC');
        lse.sortExpression = 'Lieferschein__r.Liefertext__c';
        

        boolean ok = lse.hasNext;
        ok = lse.hasPrevious;
        integer n = lse.pageNumber;
        list<SelectOption> querySelect = lse.querySelect;
        lse.next();
        lse.last();
        lse.first();
        lse.previous();
        lse.LS_erzeugen_zurueck();
    }
}