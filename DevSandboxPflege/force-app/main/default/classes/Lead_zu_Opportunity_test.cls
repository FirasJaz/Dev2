@isTest
private class Lead_zu_Opportunity_test {

    @TestSetup static void DueDate(){
        // custom settings
        Due_Date__c dueDate = new Due_Date__c(Name = 'Formularversand', Follow_Up_Task_Due_Date__c = 5);
        insert dueDate;
    }

    static testMethod void myUnitTest(){                                   
        List<RecordType> lead_rtList = [select id, Name, sObjectType from RecordType where Name = 'Treppenlift' and sObjectType = 'Lead'];
        List<RecordType> lead_rtList2 = [select id, Name, sObjectType from RecordType where Name = 'Betreuungsleistungen' and sObjectType = 'Lead'];
        List<RecordType> lead_rtList_Badumabu = [select id, Name, sObjectType from RecordType where Name = 'Badumabu' and sObjectType = 'Lead'];
        List<RecordType> lead_rtList_curabox = [select id, Name, sObjectType from RecordType where Name = 'Curabox' and sObjectType = 'Lead'];
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead testlead = new Lead( lastname = 'Lead_lastname_test',
                                firstname = 'Lead_firstname_test',
                                salutation = 'Herr',
                                Company = 'Treppenlift',
                                RecordType = lead_rtList_curabox[0],
                                TL_Anzahl_der_Etagen__c = '2 Etagen',
                                TL_Postleitzahl_f_r_Suche__c = '11223',
                                Email = 'test@test.de',
                                Phone = '0123456789',
                                OM_Wizzard_Name2__c = cmp.Id,
                                CB_Box__c = 'box1', 
                                CB_Handschuh_Groesse__c = 'Peha-soft Vinyl Einmalhandschuhe (Größe M)',
                                Angehoeriger_Anrede__c = 'Herr', 
                                Angehoeriger_Vorname__c = 'Alex', 
                                Angehoeriger_Nachname__c = 'Savic',
                                Angehoeriger_Email__c = 'alexsavic@yahoo.de', 
                                Angeh_riger_Mobile__c = '017667071610',
                                Angehoeriger_Ort__c = 'Hamburg', 
                                Angehoeriger_PLZ__c = '20097', 
                                Angehoeriger_Strasse__c = 'Nordkanalstrasse', 
                                Angehoeriger_Telefon__c = '017667071610');
        
        insert testLead;
        
        
        list<RecordType> fam_rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien']; 
        
        Account testFamilie = new Account(RecordType = fam_rtList[0],
                                          Name = 'testFamilie');
                                          
        insert testFamilie;
        
        list<RecordType> cont_rtList = [SELECT Id FROM RecordType WHERE Name = 'Familienangehörige']; 
        
        Contact testContact = new Contact( RecordType = cont_rtList[0],
                                           lastname = 'Lead_lastname',
                                           firstname = 'Lead_firstname',
                                           AccountId = testFamilie.Id,
                                           Email = 'test@test.de',
                                           Phone = '0123456789');
        
        insert testContact;    
        
        Contact testContact2 = new Contact( RecordType = cont_rtList[0],
                                           lastname = 'Lead_lastname',
                                           firstname = 'Lead_firstname',
                                           AccountId = testFamilie.Id,
                                           Email = 'test@test.de',
                                           Phone = '0123456789');
        
        insert testContact2; 
        
        List<RecordType> opp_rtList = [select id, Name, sObjectType from RecordType where Name = 'Treppenlift' and sObjectType = 'Opportunity'];
        
        Opportunity testOpp = new Opportunity(RecordType = opp_rtList[0],
                                              StageName = 'Offen',
                                              Kategorie__c = '1',
                                              closeDate = date.today(),
                                              Name = 'testOpp',
                                              AccountId = testFamilie.Id); 
        
        insert testOpp;
        
        OpportunityContactRole testOcr = new OpportunityContactRole( ContactId = testContact.Id,
                                                                   OpportunityId = testOpp.Id,
                                                                   IsPrimary = true,
                                                                   Role = 'PB = ASP');      
        
        insert testOcr;                                                      
                 
        Kunde__c testKunde = new Kunde__c( Name__c = 'Lead_lastname',
                                           Vorname__c = 'Lead_firstname',
                                           Produktgruppe__c = 'PG54');
        
        insert testKunde;                  
        
        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        System.currentPageReference().getParameters().put('ID', testLead.Id);          
        ApexPages.StandardController ctr1 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity lzo1 = new Lead_zu_Opportunity(ctr1); 
        lzo1.zuLeads();
        lzo1.waehleKontaktAus();
        lzo1.weiter();
        System.currentPageReference().getParameters().put('kontaktId', 'neuerKontakt');
        lzo1.waehleKontaktAus();
        lzo1.weiter();
        lzo1.zurueck();
        lzo1.weiter();
        lzo1.weiter();
        System.currentPageReference().getParameters().put('kundeId', testKunde.Id);
        lzo1.weiter();
        lzo1.zurueck();
        lzo1.weiter();        
        lzo1.waehleFamilieAus();
        System.currentPageReference().getParameters().put('famId', 'neueFamilie');
        lzo1.waehleFamilieAus();
        lzo1.waehleOpportunityAus();
        lzo1.weiter();
        System.currentPageReference().getParameters().put('oppId', 'neueOpportunity');
        lzo1.waehleOpportunityAus();
        lzo1.waehleGrundAus();
        lzo1.getAgList();
        lzo1.getMessage_layout();
        lzo1.getTable1_layout();
        lzo1.getTable3_layout();
        lzo1.getTable4_layout();
        
        delete testKunde;
        
        testLead.TL_Anzahl_der_Etagen__c = '3 Etagen o. mehr';
        testLead.RecordTypeId = lead_rtList2[0].Id;
        update testLead;
        System.currentPageReference().getParameters().put('ID', testLead.Id);          
        ApexPages.StandardController ctr2 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity lzo2 = new Lead_zu_Opportunity(ctr2); 
        lzo2.zuLeads();
        System.currentPageReference().getParameters().put('kontaktId', testContact.Id);
        lzo2.waehleKontaktAus();
        lzo2.weiter();
        lzo2.zurueck();
        lzo2.weiter();
        System.currentPageReference().getParameters().put('famId', testFamilie.Id);
        lzo2.waehleFamilieAus();
        lzo2.weiter();
        lzo2.zurueck();
        lzo2.weiter();
        System.currentPageReference().getParameters().put('oppId', testOpp.Id);
        lzo2.waehleOpportunityAus();   
        lzo2.weiter();
        
        testLead.TL_Anzahl_der_Etagen__c = '1 Etage';
        testLead.RecordTypeId = lead_rtList2[0].Id;
        testLead.firstname = 'firstname';
        testLead.lastname = 'lastname';
        update testLead;
        System.currentPageReference().getParameters().put('ID', testLead.Id);         
        
        Test.startTest();
        ApexPages.StandardController ctr3 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity lzo3 = new Lead_zu_Opportunity(ctr3); 
        lzo3.zuLeads();
        System.currentPageReference().getParameters().put('kontaktId', testContact.Id);
        lzo3.waehleKontaktAus();
        lzo3.weiter();
        System.currentPageReference().getParameters().put('famId', 'famZuOrdnen');
        System.currentPageReference().getParameters().put('fmName', testFamilie.Name);
        lzo3.familieZuOrdnen();
        lzo3.waehleFamilieAus();
        lzo3.weiter();
        System.currentPageReference().getParameters().put('oppId', 'Ausschuss');
        System.currentPageReference().getParameters().put('grd', 'Doppelte Anfrage');
        lzo3.waehleGrundAus();
        lzo3.waehleOpportunityAus();
        lzo3.denyDuplicate();
        try{
        lzo3.acceptDuplicate();
        }catch(exception e){}	
        lzo3.saveWithSatndardLeadConvert();
        Test.stopTest();
        lzo3.dummyMethod();
    }

