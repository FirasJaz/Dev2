@isTest
private class Lieferungen_ausloesen_test {
    static testMethod void myUnitTest() {      
        Account KK = new Account();
        KK.Name = 'AOK';
        KK.BillingCity = 'Hamburg';
        KK.BillingState = 'DE';
        KK.BillingStreet = 'Reeperbahn';
        KK.BillingPostalCode = '20301';   
        KK.Industry = 'Krankenkassen';     
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

        Lieferschein__c LS1 = new Lieferschein__c(Kunde__c = kd.id, Lieferdatum__c = date.Today().addDays(-1), Liefertext__c='PG54');
        insert ls1;
        
        ID batchprocessid = Database.executeBatch(new Lieferungen_ausloesen());
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP,  new Lieferungen_ausloesen_start());
        
        
        ID batchprocessid2 = Database.executeBatch(new Lieferungen_ausloesen_jetzt());
        String jobId2 = System.schedule('testScheduledApex', CRON_EXP,  new Lieferungen_ausloesen_jetzt_start());
        
        Lieferungen_ausloesen_jetzt lief_aus_jetzt = new Lieferungen_ausloesen_jetzt();
        lief_aus_jetzt.setLeereZeilen();
        
        Lieferungen_ausloesen lief_aus = new Lieferungen_ausloesen();
        lief_aus.setLeereZeilen();
        
        LS_XML_nachbearbeiten_batch nbXML = new LS_XML_nachbearbeiten_batch();
        nbXML.setLeereZeilen();
        
        ID bid = Database.executeBatch(new ls_xml_create());
    }
}