@isTest
public class ksgHnrController_test {

    static testMethod void  testPostRestService() {
        string jsonstring = '{                                                                   '+
                            '  \"created_at\": \"2017-01-19T11:17:31+01:00\",                    '+
                            '  \"Order_ID\": \"8b7c8e76-8de6-d3ff-8ffb-197e6980fc19\",           '+
                            '  \"wizard_name\": \"hausnotruf_wizard\",                           '+     
                            '  \"device_type\": \"Mobile Notruflösung\",                         '+         
                            '  \"emergency_contact\": \"Notrufzentrale\",                        '+         
                            '  \"urgency\": \"Schnellstmöglich\",                                '+                                     
                            '  \"needed_in_zip_code\": \"12347\",                                '+
                            '  \"needed_in_city\": \"Berlin\",                                   '+
                            '  \"target_person\": \"Für mich\",                                  '+
                            '  \"care_level_state\": \"Pflegegrad beantragt\",                   '+
                            '  \"referrer\": \"http://service-neu.pflege.localhost/24h-pflege\", '+
                            '  \"change_cycle\": \"\",                                           '+
                            '  \"contact_hnr\": {                                                '+
                            '    \"contact_mail_from\": \"test@pflege.de\",                      '+
                            '    \"contact_first_name\": \"Tobias\",                             '+
                            '    \"contact_last_name\": \"Hößl\",                                '+
                            '    \"contact_phone_number\": \"012334 7868676\",                   '+
                            '    \"contact_salutation\": \"Herr\",                               '+
                            '    \"contact_zip_code\": null,                                     '+
                            '    \"contact_city\": null,                                         '+
                            '    \"contact_street\": \" \"                                       '+
                            '    \"contact_phone2\": \" \"                                       '+
                            '  },                                                                '+
                            '  \"Partner_ID\": \"\"                                              '+ 
                            ' }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/hnr'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgHnrController.contact_hnr c = new ksgHnrController.contact_hnr();
        c.contact_last_name = 'test';

        Campaign cmp = new Campaign(name ='testWizard');
        insert cmp;
        
        ksgHnrController.createNewLead( '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'testWizard',
                                        'Mobile Notruflösung',
                                        'Notrufzentrale',
                                        'Schnellstmöglich',
                                        '12347', 
                                        'Berlin', 
                                        'Für mich', 
                                        'Pflegegrad beantragt', 
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        '', 
                                        c, 
                                        '123',
                                        '',
                                        '123456789',
                                        '18:00', 'v 1.1');
                                        
        ksgHnrController.createNewLead( '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'testWizard',
                                        'Mobile Notruflösung',
                                        'Notrufzentrale',
                                        'Schnellstmöglich',
                                        '12347', 
                                        'Berlin', 
                                        'Für mich', 
                                        'Pflegegrad beantragt', 
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        '', 
                                        c, 
                                        '123',
                                        '',
                                        '123456789',
                                        '', 'v 1.1');
                                        
    }
}