@isTest
public class ksgHnrGeneralPurposeController_test {

    static testMethod void  testPostRestService() {
    
        Campaign camp = new Campaign(name ='testKSGcontroller');
        insert camp;
        
        string jsonstring = '{                                                                   '+
                            '  \"created_at\": \"2017-01-19T11:17:31+01:00\",                    '+
                            '  \"Order_ID\": \"8b7c8e7632116168ffb-197e6980fc19\",           '+
                            '  \"wizard_name\": \"testKSGcontroller\",                           '+     
                            '  \"device_type\": \"Mobile Notruflösung\",                         '+         
                            '  \"emergency_contact\": \"Notrufzentrale\",                        '+         
                            '  \"urgency\": \"Schnellstmöglich\",                                '+                                     
                            '  \"needed_in_zip_code\": \"99991\",                                '+
                            '  \"needed_in_city\": \"Großengottern\",                                   '+
                            '  \"target_person\": \"Für mich\",                                  '+
                            '  \"care_level_state\": \"Beantragt\",                   '+
                            '  \"referrer\": \"http://service-neu.pflege.localhost/24h-pflege\", '+
                            '  \"zustand\": \"eingeschränkt mobil\", '+
                            '  \"unterwegs\": \"Selten\", '+
                            '  \"sturz\": \"Mehrfach\", '+
                            '  \"notfall_nachbarn\": \"Meistens\", '+
                            '  \"referenznummer\": \"NAS-121323\",                                           '+
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
        req.requestURI = '/services/apexrest/hnrMktCloud'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgHnrGeneralPurposeController.contact_hnr c = new ksgHnrGeneralPurposeController.contact_hnr();
        c.contact_last_name = 'test';
        c.contact_phone_number = '';
        c.contact_phone2 = '';

        Campaign cmp = new Campaign(name ='testWizard');
        insert cmp;
        
        ksgHnrGeneralPurposeController.createNewLead( '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'testWizard',
                                        'Mobile Notruflösung',
                                        'Notrufzentrale',
                                        'Schnellstmöglich',
                                        '12347', 
                                        'Berlin', 
                                        'Für mich', 
                                        'Beantragt', 
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        '',
                                        '',
                                        'selten',
                                        'meistens',
                                        'NAS-255304', 
                                        c, 
                                        '', '', '1233456789', '18:00', 'v 1.1');
                                        
         ksgHnrGeneralPurposeController.createNewLead( '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'testWizard',
                                        'Mobile Notruflösung',
                                        'Notrufzentrale',
                                        'Schnellstmöglich',
                                        '12347', 
                                        'Berlin', 
                                        'Für mich', 
                                        'Beantragt', 
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        '',
                                        '',
                                        'selten',
                                        'meistens',
                                        'NAS-255304', 
                                        c, 
                                        '', '', '1233456789', '', 'v 1.1');
    }
}