    @isTest static void convertCurabox(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(3);
        List<Contact> conList = [SELECT Id, Salutation, Name, FirstName, LastName, Email, AccountId, Betreuer__r.Salutation, Betreuer__r.Firstname, Betreuer__r.LastName FROM Contact];
        //
        Campaign cmp = new Campaign();
        cmp.name = 'Curabox';
        insert cmp;
        Lead testlead = new Lead( lastname = 'Lead_lastname_test',
                                firstname = 'Lead_firstname_test',
                                salutation = 'Herr',
                                Company = 'Curabox',
                                Geburtsdatum__c = '12.12.1945',
                                TL_Anzahl_der_Etagen__c = '2 Etagen',
                                TL_Postleitzahl_f_r_Suche__c = '11223',
                                Email = 'test@test.de',
                                Phone = '0123456789',
                                OM_Wizzard_Name2__c = cmp.Id,
                                CB_Box__c = 'box1', 
                                CB_Handschuh_Groesse__c = 'Peha-soft Vinyl Einmalhandschuhe (Größe M)',
                                Angehoeriger_Anrede__c = 'Herr', 
                                Angehoeriger_Vorname__c = 'Alex', 
                                Angehoeriger_Nachname__c = 'Savic',
                                Angehoeriger_Email__c = 'alexsavic@yahoo.de', 
                                Angeh_riger_Mobile__c = '017667071610',
                                Angehoeriger_Ort__c = 'Hamburg', 
                                Angehoeriger_PLZ__c = '20097', 
                                Angehoeriger_Strasse__c = 'Nordkanalstrasse', 
                                Angehoeriger_Telefon__c = '017667071610',
                                IK_Nummer_des_traegers__c = '1234567890',
                                Versicherungsnummer__c = '098766RTK54321'
                                );
        insert testLead;

        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        System.currentPageReference().getParameters().put('ID', testLead.Id); 
        ApexPages.StandardController ctr1 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity leadZuOpp = new Lead_zu_Opportunity(ctr1);
        String cb1 = leadZuOpp.convertCurabox('box1');
        String cb2 = leadZuOpp.convertCurabox('box2');
        String cb3 = leadZuOpp.convertCurabox('box3');
        String cb4 = leadZuOpp.convertCurabox('box4');
        String cb5 = leadZuOpp.convertCurabox('box5');
        String flexbox = leadZuOpp.convertCurabox('Flexbox');
        // Test convertCurabox()
        System.assertEquals('CB1', cb1);
        System.assertEquals('CB2', cb2);
        System.assertEquals('CB3', cb3);
        System.assertEquals('CB4', cb4);
        System.assertEquals('CB5', cb5);
        System.assertEquals('CB6 - Flexibel', flexbox);
        // Test new contact
        leadZuOpp.sKont = 'neuerKontakt';
        leadZuOpp.selectedContact = 'neuerKontakt';
        leadZuOpp.sFam = 'neueFamilie';
        leadZuOpp.leseKontakte();
        leadZuOpp.kontaktAnlegen();
        leadZuOpp.lesePBKontakte();
        leadZuOpp.createPflegeBeduertigeContact();
        leadZuOpp.leseFamilie();
        leadZuOpp.familieAnlegen();
        // Test existing contact
        leadZuOpp.sKont = conList[0].Id;
        leadZuOpp.selectedContact = conList[1].Id;
        leadZuOpp.sFam = conList[0].AccountId;
        leadZuOpp.kontaktAnlegen();
        leadZuOpp.createPflegeBeduertigeContact();
        leadZuOpp.familieAnlegen();
        // Test saveWithSatndardLeadConvert()
        leadZuOpp.saveWithSatndardLeadConvert();
    }

