@isTest
private class sendenFaxAusKunde_test {
    static testMethod void myUnitTest(){
        sendenFaxAusKunde fk = new sendenFaxAusKunde();
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54', Name = 'Testkunde');
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.Art_des_Kontakts__c='kein';
        Account a = new Account(Name = 'Test Account');
        a.Industry='Krankenkassen';
        insert a;
        c.AccountId=a.Id;
        insert c;
        k.Betreuer__c = c.ID;
        //k.Pflegedienst__c = a.Id;
        insert k;   
        PageReference tpageRef = Page.sendenFaxAusKunde;
        Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('ID', k.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(k);
        AB_KK__c ab_kk = new AB_KK__c(Name='AB_KK_Einstellungen');
        ab_kk.Abrechnungsfirma__c='Testkunde';
        insert ab_kk;
        Blob abody = blob.valueOf('test');
        Attachment attach = new Attachment(Body = abody, ParentId = k.Id, Name = 'fax_test 54');
        insert attach;
        Antragstext__c at = new Antragstext__c(RichText__c='test rich text',Textkey__c= 'Antrag auf Kostenübernahme 54');
        insert at;
        at = new Antragstext__c(RichText__c='test rich text51',Textkey__c= 'Antrag auf Kostenübernahme 51');
        insert at;
        Faelligkeitsdatum__c fDatum = new Faelligkeitsdatum__c(Name = 'Nachfassen bei PK wg offener KU', Zeitraum__c = 14);
        insert fDatum;

        fk = new sendenFaxAusKunde(sc);
        fk.sendenFaxAusKunde_reload();
        fk.sendenFaxAusKunde_zurueck();
        fk.startMail();
        fk.startFax();
        fk.setKdFax('test');
        fk.fAtID = attach.Id;
        fk.startFax();
        fk.getArtikelGruppen();
        fk.getKundeKontakt();
        fk.getKdKontakt();
        fk.getKdBody();
        fk.getSeitenTitel();
        fk.createTask();
        fk.getKdID();
        fk.getMBtext();
        fk.getMtext();
        fk.getButtonPdfVisible();
        fk.getButtonFaxVisible();
        fk.getButtonMailVisible();
        fk.getKdBody2();
        fk.getApName();
        fk.getKdVersNr();
        fk.getKkName();
        fk.getKdName();
        fk.getKdText();
        fk.getKdMail();
        fk.getArtikelGruppe();
        fk.getKdSubject();
        
        fk.setKdSubject('test');
        fk.setKdText('test');
        fk.setKdKontakt('test');
        fk.setKdBody('test');
        fk.setFAtID('test');
        fk.setKdName('test');
        fk.setArtikelGruppe('test');
        fk.setKdMail('test');
        fk.getTargetMail();
        
    }
}