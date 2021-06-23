/****************************************************************************************************************************
//  Erstellt 18.09.2017 von MZ
//  Klose und Srocke Gesellschaft fÃ¼r kreative KonfliktlÃ¶sungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Lead 
//
//****************************************************************************************************************************
//
// Description:
// converting lead to opportunity              
//
//****************************************************************************************************************************
//Änderungen:
// 20.10.2017 MZ   manual status change replaced by Database.LeadConvert
// 02.02.2018 MZ   #154870869 - Bestehende Opps sollen bei Dopplungen nicht angefasst werden.
// 23.10.2018   MZ  #161257706 wizard version added
//****************************************************************************************************************************
*/
global class Lead_to_Opportunity_Auto{
    private static String rt_Familienangehoerige = 'Familienangehörige';
    private static String rt_Standard = 'Standard';
    private static String rt_Familien = 'Pflege.de - Familien';


    global Lead_to_Opportunity_Auto(){
    }
    
    public static String convertLeadToOpportunity(Lead l){
        try{
            Id userId;
            list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
            if((usList != null) && (usList.size() > 0)) {
                userId = usList[0].id;
            }
            
            Contact con = getContact(l);
            Account acc;
            List<Opportunity> oppList;
            if(con.accountId == null){
                acc = getAccount(l);
                oppList = getOpportunity(l.Id, acc.Id);
            }else{
                oppList = getOpportunity(l.Id, con.accountId);
            }
            
            if(con.accountId == null){
                if(acc != null){
                    if(acc.Id == null){
                        if(userId != null) acc.OwnerId = userId;
                        insert acc;
                    }else{
                        update acc;
                    }
                    con.accountId = acc.Id;
                }
            }
            
            con.OM_UserID__c = l.OM_UserID__c;
            if(con.Id == null){
                if(userId != null) con.OwnerId = userId;
                con.Marketing_Cloud_ID__c = l.Id;
                insert con;
            }else{
                if(String.isEmpty(con.Email)){
                    con.Email = l.Email;
                }
                update con;
            }
            
            Opportunity opp;
            List<Opportunity> oppList_toUpdate = new List<Opportunity>();
            for(Opportunity o: oppList){
                if(o.Id == null){
                    opp = o;
                }else{
                    oppList_toUpdate.add(o);
                }
            }
            if(oppList_toUpdate != null && !oppList_toUpdate.isEmpty()){
                update oppList_toUpdate;
                
                //l.status = 'Ausschuss';
                l.Lead_Status_Bemerkung__c = 'Dopplung';
                update l;
                
            }
            if(opp != null){
                opp.AccountId = con.accountId;                
                
                if(String.isEmpty(con.Phone)){
                    opp.stageName ='Prospect Mkt cloud';
                }
                /*else{
                    l.Phone = con.Phone;
                }*/
                
                if(userId != null) opp.OwnerId = userId;
                
                insert opp;
                
                OpportunityContactRole ocr = new OpportunityContactRole( ContactId = con.Id,
                                                                         OpportunityId = opp.Id,
                                                                         IsPrimary = true,
                                                                          Role = 'ASP');
                if(l.Person_des_Bedarfs__c != null && l.Person_des_Bedarfs__c == 'Für mich'){
                    ocr.Role = 'PB = ASP';
                }
                insert ocr;
                
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.id);
                lc.setDoNotCreateOpportunity(true);
                lc.setAccountId(con.accountId);
                lc.setContactId(con.Id);
                System.debug('mansi:::con.accountId:::'+ con.accountId);
                System.debug('mansi:::con.Id:::'+ con.Id);

                if(oppList_toUpdate != null && !oppList_toUpdate.isEmpty()){
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Ausschuss' LIMIT 1];
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                }else{
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Qualified' LIMIT 1];
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                }

                Database.LeadConvertResult lcr = Database.convertLead(lc);
                //System.assert(lcr.isSuccess());
                
                //l.status = 'qualifiziert';
                
            }
            
            
        }
        catch (Exception e){
            return 'Error: ksgHnrGeneralPurposeController' + e.getMessage();
        }
        
        return 'OK';
    }
    
    private static Contact getContact(Lead l){
        Contact c;
        map<String, Id> rtMap = new map<String, Id>();
        list<RecordType> rtList = [SELECT Id, Name, sObjectType FROM RecordType WHERE Name IN ( :rt_Familienangehoerige, :rt_Standard) and sObjectType = 'Contact'];     
        for(RecordType rt : rtList){
            rtMap.put(rt.Name, rt.Id);
        }
        if(!rtList.isEmpty()){
            List<Contact> contactList = [select id, 
                                                Name, 
                                                firstname, 
                                                lastname, 
                                                Email, 
                                                Phone, 
                                                RecordTypeId, 
                                                MobilePhone, 
                                                CreatedById, 
                                                AccountId, 
                                                Art_des_Kontakts__c,
                                                Familien_Zugeh_rigkeit__c, 
                                                von__c, 
                                                MailingStreet, 
                                                MailingCity, 
                                                MailingPostalCode
                                       from  Contact 
                                       where (Email = null or Email =: l.Email) and   
                                             firstname != null and
                                             firstname =: l.firstname and
                                             lastname != null and
                                             lastname =: l.lastname and   
                                             RecordTypeId in :rtMap.values()];
            if(contactList!= null){
                Integer listSize = contactList.size();
                if(listSize == 0){
                    c = null;
                }else if(listSize == 1){
                    c = contactList[0];
                }else{ // more than one contact is found
                    Integer i = 0;
                    while (i < contactList.size()){
                      if(contactList.size()>1 && contactList[i].AccountId == null){
                          contactList.remove(i);
                      }else{
                          i++;
                      }
                    }
                    i = 0;
                    while (i < contactList.size()){
                      if(contactList.size()>1 && contactList[i].RecordTypeId != rtMap.get(rt_Familienangehoerige)){
                          contactList.remove(i);
                      }else{
                          i++;
                      }
                    }
                    c = contactList[0];
                }
            }
        
            if(c == null){
                c = new Contact(Salutation = l.Salutation,
                                firstname = l.firstname,
                                lastname = l.lastname,
                                Email = l.Email,
                                MailingCity = l.City,
                                MailingPostalCode = l.PostalCode,
                                MailingStreet = l.Street,
                                RecordTypeId = rtMap.get(rt_Familienangehoerige));
                if(l.pflegegrad__c != null) c.Pflegegrad__c = l.pflegegrad__c; 
                if(l.Pflegestufe__c != null) c.Pflegestufe__c = l.Pflegestufe__c;   
            }else{
                c.RecordTypeId = rtMap.get(rt_Familienangehoerige);
                if(String.isEmpty(c.Email)) c.Email = l.Email;
                if(String.isEmpty(c.MailingStreet) && !String.isEmpty(l.Street)) c.Email = l.Street;
                if(String.isEmpty(c.MailingCity) && !String.isEmpty(l.City)) c.MailingCity = l.City;
                if(String.isEmpty(c.MailingPostalCode) && !String.isEmpty(l.postalcode)) c.MailingPostalCode = l.Email;
                if(c.Pflegegrad__c == null && l.pflegegrad__c != null) c.Pflegegrad__c = l.pflegegrad__c; 
                if(c.Pflegestufe__c == null && l.Pflegestufe__c != null) c.Pflegestufe__c = l.Pflegestufe__c;
            }
        }
        
        return c;
    }
    
    private static Account getAccount(Lead l){
        Account a;
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE Name =: rt_Familien and sObjectType = 'Account' limit 1];
        list<RecordType> rtListContact = [SELECT Id, Name, sObjectType FROM RecordType WHERE Name =: rt_Familienangehoerige and sObjectType = 'Contact' limit 1];     
        
        if(!rtList.isEmpty()) {
            if(!rtListContact.isEmpty()) {
                List<Contact> contactsWithSameEmail = [select Id, 
                                                             Email, 
                                                             RecordTypeId, 
                                                             AccountId,
                                                             Account.Familien_Name__c,
                                                             Account.BillingCity
                                                       from  Contact
                                                       where Email != null and 
                                                             Email =: l.Email and
                                                             AccountId != null and 
                                                             Account.Familien_Name__c =: l.lastname and
                                                             RecordTypeId =: rtListContact[0].Id and
                                                             Account.RecordTypeId =: rtList[0].Id ];
                if(!contactsWithSameEmail.isEmpty()){
                    if(contactsWithSameEmail.size() > 1){
                        Integer i = 0;
                        while (i < contactsWithSameEmail.size()){
                          if(contactsWithSameEmail.size()>1 && contactsWithSameEmail[i].Account.BillingCity != l.City){
                              contactsWithSameEmail.remove(i);
                          }else{
                              i++;
                          }
                        }
                    }
                    a = [select Id, Name, Familien_Name__c, BillingCity from Account where Id =: contactsWithSameEmail[0].AccountId limit 1];
                }
            }
            if(a == null){
                a = new Account(Name = l.lastname,
                                Familien_Name__c = l.lastname,
                                BillingCity = l.City,
                                RecordTypeId = rtList[0].Id );
            }
        }
        return a;
    }
    
    
    private static List<Opportunity> getOpportunity(Id leadId, Id accountId){
    
        List<Opportunity> oList = new List<Opportunity>();
        
        try{
            Lead l = [select Id,
                        RecordTypeId,
                        TL_Treppenliftart__c,
                        TL_Postleitzahl_f_r_Suche__c,
                        Partner__c,
                        OM_Referrer__c,
                        OM_Tracking_Order_ID__c,
                        OM_Wizard_Version__c,
                        OM_Partner_ID__c,
                        R_ckrufm_glichkeit__c,
                        Umgebung__c,
                        TL_Zu_berwindendes_Hindernis__c,
                        TL_H_usliche_Situation__c,
                        TL_Belastbarkeit__c,
                        emergency_contact__c,
                        Zeitpunkt_der_Versorgung__c,
                        Unterbringungsm_glichkeit__c,
                        Aktuelle_Betreuung__c,
                        H_ufigkeit_der_Unterst_tzung__c,
                        financing_model__c,
                        location_direction__c,
                        own_use__c,
                        TL_Anzahl_der_Etagen__c,
                        Person_des_Bedarfs__c,
                        pflegegrad__c,
                        Wohnort_der_suche__c,
                        next_step__c,
                        OM_Wizzard_Name2__c,
                        alleine_au_er_Haus__c,
                        in_letzter_Zeit_gest_rzt__c,
                        koerperlicher_Zustand__c,
                        Soforthilfe_vor_Ort__c,
                        OM_Referenznummer__c,
                        createdDate,
                        OM_UserID__c,
                        Marketing_Cloud_ID__c,
                        GCLID__c,
                        Preferred_timeframe__c
                    from Lead where Id =: leadId limit 1];
                    
            list<RecordType> rtList;
            list<RecordType> rtListLead = [SELECT Id, SobjectType, Name FROM RecordType WHERE Id =: l.RecordTypeId];
            if(!rtListLead.isEmpty()){
                rtList = [SELECT Id, SobjectType, Name FROM RecordType WHERE Name =: rtListLead[0].Name and SobjectType = 'Opportunity'];
                if(!rtList.isEmpty()){
                    Opportunity o = new Opportunity(Name = 'tempName', 
                                                    StageName = 'Offen', 
                                                    RecordTypeId = rtList[0].Id); 
                                              
                    o.RO_alleine_au_er_Haus__c = l.alleine_au_er_Haus__c;
                    o.RO_Person_des_Bedarfs__c = l.Person_des_Bedarfs__c;
                    o.RO_in_letzter_Zeit_gest_rzt__c = l.in_letzter_Zeit_gest_rzt__c;
                    o.RO_koerperlicher_Zustand__c = l.koerperlicher_Zustand__c;
                    o.RO_emergency_contact__c = l.emergency_contact__c;
                    o.RO_Pflegegrad_vorhanden__c = l.pflegegrad__c;
                    o.RO_Produkt_Kategorie__c = l.TL_Treppenliftart__c;
                    o.RO_Soforthilfe_vor_Ort__c = l.Soforthilfe_vor_Ort__c;
                    o.RO_Zeitpunkt_der_Versorgung__c = l.Zeitpunkt_der_Versorgung__c;
                    
                    o.alleine_au_er_Haus__c = l.alleine_au_er_Haus__c; 
                    o.in_letzter_Zeit_gest_rzt__c = l.in_letzter_Zeit_gest_rzt__c;
                    o.koerperlicher_Zustand__c = l.koerperlicher_Zustand__c;
                    o.Soforthilfe_vor_Ort__c = l.Soforthilfe_vor_Ort__c;
                    o.Produkt_Kategorie__c = l.TL_Treppenliftart__c;
                    o.Kategorie__c = '1';
                    o.Alternative_Postleitzahl__c = l.TL_Postleitzahl_f_r_Suche__c;
                    o.Partner__c = l.Partner__c;
                    o.OM_Referrer__c = l.OM_Referrer__c;
                    o.OM_Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c;
                    o.OM_Wizard_Version__c = l.OM_Wizard_Version__c;
                    o.OM_Partner_ID__c = l.OM_Partner_ID__c;
                    o.OM_Referenznummer__c = l.OM_Referenznummer__c;
                    o.Bezugspunkt_der_PLZ_Suche__c = 'Angefragte Postleitzahl';
                    o.CloseDate = date.today();
                    o.R_ckrufm_glichkeit__c = l.R_ckrufm_glichkeit__c;
                    o.Umgebung__c = l.Umgebung__c;
                    o.Treppenbauart__c = l.TL_Zu_berwindendes_Hindernis__c;
                    o.Art_des_Geb_udes__c = l.TL_H_usliche_Situation__c;
                    o.Belastbarkeit__c = l.TL_Belastbarkeit__c;
                    o.emergency_contact__c = l.emergency_contact__c;
                    o.Zeitpunkt_der_Versorgung__c = l.Zeitpunkt_der_Versorgung__c;
                    o.Unterbringungsm_glichkeit__c = l.Unterbringungsm_glichkeit__c;
                    o.Aktuelle_Betreuung__c = l.Aktuelle_Betreuung__c;
                    o.H_ufigkeit__c = l.H_ufigkeit_der_Unterst_tzung__c;
                    o.financing_model__c = l.financing_model__c;
                    o.location_direction__c = l.location_direction__c;
                    o.own_use__c = l.own_use__c;
                    o.Date_of_Request__c = l.createdDate;
                    o.Automatically_Converted__c = true;
                    
                    o.GCLID__c = l.GCLID__c;
                    o.Preferred_timeframe__c = l.Preferred_timeframe__c;
                    
                    if(l.TL_Anzahl_der_Etagen__c != null){
                        if(l.TL_Anzahl_der_Etagen__c == '1 Etage') {
                              o.Anzahl_der_Etagen__c = 1;
                        }
                        else if(l.TL_Anzahl_der_Etagen__c == '2 Etagen'){
                              o.Anzahl_der_Etagen__c = 2;
                        }
                        else if(l.TL_Anzahl_der_Etagen__c == '3 Etagen o. mehr'){
                              o.Anzahl_der_Etagen__c = 3;
                        }
                    }
                    if(l.Person_des_Bedarfs__c != null) o.Person_des_Bedarfs__c = l.Person_des_Bedarfs__c;                                            
                    
                    if(l.pflegegrad__c != null){
                        set<String> pgSet = new set<string>{'1','2','3','4','5'};
                        if(!pgSet.contains(l.pflegegrad__c)) {
                            o.Pflegegrad_vorhanden__c = l.pflegegrad__c;
                        }
                    } 
                    
                    if(l.Wohnort_der_suche__c != null) o.Angefragter_Wohnort__c = l.Wohnort_der_suche__c;
                    
                    if(l.next_step__c == 'Anrufen für Direktvertrieb' || l.next_step__c == 'Weiterleitung') {
                        o.N_chster_Schritt__c = l.next_step__c;
                    }                  
                    
                    o.CampaignId = l.OM_Wizzard_Name2__c;
                    o.Urspr_nglicher_Lead__c = l.Id;   
                    
                    if(rtList[0].Name == 'Pflegeimmobilien' || rtList[0].Name == 'Widerspruch'){
                        o.Produkt_Kategorie__c = rtList[0].Name;
                    }                  
                    
                    if(accountId != null){
                        o.AccountId = accountId;
                        List<Opportunity> oppList = [select id, 
                                                        AccountId, 
                                                        Name, 
                                                        Produkt_Kategorie__c, 
                                                        RecordTypeId, 
                                                        StageName, 
                                                        OM_Tracking_Order_ID__c,
                                                        OM_Wizard_Version__c,
                                                        OM_Referenznummer__c
                                                     from Opportunity 
                                                     where AccountId =: accountId and 
                                                         RecordTypeId =: rtList[0].Id];
                        if(!oppList.isEmpty()){
                            /*
                            if(l.OM_Tracking_Order_ID__c != null){
                                for(Opportunity opp : oppList){
                                    if(opp.OM_Tracking_Order_ID__c == null){
                                        opp.OM_Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c;
                                    }
                                    else{
                                        opp.OM_Tracking_Order_ID__c = opp.OM_Tracking_Order_ID__c + ', ' + l.OM_Tracking_Order_ID__c;
                                    }
                                    oList.add(opp);
                                }
                            }*/
                            o.OM_Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c;
                            o.StageName = 'Abbruch';
                            o.Abbruchgrund__c = 'Auschuss';
                        }
                    }
                    oList.add(o);
                }
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            throw new applicationException (e.getMessage());
        }
        return oList;                     
    }
    
    public class applicationException extends Exception{}


}