    @isTest static void kontaktAnlegen(){
        User benutzer = [SELECT Id, Name FROM User WHERE Name = 'IT Support' LIMIT 1];
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(3);
        List<Contact> conList = [SELECT Id, Salutation, Name, FirstName, LastName, Email, AccountId, Betreuer__r.Salutation, Betreuer__r.Firstname, Betreuer__r.LastName FROM Contact];
        conList[0].OM_UserID__c = benutzer.Id;
        update conList[0];
        //
        Campaign cmp = new Campaign();
        cmp.name = 'Curabox';
        insert cmp;
        Lead testlead = new Lead( lastname = 'Lead_lastname_test',
                                firstname = 'Lead_firstname_test',
                                salutation = 'Herr',
                                Company = 'Curabox',
                                Geburtsdatum__c = '12.12.1945',
                                TL_Anzahl_der_Etagen__c = '2 Etagen',
                                TL_Postleitzahl_f_r_Suche__c = '11223',
                                Email = 'test@test.de',
                                Phone = '0123456789',
                                OM_Wizzard_Name2__c = cmp.Id,
                                OM_UserID__c = benutzer.Id,
                                CB_Box__c = 'box1', 
                                CB_Handschuh_Groesse__c = 'Peha-soft Vinyl Einmalhandschuhe (Größe M)',
                                IK_Nummer_des_traegers__c = '1234567890',
                                Versicherungsnummer__c = '098766RTK54321'
                                );
        insert testLead;

        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        System.currentPageReference().getParameters().put('ID', testLead.Id); 
        ApexPages.StandardController ctr1 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity leadZuOpp = new Lead_zu_Opportunity(ctr1);
        // Test new contact
        leadZuOpp.sKont = 'neuerKontakt';
        leadZuOpp.selectedContact = 'neuerKontakt';
        leadZuOpp.kontaktAnlegen();
        leadZuOpp.createPflegeBeduertigeContact();
        // Test existing contact
        leadZuOpp.sKont = conList[0].Id;
        leadZuOpp.kontaktAnlegen();
        leadZuOpp.duplicateUserIdExists();
        String conId = conList[1].Id;
        String famId = leadZuOpp.getFamiliebyContact(conId);
        System.assertEquals(conList[1].AccountId, famId);
        testlead.next_Step__c = 'blanko per Post';
        leadZuOpp.nextStep('blanko per Post');
        testlead.next_Step__c = 'blanko per Post';
        leadZuOpp.nextStep('blanko per Post');
        testlead.next_Step__c = 'ausgefüllt per Post an Angehörigen';
        leadZuOpp.nextStep('ausgefüllt per Post an Angehörigen');
        testlead.next_Step__c = 'ausgefüllt per Post an Versicherten';
        leadZuOpp.nextStep('ausgefüllt per Post an Versicherten');
        // Test saveAttachment();
        ContentVersion attach = new ContentVersion();
        Blob atbody  = Blob.valueOf('Test document');
        attach.VersionData = atbody;
        attach.Title = 'CB_Formular_Alex';
        attach.PathOnClient ='CB_Formular_Alex.pdf';
        attach.FirstPublishLocationId = testlead.Id;
        attach.ContentLocation = 'S';
        insert attach;
        leadZuOpp.saveAttachmentToPB();
    }

