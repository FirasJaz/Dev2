@isTest
public class ksgWiderspruchController_test {

    static testMethod void  testPostRestService() {
        Campaign cm = new Campaign(name='widerspruch_wizard', status='In Progress');
        insert cm;
    
        string jsonstring = '{                                                                   '+
                            '  \"created_at\": \"2017-01-19T11:17:31+01:00\",                    '+
                            '  \"Order_ID\": \"8b7c8e76-8de6-d3ff-8ffb-197e6980fc19\",           '+
                            '  \"wizard_name\": \"widerspruch_wizard\",                           '+        
                            '  \"referrer\": \"http://service-neu.pflege.localhost/24h-pflege\", '+
                            '  \"contact_widerspruch\": {                                                '+
                            '    \"contact_mail_from\": \"test@pflege.de\",                      '+
                            '    \"contact_first_name\": \"Tobias\",                             '+
                            '    \"contact_last_name\": \"Hößl\",                                '+
                            '    \"contact_phone_number\": \"012334 7868676\",                   '+
                            '    \"contact_salutation\": \"Herr\",                               '+
                            '  },                                                                '+
                            '  \"contact_rueckruf\": \"Nein\",                                   '+
                            '  \"Partner_ID\": \"\"                                              '+ 
                            ' }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/widerspruch'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgWiderspruchController.contact_widerspruch c = new ksgWiderspruchController.contact_widerspruch();
        c.contact_last_name = 'test';
        c.contact_first_name = 'test';
        c.contact_mail_from = 'test@pflege.de';
        c.contact_phone_number = '123';
        c.contact_salutation = 'Herr';
        
        ksgWiderspruchController.createNewLead( '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'widerspruch_wizard',
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        c, 
                                        'Nein', 
                                        '', '', '123456789', '18:00', 'v 1.1', '', '', '', '');
                                        
        ksgWiderspruchController.createNewLead( '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'widerspruch_wizard',
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        c, 
                                        'Nein', 
                                        '', '', '123456789', '', 'v 1.1', '', '', '', '');                               
    }
}