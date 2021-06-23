@isTest
public class OpportunityToLeadTest {
    
    static testMethod void myUnitTest() {
        Campaign cmp = new Campaign();
        cmp.Name = 'Cross-Selling';
        insert cmp;
        
        Account a = new Account();
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        //partner p = new partner();
        //insert p;
            
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        //pp.RecordType = new RecordType();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        //opp.RecordType = new RecordType();
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
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB = ASP';
        insert cr;       
        
        //ApexPages.StandardController sc = new ApexPages.standardController(opp);
        PageReference pRef = Page.OpportunityToLeadPage;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        OpportunityToLead otl = new OpportunityToLead();
        otl.setSelectedRt('Treppenlift');
        otl.getSelectedRt();
        otl.getRtItems();
        otl.leadUebernehmen = true;
        otl.Speichern();
        
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'ASP';
        insert cr2; 
        otl.setSelectedRt('Curabox');
        otl.leadUebernehmen = true;
        otl.Speichern();
        
        otl.zuOpportunity();
        
    }
    
}