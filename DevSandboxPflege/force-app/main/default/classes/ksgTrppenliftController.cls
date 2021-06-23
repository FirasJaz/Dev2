/****************************************************************************************************************************
// Erstellt 05.08.2016 von WDS
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
// controller für Trppenlift landingpage
//
//
//****************************************************************************************************************************
// Änderungen
// 21.10.2016 AM    Prüfung auf doppelte OM_Tracking_Order_ID__c 
// 07.06.2017 AM    Erweitern um target_person und  care_level_state (Analog zu HNR)
// 06.12.2017 MZ    #145581229 set UserId in Lead/Contact/kunde
// 16.01.2018 MZ    #154212180
// 23.10.2018 MZ    #161257706 wizard version added
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@RestResource(urlMapping='/treppenlift/*')
global class ksgTrppenliftController {



    @HttpPost 
    global static string createNewLead( string created_at,
                                        string Order_ID,
                                        string wizard_name,
                                        string lift_type,
                                        string mounting_location,
                                        string obstacle,
                                        string floor,
                                        string living_situation,
                                        string care_person_weight,
                                        string callback_days,
                                        string callback_time,
                                        string contact_area_code_2,
                                        string contact_phone_number_2,
                                        string type,
                                        String target_person,
                                        String care_level_state,
                                        string referrer,
                                        string change_cycle,
                                        contact_stairlft contact_stairlft,
                                        string Partner_ID,
                                        string contact_rueckruf,
                                        string GCLID,
                                        string UserID,
                                        string Preferred_timeframe,
                                        String wizard_version) {
        
        boolean doppelt = false;
        
        id rtid = null;    
        id ownid = UserInfo.getUserId(); 
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name= 'Treppenlift'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        } 

        list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
        if((usList != null) && (usList.size() > 0)) {
            ownid = usList[0].id;
        }       
        
        lead l = new lead(Company='Treppenlift', Status='Open');
        l.RecordTypeId = rtid;  

        l.OM_UserId__c = UserID;
        l.OM_created_at__c = created_at;
        l.OM_Tracking_Order_ID__c = Order_ID;
        l.OM_Wizard_Version__c = wizard_version;
        l.GCLID__c = GCLID;
        
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
        
        
        list<lead> doppList = [SELECT id, OM_UserID__c, isConverted FROM lead WHERE OM_Tracking_Order_ID__c = :l.OM_Tracking_Order_ID__c];
        List<lead> toUpdateLeads = new List<lead>();
        List<Contact> toUpdateContacts = new List<Contact>();
        List<Kunde__c> toUpdateKunde = new List<Kunde__c>();
        if((doppList != null) && (doppList.size() > 0) ){
            doppelt = true;
            if(!String.isEmpty(UserID)){
                for(Lead dl : doppList){
                    if(!dl.isConverted){
                        dl.OM_UserID__c = UserID;
                        toUpdateLeads.add(dl);
                    }
                }
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
        
        
        List<Campaign> cmplist = [select id, name from Campaign where name =: wizard_name LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) l.OM_Wizzard_Name2__c = cmplist[0].Id;
        l.TL_Treppenliftart__c = lift_type;
        l.Umgebung__c = mounting_location;
        l.TL_Zu_berwindendes_Hindernis__c = obstacle;
        l.TL_Anzahl_der_Etagen__c = floor;
        l.TL_H_usliche_Situation__c = living_situation;
        l.TL_Belastbarkeit__c = care_person_weight;
        l.R_ckrufm_glichkeit__c = contact_rueckruf;
        
        
        l.TL_Postleitzahl_f_r_Suche__c = contact_area_code_2;
        
        l.Person_des_Bedarfs__c = target_person;
        l.Pflegegrad__c = care_level_state;
        
        l.OM_Referrer__c = referrer;
        
        if(contact_stairlft != null) {
            try { 
                l.Email = contact_stairlft.contact_mail_from;
                l.Firstname = contact_stairlft.contact_first_name;
                l.Lastname = contact_stairlft.contact_last_name;
                l.Phone = contact_stairlft.contact_phone_number;
                l.Salutation = contact_stairlft.contact_salutation;
                l.TL_Postleitzahl_f_r_Suche__c = contact_stairlft.contact_zip_code;
                l.City = contact_stairlft.contact_city;
                l.Street = contact_stairlft.contact_street;
                l.Phone2__c = contact_stairlft.contact_phone2;
            }
            catch (System.Exception e) {}
        }
        
        l.OM_Partner_ID__c = Partner_ID;
        l.OwnerID = ownid;
        if(!doppelt) {
            try {
                insert l;
            }
            catch (System.Exception e) {
                system.debug('#########################error ' + e);
            }
        }
        try{
            update toUpdateLeads;
            update toUpdateContacts;
            update toUpdateKunde;
        }
        catch (System.Exception e) {
            system.debug('#########################error ' + e);
        }
        return 'OK';
    }

    global class contact_stairlft {
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