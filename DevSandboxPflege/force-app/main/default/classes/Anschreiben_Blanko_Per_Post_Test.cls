/****************************************************************************************************************************
// Created 02.07.2020 von  BT
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Description:       
//                      Test class for the class Anschreiben_Blanko_Per_Post
//****************************************************************************************************************************
// Changes: 
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
private class Anschreiben_Blanko_Per_Post_Test {
    
    @testSetup
    static void setup() {
        Antragstext__c at = new Antragstext__c(Textkey__c='AGB',
                                                Richtext__c='Test Body.');
        insert at;
        
        Account a = new Account(Name='Test Account');
        insert a;        
        
        Campaign cmp = new Campaign(Name='Test Campaign');
        insert cmp;
        
        Lead l = new Lead(FirstName='Max',
                          LastName='Mustermann',
                          Salutation='Herr',
                          Street='Musterstraße 12',
                          PostalCode='12345',
                          City='Musterstadt',
                          Company='Test Account',
                          OM_Wizzard_Name2__c=cmp.Id);
        insert l;
        
        Contact c = new Contact(FirstName='Alexander',
                                LastName='Mustermann',
                                Salutation='Herr',
                                MailingStreet='Musterstraße 12',
                                MailingPostalCode='23456',
                                MailingCity='Musterstadt');
        insert c;        
    }
    
    @isTest
    static void testFillAnschreibenWithContactData(){
        Contact c = [SELECT Id
                     FROM Contact LIMIT 1];
        PageReference pageRef = Page.Anschreiben_Formular_Neu;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', c.Id);
        ApexPages.currentPage().getParameters().put('rcpt', c.Id);
        Anschreiben_Blanko_Per_Post anschBlanko = new Anschreiben_Blanko_Per_Post();
        System.assert(anschBlanko.empfaenger == 'AnsprechpartnerIn');
    }
    
    @isTest
    static void testFillAnschreibenWithLeadData(){
        Contact c = [SELECT Id
                     FROM Contact LIMIT 1];
        Lead l = [SELECT Id
                  FROM Lead LIMIT 1];
        PageReference pageRef = Page.Anschreiben_Formular_Neu;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', c.Id);
        ApexPages.currentPage().getParameters().put('rcpt', l.Id);
        Anschreiben_Blanko_Per_Post anschBlanko = new Anschreiben_Blanko_Per_Post();
        System.assert(anschBlanko.empfaenger == 'Pflegebedürftiger');
    }    
    
    @isTest
    static void testFillAnschreibenWithAccountData(){
        Contact c = [SELECT Id
                     FROM Contact LIMIT 1];
        Account a = [SELECT Id
                     FROM Account LIMIT 1];
        PageReference pageRef = Page.Anschreiben_Formular_Neu;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', c.Id);
        ApexPages.currentPage().getParameters().put('rcpt', a.Id);
        Anschreiben_Blanko_Per_Post anschBlanko = new Anschreiben_Blanko_Per_Post();
        System.assert(anschBlanko.empfaenger == 'Pflegedienst');
    }     
    
    @isTest
    static void testGetMethods(){
        Contact c = [SELECT Id
                     FROM Contact LIMIT 1];
        PageReference pageRef = Page.Anschreiben_Formular_Neu;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', c.Id);
        ApexPages.currentPage().getParameters().put('rcpt', c.Id);        
        Anschreiben_Blanko_Per_Post anschBlanko = new Anschreiben_Blanko_Per_Post();
        anschBlanko.getAnredeformel();
        anschBlanko.getAnschrift();
        anschBlanko.getFirmenInfo();
        anschBlanko.getKdAddr();
        anschBlanko.getKdAddrD();
        anschBlanko.getKK();
        anschBlanko.getKunde();
        anschBlanko.getLead();
        anschBlanko.getRetPage();        
    }    
}