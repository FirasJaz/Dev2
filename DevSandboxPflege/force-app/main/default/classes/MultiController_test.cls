@isTest
public class MultiController_test {

    static testMethod void  testPostRestService() {
        string jsonstring = '{                                                                   '+
                            '  \"created_at\": \"2017-01-19T11:17:31+01:00\",                    '+
            				'  \"wizard_version\": \"v1\",                    					'+               
            				'  \"Order_ID\": \"8b7c8e76-8de6-d3ff-8ffb-197e6980fc19\",           '+
                            '  \"wizard_name\": \"multilead_wizard\",                           '+
                            '  \"referrer\": \"http://service.pflege.local/multilead/2?show_cc=false&is_iframe=true&preselect=13,14,20\", '+
                            '    \"contact_first_name\": \"Dennis\",                             '+
                            '    \"contact_last_name\": \"Zietkoff\",                            '+
                            '    \"contact_phone_number\": \"012334 7868676\",                   '+
                            '    \"contact_salutation\": \"Herr\",                               '+
                            '   \"topics_multilead": "Stundenweise Betreuung"   			     '+
                            '  \"Partner_ID\": \"\"                                              '+ 
                            '  \"UserID\": \"d588223c-cb15-4be2-8044-20f46043638c\"              '+
							'  \"GCLID\": \"\"                                              '+             
                            ' }';
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/MultiController/*'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        list<string> ct = new list<string>();

        
        MultiController.createNewLead('2017-01-19T11:17:31+01:00', 'v1', '8b7c8e76-8de6-d3ff-8ffb-197e6980fc19','multilead_wizard', 'http://service.pflege.local/multilead/2?show_cc=false&is_iframe=true&preselect=13,14,20', 'Dennis', 'Zietkoff', '012334 7868676',  'Herr',  'Stundenweise Betreuung', '', 'd588223c-cb15-4be2-8044-20f46043638c', '');
                                        
        MultiController.createNewLead('2017-01-19T11:17:31+01:00', 'v1', '8b7c8e76-8de6-d3ff-8ffb-197e6980fc19','multilead_wizard', 'http://service.pflege.local/multilead/2?show_cc=false&is_iframe=true&preselect=13,14,20', 'Dennis', 'Zietkoff', '012334 7868676',  'Herr',  'Stundenweise Betreuung', '', 'd588223c-cb15-4be2-8044-20f46043638c', '');
                                        
    }
}