/****************************************************************************************************************************
// Erstellt 12.09.2017 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// HTTP request JSON
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// controller HNR API call. Controller will decide about converting the lead to opportunity or updating the opportunity status based on the comming information.
// the status of the opportunity is set to "Prospekt Mkt cloud"
//
//****************************************************************************************************************************
// Änderungen
// 23.10.2018   MZ  #161257706 wizard version added
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@RestResource(urlMapping='/hnrGenController/*')
// dev :    https://dev-pflegede.cs84.force.com/services/apexrest/hnrGenController
// FS:      https://fs-pflegede.cs80.force.com/services/apexrest/hnrGenController
// Prod:    https://pflegede.EU6.force.com/services/apexrest/hnrGenController


global class ksgHnrGeneralPurposeController {
    
    @HttpPost 
    global static string createNewLead( String created_at,
                                        String Order_ID,
                                        String wizard_name,
                                        String device_type,
                                        String emergency_contact,
                                        String urgency,
                                        String needed_in_zip_code,
                                        String needed_in_city,
                                        String target_person,
                                        String care_level_state,
                                        String referrer,
                                        String zustand,
                                        String unterwegs,
                                        String sturz,
                                        String notfall_nachbarn,
                                        String referenznummer,                                  
                                        contact_hnr contact_hnr,
                                        String Partner_ID,
                                        string GCLID,
                                        string UserID,
                                        string Preferred_timeframe,
                                        String wizard_version) {
        boolean doppelt_OrderId = false;
        string ret = 'OK';                                  
        id rtid = null;       
        id ownid = UserInfo.getUserId();  
        try {      
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Notrufsysteme'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        else {
            return 'Error: RecordType Notrufsysteme not found for sObjectType lead'; 
        }
        list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
        if((usList != null) && (usList.size() > 0)) {
            ownid = usList[0].id;
        }       
        
        lead l = new lead(Company='Notrufsysteme', Status='Open');
        l.RecordTypeId = rtid;  
        l.OwnerID = ownid;
        l.OM_created_at__c = created_at;
        l.OM_Tracking_Order_ID__c = Order_ID;
        l.OM_Wizard_Version__c = wizard_version;
        l.TL_Treppenliftart__c = device_type;
        l.OM_Referrer__c = referrer; 
        l.GCLID__c = GCLID;
        l.Person_des_Bedarfs__c = target_person;
        l.TL_Postleitzahl_f_r_Suche__c = needed_in_zip_code;
        l.Wohnort_der_Suche__c = needed_in_city;
        l.OM_UserId__c = UserID;
        
        // map the values of Pflegegrad field
        if(!String.isEmpty(care_level_state)){
            if(care_level_state == 'Ja' || care_level_state == 'Pflegegrad vorhanden' ){
                l.Pflegegrad__c = 'Pflegegrad vorhanden';
            }
            if(care_level_state == 'Nein' || care_level_state == 'Keinen Pflegegrad' ){
                l.Pflegegrad__c = 'Keinen Pflegegrad';
            }
            if(care_level_state == 'Beantragt' || care_level_state == 'Pflegegrad beantragt' ){
                l.Pflegegrad__c = 'Pflegegrad beantragt';
            }
            if(care_level_state == 'Unklar' || care_level_state == 'Noch unklar' ){
                l.Pflegegrad__c = 'Noch unklar';
            }
        }
        
        l.Zeitpunkt_der_Versorgung__c = urgency;
        l.emergency_contact__c = emergency_contact;
        
        l.koerperlicher_Zustand__c = zustand;
        l.alleine_au_er_Haus__c = unterwegs;
        l.soforthilfe_vor_Ort__c = notfall_nachbarn;
        l.in_letzter_Zeit_gest_rzt__c = sturz;
                                 
        
        if(contact_hnr != null) {
            try { 
                l.Email = contact_hnr.contact_mail_from;
                l.Firstname = contact_hnr.contact_first_name;
                l.Lastname = contact_hnr.contact_last_name;
                l.Phone = contact_hnr.contact_phone_number;
                l.Salutation = contact_hnr.contact_salutation;
                l.postalcode = contact_hnr.contact_zip_code;
                l.City = contact_hnr.contact_city;
                l.Street = contact_hnr.contact_street;
                l.Phone2__c = contact_hnr.contact_phone2;
            }
            catch (System.Exception e) {
                ret = 'Error: ' + e.getMessage();
            }
        }       
        l.OM_Partner_ID__c = Partner_ID;
        l.OM_Referenznummer__c = referenznummer;
        
        // #154212180
        if(!String.isEmpty(Preferred_timeframe)){
            if(Preferred_timeframe.containsignoreCase('nachmittag') || Preferred_timeframe.containsignoreCase('18')){
                l.Preferred_timeframe__c = Nachtelefonie_einrichten.Preferred_timeframe_Nachmittags;
            }
            else if(Preferred_timeframe.containsignoreCase('vormittag') || Preferred_timeframe.containsignoreCase('8')){
                l.Preferred_timeframe__c = Nachtelefonie_einrichten.Preferred_timeframe_Vormittags;
            }
            else{
                l.Preferred_timeframe__c = Nachtelefonie_einrichten.Preferred_timeframe_Mittags;
            }
        }
        
        // check dulicate of Tracking Order Id
        List<lead> toUpdateLeads = new List<lead>();
        List<Contact> toUpdateContacts = new List<Contact>();
        List<Kunde__c> toUpdateKunde = new List<Kunde__c>();
        list<lead> doppList_OrderId = [SELECT id, isConverted FROM lead WHERE OM_Tracking_Order_ID__c = :l.OM_Tracking_Order_ID__c];
        if((doppList_OrderId != null) && (doppList_OrderId.size() > 0) ){
            doppelt_OrderId = true;
            if(!String.isEmpty(UserID)){
                for(Lead dl : doppList_OrderId){
                    if(!dl.isConverted){
                        dl.OM_UserID__c = UserID;
                        toUpdateLeads.add(dl);
                    }
                }
            }
        }
        
        // Ursprungsanfrage2
        List<Campaign> cmplist = [select id, name from Campaign where name =: wizard_name LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) {
            l.OM_Wizzard_Name2__c = cmplist[0].Id;      
        }
        else return 'Error: Campaign ' + wizard_name + ' not found.';  
       
        if(! doppelt_OrderId) {
            // create lead
           // Savepoint sp = Database.setSavepoint();
            try {
                insert l;
                if((!String.isEmpty(l.OM_Referenznummer__c) )&& String.isEmpty(l.Phone) && String.isEmpty(l.Phone2__c)){
                    ret = Lead_to_Opportunity_Auto.convertLeadToOpportunity(l);
                }
                if(ret != 'OK'){
                   // Database.rollback(sp);
                }
            }
            catch (Exception e) {
                // Roll the database back to before we saved ANYTHING
                //Database.rollback(sp);
                ret = 'Error: ' + e.getMessage(); 
                system.debug('#########################error ' + e);
            }
        }
        else{
            // check if the phone number of the contact should be updated.
            if(!String.isEmpty(l.OM_Referenznummer__c)){
                // call update opportunity and contact with phone_number
                ret = Prospect_Opportunity.updateContactPhone(l.OM_Referenznummer__c, 
                                                                l.Phone, l.Phone2__c, 
                                                                l.postalcode, l.City, 
                                                                l.Street, 
                                                                l.TL_Postleitzahl_f_r_Suche__c, 
                                                                l.Wohnort_der_Suche__c);
            }else{
                ret = 'Error: a Lead with the Order_ID already exists.' ;
            }
        }
        
        // #145581229 set userID
        if(!String.isEmpty(UserID)){
            Set<Id> contactIds = new Set<Id>();
            Set<Id> kundeIds = new Set<Id>();
            String keyword = '%'+ Order_ID + '%';
            List<OpportunityContactRole> opcr_list = [select ContactId, opportunity.OM_Tracking_Order_ID__c from OpportunityContactRole where opportunity.OM_Tracking_Order_ID__c like: keyword ];
            for(OpportunityContactRole r : opcr_list){
                contactIds.add(r.ContactId);
            }
            toUpdateContacts = [select Id, OM_USERID__c, Passender_CB_Kunde__c from Contact where id in :contactIds];
            for(Contact c : toUpdateContacts){
                c.OM_UserId__c = UserID;
                if(!String.isEmpty(c.Passender_CB_Kunde__c)){
                    kundeIds.add(c.Passender_CB_Kunde__c);
                }
            }
            toUpdateKunde = [select id, OM_USERID__c from Kunde__c where id in :kundeIds ];
            for(Kunde__c k : toUpdateKunde){
                k.OM_UserId__c = UserID;
            }
        }
        
        try{
            update toUpdateLeads;
            update toUpdateContacts;
            update toUpdateKunde;
        }
        catch (System.Exception e) {
            system.debug('#########################error ' + e);
            ret = 'Error: update failed: ' + e.getMessage();
        }
        return ret;
        }
        catch (Exception e) {
            return 'Error: ksgHnrGeneralPurposeController' + e.getMessage(); 
        }
        
    }

    global class contact_hnr {
        global String contact_mail_from {get;set;} 
        global String contact_first_name {get;set;} 
        global String contact_last_name {get;set;} 
        global String contact_phone_number {get;set;} 
        global String contact_salutation {get;set;} 
        global String contact_zip_code {get;set;} 
        global String contact_city {get;set;} 
        global String contact_street {get;set;} 
        global String contact_phone2 {get;set;} 
    }
    

}