    @isTest static void weiter(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(3);
        List<Contact> conList = [SELECT Id, Salutation, Name, FirstName, LastName, Email, AccountId, Betreuer__r.Salutation, Betreuer__r.Firstname, Betreuer__r.LastName FROM Contact];
        //
        create_test_product.createOrders();
        List<RecordType> lead_rtList_curabox = [select id, Name, sObjectType from RecordType where Name = 'Curabox' and sObjectType = 'Lead'];
        Campaign cmp = new Campaign();
        cmp.name = 'Curabox';
        insert cmp;
        
        Lead testlead = new Lead( lastname = 'Lead_lastname_test',
                                firstname = 'Lead_firstname_test',
                                salutation = 'Herr',
                                 Company = 'Curabox',
                                RecordType = lead_rtList_curabox[0],
                                TL_Anzahl_der_Etagen__c = '2 Etagen',
                                TL_Postleitzahl_f_r_Suche__c = '11223',
                                Email = 'test@test.de',
                                Phone = '0123456789',
                                OM_Wizzard_Name2__c = cmp.Id,
                                CB_Box__c = 'box1',
                                next_step__c = 'Blanko per Post', 
                                CB_Handschuh_Groesse__c = 'Peha-soft Vinyl Einmalhandschuhe (Größe M)',
                                Angehoeriger_Anrede__c = 'Herr', 
                                Angehoeriger_Vorname__c = 'Alex', 
                                Angehoeriger_Nachname__c = 'Savic',
                                Angehoeriger_Email__c = 'alexsavic@yahoo.de', 
                                Angeh_riger_Mobile__c = '017667071610',
                                Angehoeriger_Ort__c = 'Hamburg', 
                                Angehoeriger_PLZ__c = '20097', 
                                Angehoeriger_Strasse__c = 'Nordkanalstrasse', 
                                Angehoeriger_Telefon__c = '017667071610');
        
        insert testLead;
        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        System.currentPageReference().getParameters().put('ID', testLead.Id); 
        ApexPages.StandardController ctr1 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity leadZuOpp = new Lead_zu_Opportunity(ctr1);
         /*+ Schritt 1 +*/
        leadZuOpp.title = 'Schritt 1';
        leadZuOpp.sKont = null;
        leadZuOpp.weiter();
        leadZuOpp.title = 'Schritt 1';
        leadZuOpp.sKont = 'neuerKontakt';
        leadZuOpp.weiter();
        /*+ Schritt 2 +*/
        // when the contacts exists
        leadZuOpp.title = 'Schritt 2';
        leadZuOpp.selectedContact = null;
        leadZuOpp.weiter();
        leadZuOpp.waehleZweiterKontaktAus();
        // same family
        leadZuOpp.sKont = conList[0].Id;
        leadZuOpp.selectedContact = conList[0].Id;
        leadZuOpp.weiter();
        // different family
        leadZuOpp.title = 'Schritt 2';
        leadZuOpp.sKont = conList[0].Id;
        leadZuOpp.selectedContact = conList[1].Id;
        leadZuOpp.weiter();
        // only one contact exists
        leadZuOpp.title = 'Schritt 2';
        leadZuOpp.sKont = 'neuerKontakt';
        leadZuOpp.selectedContact = conList[1].Id;
        leadZuOpp.weiter();
        leadZuOpp.title = 'Schritt 2';
        leadZuOpp.sKont =  conList[1].Id;
        leadZuOpp.selectedContact = 'neuerKontakt';
        leadZuOpp.weiter();
        // when the contacts are new
        leadZuOpp.title = 'Schritt 2';
        leadZuOpp.sKont = 'neuerKontakt';
        leadZuOpp.selectedContact = 'neuerKontakt';
        //leadZuOpp.weiter();
        /*+ Schritt 3 +*/
        leadZuOpp.title = 'Schritt 3';
        leadZuOpp.sFam = null;
        //leadZuOpp.weiter();
        // sFam != null
        leadZuOpp.sFam = conList[1].AccountId;
        //leadZuOpp.weiter();
        /*+ Schritt 4 +*/
        leadZuOpp.title = 'Schritt 4';
        // leadZuOpp.weiter();
    }

