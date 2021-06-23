@istest
public class ksgInkoController_test {
    
    public class jsonWrapper{
        public string created_at {get; set;}
        public string referrer {get; set;}
        public string type {get; set;}
        public string wizard_state {get; set;}
        public string wizard_name {get; set;}
        public string product {get; set;}
        public string product_type {get; set;}
        public string gender {get; set;}
        public string own_use {get; set;}
        public string already_in_use {get; set;}
        public string situation {get; set;}
        public string product_inco {get; set;}
        public string change_cycle {get; set;}
        public string liquid_amount {get; set;}
        public string size {get; set;}
        public string Order_ID {get; set;}
        public string Partner_ID {get; set;}
        public string newsletter {get; set;}
        public string product_id1 {get; set;}
        public string product_id2 {get; set;}
        public string product_id3 {get; set;}
        public string product_id4 {get; set;}
        public string product_id5 {get; set;} 
        
        public string prescription_exists {get; set;} 
        public string covered_by_insurance {get; set;} 
        public string needs_support {get; set;} 

        public cont_inko ci {get; set;}
        public String wizard_version {get; set;}
    }
    
    public class cont_inko {
        public String contact_mail_from {get;set;} 
        public String contact_first_name {get;set;} 
        public String contact_last_name {get;set;} 
        public String contact_phone_number {get;set;} 
        public String contact_salutation {get;set;} 
        public String contact_zip_code {get;set;} 
        public String contact_city {get;set;} 
        public String contact_street {get;set;}     
    }
    
    static testMethod void  testPostRestService(){
        ksgInkoController.Contact_inko ci = new ksgInkoController.Contact_inko();
        jsonWrapper js = new jsonWrapper();
        js.product = 'Inkontinenz'; 
        ci.contact_mail_from = 'mail@mail.com';
        ci.contact_last_name = 'lastname';
        ci.contact_salutation = 'Herr';
        
        Campaign cmp = new Campaign();
        cmp.Name = 'ksg_test_ksgInko';
        insert cmp;
        js.wizard_name = cmp.name;
        
        String JsonMsg=JSON.serialize(js);
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/pflegeinkosb'; 
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response= res;
        
        ksgInkoController.createNewLead(js.created_at, 
                                        js.referrer, 
                                        js.type, 
                                        js.wizard_state, 
                                        js.wizard_name,
                                        js.product, 
                                        js.product_type, 
                                        js.gender, 
                                        js.own_use,
                                        js.already_in_use, 
                                        js.situation, 
                                        js.product_inco, 
                                        js.change_cycle,
                                        js.liquid_amount, 
                                        js.size, 
                                        js.Order_ID, 
                                        js.Partner_ID, 
                                        js.newsletter,
                                        js.product_id1, 
                                        js.product_id2, 
                                        js.product_id3, 
                                        js.product_id4, 
                                        js.product_id5, 
                                        js.prescription_exists,
                                        js.covered_by_insurance,
                                        js.needs_support,
                                        ci, 
                                        js.wizard_version);

                                        
        Test.stopTest();
    }

}