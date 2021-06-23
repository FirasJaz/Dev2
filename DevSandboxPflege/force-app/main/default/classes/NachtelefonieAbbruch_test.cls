@isTest
public class NachtelefonieAbbruch_test {
    
    static testMethod void myUnitTest() {
         Profile p = [select id from profile where name='ZWB - Standardbenutzer']; 
         User u = new User(alias = 'ksg_z', email='ziaei@testorg.com', 
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p.Id, 
            timezonesidkey='America/Los_Angeles', username='ziaei@testorg.com');


         System.runAs(u) {
           // The following code runs as user 'u' 
           System.debug('Current User: ' + UserInfo.getUserName());
           System.debug('Current Profile: ' + UserInfo.getProfileId()); 


        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        opp.RecordTypeId = rtList[0].Id;
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB = ASP';
        insert cr;
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        nt.Anzahl_der_Versuche__c = 3;
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Nachtelefonie__c' limit 1];
        nt.RecordTypeId = rtList[0].Id;
        insert nt;
        
        PageReference pRef = Page.Nachtelefonie_Abbruch;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);  
        NachtelefonieAbbruch na = new NachtelefonieAbbruch();
        
        na.cat2Checkbox = true;
        na.checkAnzahlDerVersuche();
        
        na.getItems();
        na.abbruchGrund = '--None--';
        na.cat2Checkbox = false;
        na.checkAnzahlDerVersuche();
            
        na.cat2Checkbox = true;
        na.Speichern();
        na.cat2Checkbox = false;
        na.abbruchGrund = 'ASP nicht erreichbar';
        na.Speichern();
        na.kat2Selected();
        na.grundSelected();
        na.updateOpportunityStatus('test');
        }
        
    }
    
    static testMethod void myUnitTest_Betreuungsleistungen() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Betreuungsleistungen' and sobjecttype  = 'Opportunity' limit 1];
        opp.RecordTypeId = rtList[0].Id;
        insert opp;
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        nt.Anzahl_der_Versuche__c = 3;
        rtList =[select id, name,sobjecttype from recordType where name ='Betreuungsleistungen' and sobjecttype  = 'Nachtelefonie__c' limit 1];
        nt.RecordTypeId = rtList[0].Id;
        insert nt;
        
        PageReference pRef = Page.Nachtelefonie_Abbruch;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);  
        NachtelefonieAbbruch na = new NachtelefonieAbbruch();
        
        na.cat2Checkbox = true;
        na.checkAnzahlDerVersuche();
        
        na.getItems();
        na.abbruchGrund = '--None--';
        na.cat2Checkbox = false;
        na.checkAnzahlDerVersuche();
            
        na.cat2Checkbox = true;
        na.Speichern();
        na.cat2Checkbox = false;
        na.abbruchGrund = 'ASP nicht erreichbar';
        na.Speichern();
        na.kat2Selected();
        na.grundSelected();
        na.updateOpportunityStatus('test');
        
    }
    
    static testMethod void myUnitTest_Notrufsysteme() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Notrufsysteme' and sobjecttype  = 'Opportunity' limit 1];
        opp.RecordTypeId = rtList[0].Id;
        insert opp;
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        nt.Anzahl_der_Versuche__c = 3;
        rtList =[select id, name,sobjecttype from recordType where name ='Notrufsysteme' and sobjecttype  = 'Nachtelefonie__c' limit 1];
        nt.RecordTypeId = rtList[0].Id;
        insert nt;
        
        PageReference pRef = Page.Nachtelefonie_Abbruch;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);  
        NachtelefonieAbbruch na = new NachtelefonieAbbruch();
        
        na.cat2Checkbox = true;
        na.checkAnzahlDerVersuche();
        
        na.getItems();
        na.abbruchGrund = '--None--';
        na.cat2Checkbox = false;
        na.checkAnzahlDerVersuche();
            
        na.cat2Checkbox = true;
        na.Speichern();
        na.cat2Checkbox = false;
        na.abbruchGrund = 'ASP nicht erreichbar';
        na.Speichern();
        na.kat2Selected();
        na.grundSelected();
        na.updateOpportunityStatus('test');
        
    }
    
    static testMethod void myUnitTest_Pflegeimmobilien() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Pflegeimmobilien' and sobjecttype  = 'Opportunity' limit 1];
        opp.RecordTypeId = rtList[0].Id;
        insert opp;
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        nt.Anzahl_der_Versuche__c = 3;
        rtList =[select id, name,sobjecttype from recordType where name ='Pflegeimmobilien' and sobjecttype  = 'Nachtelefonie__c' limit 1];
        nt.RecordTypeId = rtList[0].Id;
        insert nt;
        
        PageReference pRef = Page.Nachtelefonie_Abbruch;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);  
        NachtelefonieAbbruch na = new NachtelefonieAbbruch();
        
        na.cat2Checkbox = true;
        na.checkAnzahlDerVersuche();
        
        na.getItems();
        na.abbruchGrund = '--None--';
        na.cat2Checkbox = false;
        na.checkAnzahlDerVersuche();
            
        na.cat2Checkbox = true;
        na.Speichern();
        na.cat2Checkbox = false;
        na.abbruchGrund = 'ASP nicht erreichbar';
        na.Speichern();
        na.kat2Selected();
        na.grundSelected();
        na.updateOpportunityStatus('test');
        
    }
    
    static testMethod void myUnitTest_Widerspruch() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Widerspruch' and sobjecttype  = 'Opportunity' limit 1];
        opp.RecordTypeId = rtList[0].Id;
        insert opp;
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        nt.Anzahl_der_Versuche__c = 3;
        rtList =[select id, name,sobjecttype from recordType where name ='Widerspruch' and sobjecttype  = 'Nachtelefonie__c' limit 1];
        nt.RecordTypeId = rtList[0].Id;
        insert nt;
        
        PageReference pRef = Page.Nachtelefonie_Abbruch;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);  
        NachtelefonieAbbruch na = new NachtelefonieAbbruch();
        
        na.cat2Checkbox = true;
        na.checkAnzahlDerVersuche();
        
        na.getItems();
        na.abbruchGrund = '--None--';
        na.cat2Checkbox = false;
        na.checkAnzahlDerVersuche();
            
        na.cat2Checkbox = true;
        na.Speichern();
        na.cat2Checkbox = false;
        na.abbruchGrund = 'ASP nicht erreichbar';
        na.Speichern();
        na.kat2Selected();
        na.grundSelected();
        na.updateOpportunityStatus('test');
        
    }

}