    @isTest static void weiterLeadWithoutASP(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(3);
        List<Contact> conList = [SELECT Id, Salutation, Name, FirstName, LastName, Email, AccountId, Betreuer__r.Salutation, Betreuer__r.Firstname, Betreuer__r.LastName FROM Contact];
        //
        List<RecordType> lead_rtList_curabox = [select id, Name, sObjectType from RecordType where Name = 'Curabox' and sObjectType = 'Lead'];
        Campaign cmp = new Campaign();
        cmp.name = 'Curabox';
        insert cmp;
        
        Lead testlead = new Lead( lastname = 'Lead_lastname_test',
                                firstname = 'Lead_firstname_test',
                                salutation = 'Herr',
                                 Company = 'Curabox',
                                RecordType = lead_rtList_curabox[0],
                                TL_Anzahl_der_Etagen__c = '2 Etagen',
                                TL_Postleitzahl_f_r_Suche__c = '11223',
                                Email = 'test@test.de',
                                Phone = '0123456789',
                                OM_Wizzard_Name2__c = cmp.Id,
                                CB_Box__c = 'box1',
                                CB_Handschuh_Groesse__c = 'Peha-soft Vinyl Einmalhandschuhe (Größe M)'
                                );
        
        insert testLead;
        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        System.currentPageReference().getParameters().put('ID', testLead.Id); 
        ApexPages.StandardController ctr1 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity leadZuOpp = new Lead_zu_Opportunity(ctr1);
        /*+ Schritt 1 +*/
        leadZuOpp.title = 'Schritt 1';
        leadZuOpp.sKont = conList[0].Id;
        leadZuOpp.weiter();
        leadZuOpp.title = 'Schritt 1';
        leadZuOpp.sKont = 'neuerKontakt';
        leadZuOpp.weiter();
    }

