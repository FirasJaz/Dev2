@isTest
public class EmailToPartner_test {
   
    static testMethod void notificationEmial_Test() {
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType rt = rtList [0];
        
        Account a = new Account();
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        a.RecordTypeId = rt.Id;
        insert a;
                    
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22767';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'ASP';
        insert cr;
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'PB';
        insert cr2;       
        
        Partner_Ticket__c pt = new Partner_Ticket__c();
        pt.Partner__c = a.id;
        pt.Partner_Produkt__c = pp.Id;
        pt.opportunity__c = opp.Id;
        insert pt;
        
        ApexPages.StandardController sc = new ApexPages.standardController(pt);
        PageReference pRef = Page.NotificationEmailToPartner;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', pt.Id);
        
        NotificationEmailToPartner  n = new NotificationEmailToPartner (sc);        
        n.sendEmail();
    
    }
    
    
    static testMethod void errinerungsEmial_Test() {
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType rt = rtList [0];
        
        Account a = new Account();
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        a.RecordTypeId = rt.Id;
        insert a;
                    
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22767';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'ASP';
        insert cr;
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'PB';
        insert cr2;       
        
        Partner_Ticket__c pt = new Partner_Ticket__c();
        pt.Partner__c = a.id;
        pt.Partner_Produkt__c = pp.Id;
        pt.opportunity__c = opp.Id;
        insert pt;
        
        ApexPages.StandardController sc = new ApexPages.standardController(pt);
        PageReference pRef = Page.NotificationEmailToPartner;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', pt.Id);
        
        ErinnerungsmailAnPartner n = new ErinnerungsmailAnPartner (sc);        
        n.sendEmail();
    
    }
}