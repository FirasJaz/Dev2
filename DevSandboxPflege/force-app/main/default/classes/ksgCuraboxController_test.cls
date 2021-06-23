@istest
public class ksgCuraboxController_test {

    static testMethod void  testPostRestService() {
        String jsonstring = '{  \"box\" : \"testbox\",'+
        '   \"ipc\" : {'+
        '        \"ip_fname\" : \"test\",'+
        '        \"ip_lname\" : \"test\",'+
        '        \"ip_zipcode\" : \"test\",'+
        '        \"ip_city\" : \"test\",'+
        '        \"ip_email\" : \"test\",'+
        '        \"ip_phone\" : \"test\",'+
        '        \"ip_born_at\" : \"test\",'+
        '        \"ip_care_level\" : \"test\",'+
        '        \"ip_insurance_number\" : \"test\",'+
        '        \"ip_salutation\" : \"test\",'+
        '        \"ip_street_nr\" : \"test\",'+
        '        \"ip_identitynumber_carrier_a\" : \"test\",'+
        '        \"ip_identitynumber_carrier_b\" : \"test\"         '+
        '       },'+
        '   \"cpc\" : {'+
        '        \"cp_fname\" : \"test\",'+
        '        \"cp_lname\" : \"test\",'+
        '        \"cp_zipcode\" : \"test\",'+
        '        \"cp_city\" : \"test\",'+
        '        \"cp_email\" : \"test\",'+
        '        \"cp_phone\" : \"test\",'+
        '        \"cp_authorized\" : \"test\",'+
        '        \"cp_salutation\" : \"test\",'+
        '        \"cp_street_nr\" : \"test\"    '+
        '       },'+
        '   \"lines\" : [ '+
        '               {   \"pos_no\" : \"1\",'+
        '                   \"ean\" : \"123456\",'+
        '                   \"menge\" : \"2\"'+
        '               },'+
        '               {   \"pos_no\" : \"2\",'+
        '                   \"ean\" : \"123456\",'+
        '                   \"menge\" : \"2\"'+
        '               },'+
        '               {   \"pos_no\" : \"3\",'+
        '                   \"ean\" : \"123456\",'+
        '                   \"menge\" : \"6\"'+
        '               },'+
        '               {   \"pos_no\" : \"4\",'+
        '                   \"ean\" : \"123456\",'+
        '                   \"menge\" : \"1\"'+
        '               }               '+
        '   ]'+
        '}';    
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/curabox'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgCuraboxController.Box b = new ksgCuraboxController.Box();
        ksgCuraboxController.marketing m = new ksgCuraboxController.marketing();
        ksgCuraboxController.Insured_person i = new ksgCuraboxController.Insured_person();
        ksgCuraboxController.care_person c = new ksgCuraboxController.care_person();
        ksgCuraboxController.care_service s = new ksgCuraboxController.care_service();
        ksgCuraboxController.pdf_form p = new ksgCuraboxController.pdf_form();
        string next_step = 'Test';
        ksgCuraboxController.createNewLead(next_step, 
                                        m, 
                                        b, 
                                        i, 
                                        c, 
                                        s,
                                        p);
    }
}