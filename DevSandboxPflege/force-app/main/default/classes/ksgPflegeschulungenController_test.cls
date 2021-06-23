@isTest
public class ksgPflegeschulungenController_test {

    static testMethod void  testPostRestService() {
        Campaign cm = new Campaign(name='care_property_wizard', status='In Progress');
        insert cm;
    
        string jsonstring = '{                                                                   '+
                            '  \"created_at\": \"2017-01-19T11:17:31+01:00\",                    '+
                            '  \"Order_ID\": \"8b7c8e76-8de6-d3ff-8ffb-197e6980fc19\",           '+
                            '  \"wizard_name\": \"care_property_wizard\",                           '+      
                            '  \"referrer\": \"http://service-neu.pflege.localhost/24h-pflege\", '+
                            '  \"contact_wds\": {                                                '+
                            '    \"contact_mail_from\": \"test@pflege.de\",                      '+
                            '    \"contact_first_name\": \"Tobias\",                             '+
                            '    \"contact_last_name\": \"Hößl\",                                '+
                            '    \"contact_phone_number\": \"012334 7868676\",                   '+
                            '    \"contact_salutation\": \"Herr\",                               '+
                            '  }                                             '+ 
                            ' }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/treppenlift'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgPflegeschulungenController.contact_wds c = new ksgPflegeschulungenController.contact_wds();
        c.contact_last_name = 'test';
        c.contact_first_name = 'test';
        c.contact_mail_from = 'test@pflege.de';
        c.contact_phone_number = '123';
        c.contact_salutation = 'Herr';
        
        ksgPflegeschulungenController.createNewLead(    '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'care_property_wizard',
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        '123456789', '343432434', c, '', 'v 1.1');
                                        
        ksgPflegeschulungenController.createNewLead(    '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'care_property_wizard',
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        '123456789', '343432434', c, '', 'v 1.1');             
                                        
    }
}