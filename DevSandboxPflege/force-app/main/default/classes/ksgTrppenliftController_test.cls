@isTest
public class ksgTrppenliftController_test {

    static testMethod void  testPostRestService() {
        string jsonstring = '{                                                                   '+
                            '  \"created_at\": \"2017-01-19T11:17:31+01:00\",                    '+
                            '  \"Order_ID\": \"8b7c8e76-8de6-d3ff-8ffb-197e6980fc19\",           '+
                            '  \"wizard_name\": \"hausnotruf_wizard\",                           '+     
                            '  \"lift_type\": \"Mobile Notruflösung\",                       '+             
                            '  \"mounting_location\": \"12347\",                                '+
                            '  \"obstacle\": \"Berlin\",                                        '+
                            '  \"floor\": \"1\",                                           '+
                            '  \"living_situation\": \"1\",                                           '+
                            '  \"care_person_weight\": \"1\",                                           '+
                            '  \"callback_days\": \"1\",                                           '+
                            '  \"callback_time\": \"1\",                                           '+
                            '  \"contact_area_code_2\": \"1\",                                           '+
                            '  \"contact_phone_number_2\": \"1\",                                           '+
                            '  \"type\": \"1\",                                           '+
                            '  \"target_person\": \"Für mich\",                                  '+
                            '  \"care_level_state\": \"Pflegegrad beantragt\",                   '+
                            '  \"referrer\": \"http://service-neu.pflege.localhost/24h-pflege\", '+
                            '  \"change_cycle\": \"\",                                           '+
                            '  \"contact_stairlft\": {                                                '+
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
                            '  \"contact_rueckruf\": \"\"                                              '+   
                            ' }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/treppenlift'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgTrppenliftController.contact_stairlft c = new ksgTrppenliftController.contact_stairlft();
        c.contact_last_name = 'test';

        
        ksgTrppenliftController.createNewLead(  '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'hausnotruf_wizard',
                                        'Mobile Notruflösung',
                                        '12347', 
                                        'Berlin', 
                                        '', '', '', '', '', '', '', '',
                                        'Für mich', 
                                        'Pflegegrad beantragt', 
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        '', 
                                        c, 
                                        '123', '', '', '123456789', '18:00', 'v 1.1');
                                        
        ksgTrppenliftController.createNewLead(  '2017-01-19T11:17:31+01:00', 
                                        '8b7c8e76-8de6-d3ff-8ffb-197e6980fc1', 
                                        'hausnotruf_wizard',
                                        'Mobile Notruflösung',
                                        '12347', 
                                        'Berlin', 
                                        '', '', '', '', '', '', '', '',
                                        'Für mich', 
                                        'Pflegegrad beantragt', 
                                        'http://service-neu.pflege.localhost/24h-pflege',
                                        '', 
                                        c, 
                                        '123', '', '', '123456789', '', 'v 1.1');                                        
    }
}