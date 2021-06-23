/****************************************************************************************************************************
// Erstellt 28.08.2015 von AM
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: JSON File 
//
//****************************************************************************************************************************
//
// Beschreibung: Erstellen ein lead aus JSON
//                
//
//****************************************************************************************************************************
//Änderungen:
//  04.12.2015 von AM   #107897754 3 Felder hinzugefügt
//  23.10.2018   MZ     #161257706 wizard version added
*/

@RestResource(urlMapping='/pflegeinkosb/*')
global class ksgInkoController {
    
    @HttpPost 
    global static String createNewLead( String created_at, 
                                        String referrer,
                                        String type, 
                                        String wizard_state, 
                                        String wizard_name, 
                                        String product,
                                        String product_type,
                                        String gender, 
                                        String own_use, 
                                        String already_in_use, 
                                        String situation,    
                                        String product_inco,
                                        String change_cycle, 
                                        String liquid_amount,
                                        String size, 
                                        String Order_ID, 
                                        String Partner_ID, 
                                        String newsletter, 
                                        String product_id1,
                                        String product_id2, 
                                        String product_id3, 
                                        String product_id4, 
                                        String product_id5,
                                        String prescription_exists,
                                        String covered_by_insurance,
                                        String needs_support,
                                        Contact_inko contact_inko,
                                        String wizard_version) {
        id rtid = null;                                
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name=: Product];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }        
        lead l = new lead(Company='inko', Status='Open');
        l.RecordTypeId = rtid;
        l.OM_created_at__c = created_at;
        l.OM_Referrer__c = referrer;
        l.inko_type__c = type;
        l.next_step__c = Product_type;
        l.inko_product_type__c = product_inco;
        l.inko_wizard_state__c = wizard_state;
        List<Campaign> cmplist = [select id, name from Campaign where name =: wizard_name LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) l.OM_Wizzard_Name2__c = cmplist[0].Id;
        l.inko_gender__c = gender;
        l.inko_own_use__c = own_use;
        l.inko_already_in_use__c = already_in_use;
        l.inko_situation__c = situation;
        l.inko_change_cycle__c = change_cycle;
        l.inko_liquid_amount__c = liquid_amount;
        l.inko_size__c = size;
        l.OM_Tracking_Order_ID__c = Order_ID;
        l.OM_Wizard_Version__c = wizard_version;
        l.OM_Partner_ID__c = Partner_ID;
        l.OM_Newsletter__c = newsletter;
        l.inko_product_id1__c = product_id1;
        l.inko_product_id2__c = product_id2;
        l.inko_product_id3__c = product_id3;
        l.inko_product_id4__c = product_id4;
        l.inko_product_id5__c = product_id5;
        
        // 04.12.2015
        l.inko_recipe__c = prescription_exists;
        l.inko_insurance__c = covered_by_insurance;
        l.inko_support__c = needs_support;  
        if(contact_inko != null) {
            l.Email = contact_inko.contact_mail_from;
            l.LastName = contact_inko.contact_last_name;
            l.FirstName = contact_inko.contact_first_name;
            l.Street = contact_inko.contact_street;
            l.PostalCode = contact_inko.contact_zip_code;
            l.City = contact_inko.contact_city;
            l.Phone = contact_inko.contact_phone_number;
            l.salutation = contact_inko.contact_salutation;
        }

        
        insert l;

        return 'OK';
   }
   
    global class Contact_inko {
        global String contact_mail_from {get;set;} 
        global String contact_first_name {get;set;} 
        global String contact_last_name {get;set;} 
        global String contact_phone_number {get;set;} 
        global String contact_salutation {get;set;} 
        global String contact_zip_code {get;set;} 
        global String contact_city {get;set;} 
        global String contact_street {get;set;} 
    }
}