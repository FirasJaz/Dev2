@isTest
public class ksgPflegeimmobilienController_test {

    static testMethod void  testPostRestService() {
        Campaign cm = new Campaign(name='care_property_wizard', status='In Progress');
        insert cm;
    
        string jsonstring = '{                                                                   '+
                            '  \"created_at\": \"2017-01-19T11:17:31+01:00\",                    '+
                            '  \"Order_ID\": \"8b7c8e76-8de6-d3ff-8ffb-197e6980fc19\",           '+
                            '  \"wizard_name\": \"care_property_wizard\",                           '+      
                            '  \"location_direction\": \"Westdeutschland\",                      '+             
                            '  \"own_use\": \"Nein\",                                            '+
                            '  \"financing_model\": \"Finanzierung\",                                    '+
                            '  \"referrer\": \"http://service-neu.pflege.localhost/24h-pflege\", '+
                            '  \"contact_immo\": {                                                '+
                            '    \"contact_mail_from\": \"test@pflege.de\",                      '+
                            '    \"contact_first_name\": \"Tobias\",                             '+
                            '    \"contact_last_name\": \"Hößl\",                                '+
                            '    \"contact_phone_number\": \"012334 7868676\",                   '+
                            '    \"contact_salutation\": \"Herr\",                               '+
                            '  },                                                                '+
                            '  \"Partner_ID\": \"\"                                              '+ 
                            ' }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/treppenlift'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgPflegeimmobilienController.contact_immo c = new ksgPflegeimmobilienController.contact_immo();
        c.contact_last_name = 'test';
        c.contact_first_name = 'test';
        c.contact_mail_from = 'test@pflege.de';
        c.contact_phone_number = '123';
        c.contact_salutation = 'Herr';
        
        ksgPflegeimmobilienController.createNewLead(    '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'care_property_wizard',
                                        'Westdeutschland',
                                        'Nein', 
                                        'Finanzierung', 
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        c, 
                                        '', '', '123456789', '18:00', 'v 1.1');
                                        
        ksgPflegeimmobilienController.createNewLead(    '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'care_property_wizard',
                                        'Westdeutschland',
                                        'Nein', 
                                        'Finanzierung', 
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        c, 
                                        '', '', '123456789', '', 'v 1.1');
                                        
    }
}