    @isTest static void zurueck(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(3);
        List<Contact> conList = [SELECT Id, Salutation, Name, FirstName, LastName, Email, AccountId, Betreuer__r.Salutation, Betreuer__r.Firstname, Betreuer__r.LastName FROM Contact];
        //
        List<RecordType> lead_rtList_curabox = [select id, Name, sObjectType from RecordType where Name = 'Curabox' and sObjectType = 'Lead'];
        Campaign cmp = new Campaign();
        cmp.name = 'Curabox';
        insert cmp;
        
        Lead testlead = new Lead( lastname = 'Lead_lastname_test',
                                firstname = 'Lead_firstname_test',
                                salutation = 'Herr',
                                 Company = 'Curabox',
                                RecordType = lead_rtList_curabox[0],
                                TL_Anzahl_der_Etagen__c = '2 Etagen',
                                TL_Postleitzahl_f_r_Suche__c = '11223',
                                Email = 'test@test.de',
                                Phone = '0123456789',
                                OM_Wizzard_Name2__c = cmp.Id,
                                CB_Box__c = 'box1', 
                                CB_Handschuh_Groesse__c = 'Peha-soft Vinyl Einmalhandschuhe (Größe M)',
                                Angehoeriger_Anrede__c = 'Herr', 
                                Angehoeriger_Vorname__c = 'Alex', 
                                Angehoeriger_Nachname__c = 'Savic',
                                Angehoeriger_Email__c = 'alexsavic@yahoo.de', 
                                Angeh_riger_Mobile__c = '017667071610',
                                Angehoeriger_Ort__c = 'Hamburg', 
                                Angehoeriger_PLZ__c = '20097', 
                                Angehoeriger_Strasse__c = 'Nordkanalstrasse', 
                                Angehoeriger_Telefon__c = '017667071610');
        
        insert testLead;
        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        System.currentPageReference().getParameters().put('ID', testLead.Id); 
        ApexPages.StandardController ctr1 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity leadZuOpp = new Lead_zu_Opportunity(ctr1);
        leadZuOpp.leseKontakte();
        leadZuOpp.lesePBKontakte();
        leadZuOpp.leseFamilie();
         /*+ Schritt 4 +*/
        leadZuOpp.title = 'Schritt 4';
        leadZuOpp.sKont = conList[0].Id;
        leadZuOpp.selectedContact = conList[1].Id;
        leadZuOpp.zurueck();
        // the contacts are new
        leadZuOpp.title = 'Schritt 4';
        leadZuOpp.sKont = 'neuerKontakt';
        leadZuOpp.selectedContact = 'neuerKontakt';
        leadZuOpp.zurueck();
        /*+ Schritt 3 +*/
        leadZuOpp.title = 'Schritt 3';
        leadZuOpp.zurueck();
        /*+ Schritt 2 +*/
        leadZuOpp.title = 'Schritt 2';
        leadZuOpp.zurueck();
    }

    @isTest static void zurueckLeadWithoutASP(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(3);
        List<Contact> conList = [SELECT Id, Salutation, Name, FirstName, LastName, Email, AccountId, Betreuer__r.Salutation, Betreuer__r.Firstname, Betreuer__r.LastName FROM Contact];
        //
        List<RecordType> lead_rtList_curabox = [select id, Name, sObjectType from RecordType where Name = 'Curabox' and sObjectType = 'Lead'];
        Campaign cmp = new Campaign();
        cmp.name = 'Curabox';
        insert cmp;
        
        Lead testlead = new Lead( lastname = 'Lead_lastname_test',
                                firstname = 'Lead_firstname_test',
                                salutation = 'Herr',
                                Company = 'Curabox',
                                RecordType = lead_rtList_curabox[0],
                                TL_Anzahl_der_Etagen__c = '2 Etagen',
                                TL_Postleitzahl_f_r_Suche__c = '11223',
                                Email = 'test@test.de',
                                Phone = '0123456789',
                                OM_Wizzard_Name2__c = cmp.Id,
                                CB_Box__c = 'box1', 
                                CB_Handschuh_Groesse__c = 'Peha-soft Vinyl Einmalhandschuhe (Größe M)',
                                next_step__c = 'Blanko per Post'
                                );
        
        insert testLead;
        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        System.currentPageReference().getParameters().put('ID', testLead.Id); 
        ApexPages.StandardController ctr1 = new ApexPages.StandardController(testLead);
        Lead_zu_Opportunity leadZuOpp = new Lead_zu_Opportunity(ctr1);
        leadZuOpp.leseKontakte();
        leadZuOpp.lesePBKontakte();
         /*+ Schritt 4 +*/
        leadZuOpp.title = 'Schritt 4';
        leadZuOpp.sKont = conList[0].Id;
        leadZuOpp.zurueck();
        leadZuOpp.title = 'Schritt 4';
        leadZuOpp.sKont = 'neuerKontakt';
        leadZuOpp.zurueck();
        /*+ Schritt 4 +*/
        leadZuOpp.title = 'Schritt 3';
        leadZuOpp.zurueck();
    }
    
}