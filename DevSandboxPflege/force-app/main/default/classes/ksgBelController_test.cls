@isTest
public class ksgBelController_test {

    static testMethod void  testPostRestService() {
        string jsonstring = '{                                                                   '+
                            '  \"created_at\": \"2017-01-19T11:17:31+01:00\",                    '+
                            '  \"Order_ID\": \"8b7c8e76-8de6-d3ff-8ffb-197e6980fc19\",           '+
                            '  \"wizard_name\": \"24h_pflege_wizard\",                           '+
                            '  \"referrer\": \"http://service-neu.pflege.localhost/24h-pflege\", '+
                            '  \"needed_in_zip_code\": \"12347\",                                '+
                            '  \"needed_in_city\": \"Berlin\",                                   '+
                            '  \"target_person\": \"Für mich\",                                  '+
                            '  \"care_type\": [\"Medizinische Pflege\", \"Hauswirtschaft\"],     '+
                            '  \"accomodation\": \"Wohnung\",                                    '+
                            '  \"urgency\": \"Innerhalb eines Monats\",                          '+
                            '  \"care_level_state\": \"Pflegegrad beantragt\",                   '+
                            '  \"frequency\": \"Pflegegrad beantragt\",                           '+
                            '  \"contact_stairlft\": {                                           '+
                            '    \"contact_mail_from\": \"test@pflege.de\",                      '+
                            '    \"contact_first_name\": \"Tobias\",                             '+
                            '    \"contact_last_name\": \"Hößl\",                                '+
                            '    \"contact_phone_number\": \"012334 7868676\",                   '+
                            '    \"contact_phone2\": \"0171 7868676\",                   '+                            
                            '    \"contact_salutation\": \"Herr\",                               '+
                            '    \"contact_zip_code\": null,                                     '+
                            '    \"contact_city\": null,                                         '+
                            '    \"contact_street\": \" \"                                       '+
                            '  },                                                                '+
                            '  \"contact_rueckruf\": \"\",                                       '+
                            '  \"Partner_ID\": \"\"                                              '+ 
                            ' }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/bel'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgBelController.contact_stairlft c = new ksgBelController.contact_stairlft();
        c.contact_last_name = 'test';
        list<string> ct = new list<string>();
        ct.add('Medizinische Pflege');
        ct.add('Hauswirtschaft');
        
        ksgBelController.createNewLead( '2017-01-19T11:17:31+01:00', '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', '24h_pflege_wizard',
                                        'http://service-neu.pflege.localhost/24h-pflege', '12347', 'Berlin', 'Für mich', ct,
                                        'Wohnung', 'Innerhalb eines Monats', 'Pflegegrad beantragt','', c, '', '', '', '', '123456789', '18:00', 'v 1.1');
                                        
        ksgBelController.createNewLead( '2017-01-19T11:17:31+01:00', '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', '24h_pflege_wizard',
                                        'http://service-neu.pflege.localhost/24h-pflege', '12347', 'Berlin', 'Für mich', ct,
                                        'Wohnung', 'Innerhalb eines Monats', 'Pflegegrad beantragt','', c, '', '', '', '', '123456789', '', 'v 1.1');
                                        
    }
}