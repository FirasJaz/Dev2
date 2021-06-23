@isTest
public class ksgZWBContactUpdateController_test {
    static testMethod void testOpportunityOrderId(){
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Familien' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'testfamily_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        RecordType rt = rtList [0];
        
    	opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.AccountId = a.Id;
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        opp.OM_Tracking_Order_ID__c = '8b7c8e76-8de6-d3ff-8ffb-197e6980fc19';
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.AccountId = a.Id;
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.AccountId = a.Id;
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
        
        ksgZWBContactUpdateController.updateContact('8b7c8e76-8de6-d3ff-8ffb-197e6980fc19', 
                                                       'test@test.de',
                                                       'hgsdjasd',
                                                       'adasdasdasd',
                                                       '234234',
                                                       'Herr');
    }
   
	static testMethod void  testPostRestService() {
        
        Campaign cmp = new Campaign(name ='testWizard');
        insert cmp;
        
        Lead le = new Lead(Company='Notrufsysteme', Status='Open');
        le.OM_Tracking_Order_ID__c = '8b7c8e76-8de6-d3ff-8ffb-197e6980fc19';
        le.FirstName = 'sadfjhg';
        le.LastName = 'sdffsdfsd';
        le.OM_Wizzard_Name2__c = cmp.Id;
        le.Salutation = 'Herr';
        insert le;
        
        string jsonstring = '{                                                                   '+
                            '  \"Order_ID\": \"8b7c8e76-8de6-d3ff-8ffb-197e6980fc19\",           '+
                            '    \"contact_mail_from\": \"test@pflege.de\",                      '+
                            '    \"contact_first_name\": \"Tobias\",                             '+
                            '    \"contact_last_name\": \"Hößl\",                                '+
                            '    \"contact_phone_number\": \"012334 7868676\",                   '+
                            '    \"contact_salutation\": \"Herr\",                               '+
                            ' }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ZWBContactUpdate/'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        
        ksgZWBContactUpdateController.updateContact('8b7c8e76-8de6-d3ff-8ffb-197e6980fc19', 
                                                       'test@test.de',
                                                       'hgsdjasd',
                                                       'adasdasdasd',
                                                       '234234',
                                                       'Herr');

                                        
    }

    
    
}