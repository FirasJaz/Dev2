/****************************************************************************************************************************
// Erstellt 04.05.2018 von MZ
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
// controller für Bad landingpage
// instance number is required regardless of the environment
//
//
//****************************************************************************************************************************
// Änderungen
// 23.10.2018   MZ  #161257706 wizard version added
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@RestResource(urlMapping='/bad/*')
// dev :    https://dev-pflegede.cs84.force.com/services/apexrest/bad/
// FS:      https://fs-pflegede.cs80.force.com/services/apexrest/bad/
// Prod:    https://pflegede.EU6.force.com/services/apexrest/bad/

/*********** request:
{
  "created_at": "",
  "Order_ID": "",
  "wizard_name": "",
  "construction_general": "",
  "construction_type": "",
  "small_barrier": "",
  "target_person": "",
  "living_situation": "",
  "modification_floor": "",
  "care_level_state": "",
  "landlord_approves": "",
  "care_for_grant": " ",
  "care_person_salutation": "",
  "care_person_first_name": "",
  "care_person_last_name": "",
  "contact_phone_number_2": "",
  "needed_in_zip_code": "",
  "needed_in_city": "",
  "contact_street": "",
  "referrer": "",
  "GCLID":"",
  "UserID":"",
  "contact_bad": {
    "contact_mail_from": "",
    "contact_first_name": "",
    "contact_last_name": "",
    "contact_phone_number": "",
    "contact_salutation": "",
    "contact_zip_code": "",
    "contact_city": "",
    "contact_street": "",
    "contact_phone2": ""
  }
}
/***********/

global class ksgBadController {
    
    @HttpPost 
    global static string createNewLead(String created_at,
                                       String Order_ID,
                                       String wizard_name,
                                       String construction_general,
                                       String construction_type,
                                       String small_barrier,
                                       String target_person,
                                       String living_situation,
                                       String modification_floor,
                                       String care_level_state,
                                       String landlord_approves,
                                       String care_for_grant,
                                       String care_person_salutation,
                                       String care_person_first_name,
                                       String care_person_last_name,
                                       String contact_phone_number_2,
                                       String needed_in_zip_code,
                                       String needed_in_city,
                                       String contact_street,
                                       String referrer,
                                       contact_bad contact_bad,
                                       String GCLID,
                                       String UserID,
                                       String Partner_ID,
                                       String wizard_version
                                       ) {
        boolean doppelt = false;
        string ret = 'OK';     
        
        id rtid = null;       
        id ownid = UserInfo.getUserId();  
        try {      
            list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Badumbau'];
            if((rtList != null) && (rtList.size() > 0)) {
                rtId = rtList[0].id;
            }
            else {
                return 'Error: RecordType Badumbau not found for sObjectType lead'; 
            }
            list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
            if((usList != null) && (usList.size() > 0)) {
                ownid = usList[0].id;
            }       
            
            lead l = new lead(Company='Badumbau', Status='Open');
            l.RecordTypeId = rtid;  
            l.OwnerID = ownid;
            l.GCLID__c = GCLID;
            l.OM_UserId__c = UserID;
            l.OM_Partner_ID__c = Partner_ID;
            l.OM_created_at__c = created_at;
            l.OM_Tracking_Order_ID__c = Order_ID;
            l.OM_Wizard_Version__c = wizard_version;
            l.OM_Referrer__c = referrer;
            l.TL_Postleitzahl_f_r_Suche__c = needed_in_zip_code;
            l.Wohnort_der_Suche__c = needed_in_city;
            l.Person_des_Bedarfs__c = target_person;
            l.Pflegegrad__c = care_level_state;
            
            l.LandlordOwnerAgreement__c = landlord_approves;
            l.HousingSituation__c = living_situation;
            l.RemodelingSolution__c = construction_general;
            l.FloorOfRemodeling__c = modification_floor;
            l.TL_Treppenliftart__c = construction_type;
            l.TakeCareOfPossibleGrants__c = care_for_grant;
            l.EntryLevel__c = small_barrier;
            
            String pbInformation = 'Anrede : "' +care_person_salutation+'"; '+
                'Vorname : "' +care_person_first_name+'"; '+
                'Nachname : "' +care_person_last_name+'"; '+
                'Telefonnummer : "' +contact_phone_number_2+'"; '+
                'Postleitzahl : "' +needed_in_zip_code+'"; '+
                'Stadt : "' +needed_in_city+'"; '+
                'Straße : "' +contact_street+'"; ';
            
            l.extrainfo__c = pbInformation;
            
            if(contact_bad != null) {
                try { 
                    l.Email = contact_bad.contact_mail_from;
                    l.Firstname = contact_bad.contact_first_name;
                    l.Lastname = contact_bad.contact_last_name;
                    l.Phone = contact_bad.contact_phone_number;
                    l.Salutation = contact_bad.contact_salutation;
                    l.postalcode = contact_bad.contact_zip_code;
                    l.City = contact_bad.contact_city;
                    l.Street = contact_bad.contact_street;
                    l.Phone2__c = contact_bad.contact_phone2;
                }
                catch (System.Exception e) {
                    ret = 'Error: ' + e.getMessage();
                }
            }   
            
            // check dulicate
            // #145581229 set userID
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
            
            
            // Ursprungsanfrage2
            List<Campaign> cmplist = [select id, name from Campaign where name =: wizard_name LIMIT 1];        
            if(cmplist != null && cmplist.size() != 0) {
                l.OM_Wizzard_Name2__c = cmplist[0].Id;      
            }
            else return 'Error: Campaign ' + wizard_name + ' not found.';
                
            if(!doppelt) {
                try {
                    insert l;
                }
                catch (System.Exception e) {
                    ret = 'Error: ' + e.getMessage(); 
                    system.debug('#########################error ' + e);
                }
            }
            try{
                update toUpdateLeads;
                update toUpdateContacts;
                update toUpdateKunde;
            }
            catch (System.Exception e) {
                ret = 'Error: ' + e.getMessage(); 
                system.debug('#########################error ' + e);
            }
            return ret;
        }
        catch (Exception e) {
            return 'Error: ' + e.getMessage(); 
        }
    }

    global class contact_bad {
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