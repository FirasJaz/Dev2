@isTest
public class Nachtelefonie_einrichten_test {
    
    static testMethod void myUnitTest() {
    
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Alternative_Postleitzahl__c='12322';
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        if(rtList != null && rtList.size()>0){
            opp.RecordTypeId = rtList[0].Id;
        }
        
        insert opp;
        
        Contact c = new Contact();
        c.LastName='test ksg__Rueckmeldung_benoetigt';
        c.Email = 'ziaei@klosesrockepartner.de';
        insert c;
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.id;
        ocr.Role = 'PB = ASP';
        ocr.ContactId = c.id;
        insert ocr;
        
        ApexPages.StandardController sc = new ApexPages.standardController(opp);
        PageReference pRef = Page.Nachtelefonie_einrichten;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        Nachtelefonie_einrichten ne = new Nachtelefonie_einrichten(sc);
        
        ne.einrichten();
    }
    
    
    static testMethod void Badumbau_einrichten() {
    
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Alternative_Postleitzahl__c='12322';
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Opportunity' limit 1];
        if(rtList != null && rtList.size()>0){
            opp.RecordTypeId = rtList[0].Id;
        }
        
        insert opp;
        
        Contact c = new Contact();
        c.LastName='test ksg__Rueckmeldung_benoetigt';
        c.Email = 'ziaei@klosesrockepartner.de';
        insert c;
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.id;
        ocr.Role = 'PB = ASP';
        ocr.ContactId = c.id;
        insert ocr;
        
        ApexPages.StandardController sc = new ApexPages.standardController(opp);
        PageReference pRef = Page.Nachtelefonie_einrichten;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        Nachtelefonie_einrichten ne = new Nachtelefonie_einrichten(sc);
        
        ne.einrichten();
        
        try{
            opp.stageName = 'Kontaktanbahnungsphase';
        	update opp;
            
            ne.einrichten();
        }catch(Exception e){
            system.debug(e.getMessage());
        }
        
            
    }
    
    
}