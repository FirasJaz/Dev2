/****************************************************************************************************************************
// Erstellt 23.08.2016 von AM
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
// controller für Familiendaten aus CRM
//
//
//****************************************************************************************************************************
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@RestResource(urlMapping='/familiendaten/*')
global class ksgFamiliendatenController {

    @HttpPost 
    global static string familiendatenEmpfang( string request_id,
                                        string request_datetime,
                                        familie familie,
                                        kontakte[] kontakte,
                                        tickets[] tickets) {
                                        
        id rtid = null;   
        id rttId = null; // Task record type 
        id ownid = UserInfo.getUserId(); 
        id faid = null;
        id ctrtid = null;
        string fam_id = null;
        string fam_name = null;
        string errorMessage = '';
        list<RecordType> rtList;
        

        rtList = [SELECT Id FROM RecordType WHERE sObjectType='contact' AND Name= 'Familienangehörige'];
        if((rtList != null) && (rtList.size() > 0)) {
            ctrtId = rtList[0].id;
        } 
        list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
        if((usList != null) && (usList.size() > 0)) {
            ownid = usList[0].id;
        }       
        
        
        
        if(familie != null) {
            Savepoint sp = Database.setSavepoint();  
            try { 
                fam_id = familie.familie_id; 
                fam_name = familie.familie_name;
                list<account> faList = [SELECT id, Familien_Name__c FROM account WHERE Familien_CRM_ID__c = :fam_id LIMIT 1];
                if((faList != null) && (faList.size() > 0)) {
                    faid = faList[0].id;
                }
                if(faid == null) {
                    rtList = [SELECT Id FROM RecordType WHERE sObjectType='account' AND Name= 'Pflege.de - Familien'];
                    if((rtList != null) && (rtList.size() > 0)) {
                        rtId = rtList[0].id;
                    } 
                    account fam = new account(Name=fam_name, Familien_Name__c=fam_name, ownerID=ownid, RecordTypeId=rtId, Familien_CRM_ID__c=fam_id);
                    try {
                        insert fam;
                        faid = fam.id;
                    }
                    catch (System.Exception e) {
                        system.debug('##########alex001 e=' + e);
                        return 'Fehler beim insert Familie. userid='+ string.valueOf(UserInfo.getUserId()) + ' tr=' + string.valueOf(rtId) + ' e=' + string.valueOf(e);                     
                    }
                }
                else {
                    account faupd = faList[0];
                    faupd.Familien_Name__c=fam_name;
                    try {
                        update faupd;
                    }
                    catch (System.Exception e) {
                        system.debug('##########alex001 e=' + e);
                        return 'Fehler beim update Familie. e=' + string.valueOf(e);    
                        
                    }                   
                }
                                
            }
            catch (System.Exception e) {
                system.debug('##########alex002 e=' + e);
                return 'familie_id kann nicht gelesen werden '  + string.valueOf(e);     
            }
            
            if(faid != null) {
            
                if(kontakte != null ) {
                    
                    map<string, contact> ctMap = new map<string, contact>();
                    try {
                        set<string> kont_idSet = new set<string>();
                        for(integer i = 0; i < kontakte.size(); i++) {
                            kont_idSet.add(kontakte[i].kontakt_id);
                        }
                        if(!kont_idSet.isEmpty()) {
                            list<contact> ctList = [SELECT firstname, lastname, salutation, title, 
                                                        mailingstreet, mailingpostalcode, MailingCity, 
                                                        email, Phone, Fax, Birthdate, Art_des_Kontakts__c,
                                                        Sonstige_Krankheiten__c, DoNotCall, Description,
                                                        Kontakt_ID__c, Pflegestufe__c
                                                    FROM contact
                                                    WHERE Kontakt_ID__c IN :kont_idSet];
                            if((ctList != null) && (ctList.size() > 0)) {
                                for(contact ct : ctList) ctMap.put(ct.Kontakt_ID__c, ct);
                            }
                            // jetzt abarbeiten
                            list<contact> ctToUpd = new list<contact>();
                            list<contact> ctToIns = new list<contact>();
                            for(integer i = 0; i < kontakte.size(); i++) {
                                string krankheiten = null;
                                decimal geburtsjahr = null;
                                date gebdate = gebDatum(kontakte[i].kontakt_geburtsdatum);
                                
                                if(kontakte[i].krankheiten != null) krankheiten = kontakte[i].krankheiten.replace(',', ';');
                                if(kontakte[i].geburtsjahr != null) {
                                    try {
                                        geburtsjahr = decimal.valueOf(kontakte[i].geburtsjahr);
                                    }
                                    catch(System.Exception e) {
                                        // if(gebdate != null) geburtsjahr = gebdate.year();
                                    }
                                }
                                if(ctMap.containsKey(kontakte[i].kontakt_id)) {
                                    contact ctu = ctMap.get(kontakte[i].kontakt_id);
                                    ctu.AccountId=faid;
                                    ctu.Familien_Zugeh_rigkeit__c = kontakte[i].kontakt_info;
                                    ctu.firstname = kontakte[i].kontakt_vorname;
                                    ctu.lastname = kontakte[i].kontakt_nachname;
                                    ctu.salutation = kontakte[i].kontakt_anrede;
                                    ctu.title = kontakte[i].kontakt_titel;
                                    ctu.mailingstreet = kontakte[i].kontakt_strasse + ' ' +kontakte[i].kontakt_hausnummer ;
                                    ctu.mailingpostalcode = kontakte[i].kontakt_plz;
                                    ctu.MailingCity = kontakte[i].kontakt_ort;
                                    try {ctu.email = kontakte[i].kontakt_email;} catch (System.Exception e) {}
                                    ctu.Phone = kontakte[i].kontakt_telefon;
                                    ctu.Fax = kontakte[i].kontakt_fax;
                                    ctu.Birthdate = gebdate;
                                    ctu.Geburtsjahr__c = geburtsjahr;
                                    ctu.Art_des_Kontakts__c = kontakte[i].art_des_kontakts;
                                    ctu.Sonstige_Krankheiten__c = kontakte[i].sonstige_krankheiten;
                                    if((kontakte[i].kontakt_verboten == '1') || (kontakte[i].kontakt_verboten == 'true'))  {
                                        ctu.DoNotCall = true;
                                    }
                                    else ctu.DoNotCall = false;
                                    ctu.Description = kontakte[i].beschreibung;
                                    ctu.Pflegestufe__c = kontakte[i].pflegestufe;
                                    ctu.Bekannte_Krankheiten__c = krankheiten; 
                                    ctu.Pflegestufe_beantragt__c = kontakte[i].pflegestufe_beantragt;
                                    ctu.Geburtsjahr__c = geburtsjahr;
                                    ctToUpd.add(ctu);
                                    
                                }
                                else {
                                    contact cti = new contact(AccountId=faid, ownerID=ownid, RecordTypeId=ctrtId);
                                    cti.Kontakt_ID__c = kontakte[i].kontakt_id;
                                    cti.Familien_Zugeh_rigkeit__c = kontakte[i].kontakt_info;
                                    cti.firstname = kontakte[i].kontakt_vorname;
                                    cti.lastname = kontakte[i].kontakt_nachname;
                                    cti.salutation = kontakte[i].kontakt_anrede;
                                    cti.title = kontakte[i].kontakt_titel;
                                    cti.mailingstreet = kontakte[i].kontakt_strasse + ' ' +kontakte[i].kontakt_hausnummer ;
                                    cti.mailingpostalcode = kontakte[i].kontakt_plz;
                                    cti.MailingCity = kontakte[i].kontakt_ort;
                                    try {cti.email = kontakte[i].kontakt_email;} catch (System.Exception e) {}
                                    cti.Phone = kontakte[i].kontakt_telefon;
                                    cti.Fax = kontakte[i].kontakt_fax;
                                    cti.Birthdate = gebdate;
                                    cti.Geburtsjahr__c = geburtsjahr;
                                    cti.Art_des_Kontakts__c = kontakte[i].art_des_kontakts;
                                    cti.Sonstige_Krankheiten__c = kontakte[i].sonstige_krankheiten;
                                    if((kontakte[i].kontakt_verboten == '1') || (kontakte[i].kontakt_verboten == 'true'))  {
                                        cti.DoNotCall = true;
                                    }
                                    else cti.DoNotCall = false;
                                    cti.Description = kontakte[i].beschreibung;
                                    cti.Pflegestufe__c = kontakte[i].pflegestufe;       
                                    cti.Bekannte_Krankheiten__c = krankheiten;  
                                    cti.Pflegestufe_beantragt__c = kontakte[i].pflegestufe_beantragt;   
                                    cti.Geburtsjahr__c = geburtsjahr;                                   
                                    ctToIns.add(cti);
                                }
                            }
                            if(!ctToIns.isEmpty()) {
                                try {
                                    insert ctToIns;
                                }
                                catch (System.Exception e) {
                                    system.debug('##########alex003 e=' + e);
                                    Database.rollback(sp);  
                                    return 'Fehler beim insert kontakt '  + string.valueOf(e);   
                                }   
                            }
                            if(!ctToUpd.isEmpty()) {
                                try {
                                    update ctToUpd;
                                }
                                catch (System.Exception e) {
                                    system.debug('##########alex004 e=' + e);
                                    Database.rollback(sp);  
                                    return 'Fehler beim update kontakt ' + string.valueOf(e);   
                                }   
                            }                           
                            
                        }                   
                    }
                    catch (System.Exception e) {
                        system.debug('##########alex005 e=' + e);
                        Database.rollback(sp);  
                        return 'kontakte koennen nicht gelesen werden'; 
                    }               
                }
                else {
                    Database.rollback(sp);  
                    return 'kontakte kann nicht gelesen werden'; 
                }
                if(tickets != null) {
                    map<string, task> updMap = new map<string, task>();
                    rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name= 'Fam-Ticket'];
                    if((rtList != null) && (rtList.size() > 0)) {
                        rttId = rtList[0].id;
                    }                   
                    list<task> taToIns = new list<task>();
                    list<task> taToUpd = new list<task>();
                    try {
                        set<string> tickIdSet = new set<string>();
                        for(integer i = 0; i < tickets.size(); i++) {                           
                            tickIdSet.add(tickets[i].ticket_id);
                        }   
                        if(!tickIdSet.isEmpty()) {
                            taToUpd = [SELECT id, Ticket_ID__c, Ticket_Erstelldatum__c, Ticket_Nummer__c, Ticket_Typ__c, Ticket_URL__c
                                            FROM task 
                                            WHERE Ticket_ID__c IN :tickIdSet];
                            if((taToUpd != null) && (taToUpd.size() > 0)) {
                                for(task ts : taToUpd) updMap.put(ts.Ticket_ID__c, ts);
                            }                           
                        }
                        for(integer i = 0; i < tickets.size(); i++) {   
                            string tckId = tickets[i].ticket_id;
                            if(updMap.containsKey(tckId)) {
                                task uts = updMap.get(tckId);
                                uts.Ticket_Erstelldatum__c = tickets[i].angelegt;
                                uts.Ticket_Nummer__c = tickets[i].ticket_no;
                                uts.Ticket_Typ__c = tickets[i].ticket_typ;
                                uts.Ticket_URL__c = tickets[i].url;
                                updMap.put(tckId, uts);
                            }
                            else {
                                task its = new task(RecordTypeId = rttId, WhatId=faid, Status='Geschlossen');
                                its.Ticket_ID__c = tickets[i].ticket_id;
                                its.Ticket_Erstelldatum__c = tickets[i].angelegt;
                                its.Ticket_Nummer__c = tickets[i].ticket_no;
                                its.Ticket_Typ__c = tickets[i].ticket_typ;
                                its.Ticket_URL__c = tickets[i].url;     
                                its.Subject = 'Vorhandene CRM-Tickets: ' + its.Ticket_Typ__c + ' ' + its.Ticket_ID__c;
                                taToIns.add(its);
                            }
                        }
                        if(!taToIns.isEmpty()) {
                            insert taToIns;
                        }
                        if(!taToIns.isEmpty()) {
                            update taToUpd;
                        }
                        
                    }
                    catch (System.Exception e) {
                        return 'INFO. Fehler beim Bearbeiten tickets';  
                    }
                    
                }
            
            }
            
        }
        else {
            return 'familie kann nicht gelesen werden'; 
        }
        return 'OK';
    }

    global static date gebDatum(string gdat) {
        try {
            integer jahr = integer.valueOf(gdat.substring(0, 4));
            integer monat = integer.valueOf(gdat.substring(4, 6));
            integer tag = integer.valueOf(gdat.substring(6));
            date gebdat = Date.newInstance(jahr, monat, tag);
            return gebdat;
        }
        catch(System.Exception e) {
            return null;
        }
        
        
        
    }
    
    global class kontakte {
        global String kontakt_no {get;set;} 
        global String kontakt_id {get;set;} 
        global String kontakt_info {get;set;} 
        global String kontakt_anrede {get;set;} 
        global String kontakt_vorname {get;set;} 
        global String kontakt_nachname {get;set;} 
        global String kontakt_titel {get;set;} 
        global String kontakt_strasse {get;set;} 
        global String kontakt_hausnummer {get;set;} 
        global String kontakt_plz {get;set;} 
        global String kontakt_ort {get;set;} 
        global String kontakt_email {get;set;} 
        global String kontakt_telefon {get;set;} 
        global String kontakt_fax {get;set;} 
        global String geburtsjahr {get;set;}
        global String kontakt_geburtsdatum {get;set;} 
        global String art_des_kontakts {get;set;} 
        global String beschreibung {get;set;} 
        global String krankheiten {get;set;} 
        global String sonstige_krankheiten {get;set;} 
        global String pflegestufe {get;set;} 
        global String pflegestufe_beantragt {get;set;}  
        global String kontakt_verboten {get;set;}       
    }

    global class familie {
        global string familie_id {get; set;}
        global string familie_name {get; set;}
    }
    
    global class tickets {
        global string ticket_no {get; set;}
        global string ticket_id {get; set;}
        global string ticket_typ {get; set;}
        global string angelegt {get; set;}
        global string url {get; set;}
    }

}