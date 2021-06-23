@istest
public with sharing class ksgCuraboxLeadController_test {
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
        req.requestURI = '/services/apexrest/curaboxlead'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(jsonstring);
        RestContext.request = req;
        RestContext.response= res;  
        ksgCuraboxLeadController.Box b = new ksgCuraboxLeadController.Box();
        ksgCuraboxLeadController.marketing m = new ksgCuraboxLeadController.marketing();
        ksgCuraboxLeadController.Insured_person i = new ksgCuraboxLeadController.Insured_person();
        ksgCuraboxLeadController.care_person c = new ksgCuraboxLeadController.care_person();
        ksgCuraboxLeadController.care_service s = new ksgCuraboxLeadController.care_service();
        ksgCuraboxLeadController.pdf_form p = new ksgCuraboxLeadController.pdf_form();
        ksgCuraboxLeadController.antrag_1 a = new ksgCuraboxLeadController.antrag_1();
        ksgCuraboxLeadController.antrag_2 d = new ksgCuraboxLeadController.antrag_2();
        ksgCuraboxLeadController.mc_infos mc_infos = new ksgCuraboxLeadController.mc_infos();
        string next_step = 'Test';
        ksgCuraboxLeadController.createNewLead(next_step, 
                                        m, 
                                        b, 
                                        i, 
                                        c, 
                                        s,
                                        p,
                                        a,
                                        d,
                                        mc_infos);
    }
}