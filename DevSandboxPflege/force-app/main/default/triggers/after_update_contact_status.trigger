//****************************************************************************************************************************
// Created on 02.08.2019   by BT
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// None
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//             after update trigger on contact_status__c object
//
//
//****************************************************************************************************************************
//Änderungen:
//30.11.20    DZ Prozesse der Kündigungsbemerkungen deaktiviert   
//****************************************************************************************************************************
trigger after_update_contact_status on Contact_Status__c (after update) {
    set<id> kdAbgSet = new set<id>();
    set<id> kdSet = new set<id>();
    set<id> kd51Set = new set<id>();
    set<id> kd54Set = new set<id>();
    set<id> kdk54Set = new set<id>();
    set<id> kdk51Set = new set<id>();
    set<id> kSet = new set<id>();
    set<id> KPkdSet = new set<id>();
    set<id> KPPkdSet = new Set<id>();
    set<id> ALkdSet = new Set<id>();
    List<Contact_Status__c> kds51list = new List<Contact_Status__c>();
    List<Contact_Status__c> kds54list = new List<Contact_Status__c>();
    map<id, Contact_Status__c> kds51map = new map<id, Contact_Status__c>();
    map<id, Contact_Status__c> kds54map = new map<id, Contact_Status__c>();   
    map<id, Contact_Status__c> allkds51map = new map<id, Contact_Status__c>();
    map<id, Contact_Status__c> allkds54map = new map<id, Contact_Status__c>();    
    map<id, Contact_Status__c> kdLS51map = new map<id, Contact_Status__c>();
    map<id, Contact_Status__c> kdLS54map = new map<id, Contact_Status__c>();
    map<id, string> kdtknameMap = new map<id, string>();    
    
    for (Contact_Status__c KS : Trigger.new) {

//DZ 30.11.20 
//       if ((KS.status__c == 'Kunde' && trigger.OldMap.get(KS.id).status__c != 'Kunde')
//            || (KS.status__c == 'Kündigung' && trigger.OldMap.get(KS.id).status__c != 'Kündigung')) {        
//                if(KS.Productgroup__c == 'PG54') kdLS54map.put(KS.Contact__c, KS);
//                if(KS.Productgroup__c == 'PG51') kdLS51map.put(KS.Contact__c, KS);      
//                
//                if(KS.status__c == 'Kündigung' && trigger.OldMap.get(KS.id).status__c != 'Kündigung' 
//                        && KS.K_ndigungsgrund__c == 'Ablehnung durch Pflegekasse') {                
//                    
//                    if(KS.K_ndigungsbemerkung__c == 'Keine Pflegestufe vorhanden') {
//                          Mailversand_class.sendMail(KS.Contact__c, 'Curabox_Ablehnung_kein_Pflegegrad');
//                          if(Mailversand_class.error == false) {
//                              Follow_up_Task_erstellen_class.createFollowUpTask(new set<id>{KS.Contact__c}, 'Ablehnung durch Pflegekasse');
//                          }
//                    } 
//                     
//                    if(KS.K_ndigungsbemerkung__c == 'Keine private Pflegeperson vorhanden') {
//                          Mailversand_class.sendMail(KS.Contact__c, 'Curabox_Ablehnung_keine_Pflegeperson');
//                          if(Mailversand_class.error == false) {
//                              Follow_up_Task_erstellen_class.createFollowUpTask(new set<id>{KS.Contact__c}, 'Ablehnung keine Pflegeperson');         
//                          }        
//                    }
//                     
//                    if(KS.K_ndigungsbemerkung__c == 'Anderer Leistungserbringer') {
//                         Mailversand_class.sendMail(KS.Contact__c, 'Curabox_Ablehnung_anderer_LE');
//                         if(Mailversand_class.error == false) {
//                             Follow_up_Task_erstellen_class.createFollowUpTask(new set<id>{KS.Contact__c}, 'Ablehnung anderer LE');         
//                         }
//                    }
//                }    
//        }
        
        if ((KS.status__c == 'Vorgang geschlossen' && trigger.OldMap.get(KS.id).status__c != 'Vorgang geschlossen')
            || (KS.status__c == 'Kündigung' && trigger.OldMap.get(KS.id).status__c != 'Kündigung'))
            {
                kdAbgSet.add(KS.Contact__c);
        }                         
                                
        if ((KS.status__c == 'Vorgang geschlossen' && trigger.OldMap.get(KS.id).status__c != 'Vorgang geschlossen')
            || (KS.status__c == 'Kündigung' && trigger.OldMap.get(KS.id).status__c != 'Kündigung')
            || (KS.status__c == 'Kunde' && trigger.OldMap.get(KS.id).status__c != 'Kunde')) {                                     
            if(KS.Productgroup__c == 'PG54') {
                kds54map.put(KS.Contact__c, KS);
                kd51Set.add(KS.Contact__c);
            }
            
            if(KS.Productgroup__c == 'PG51') {
                kds51map.put(KS.Contact__c, KS);
                kd54Set.add(KS.Contact__c); 
            }
        }              
    }              
    
    kds51list = [select id, Productgroup__c, Contact__c, Status__c from Contact_Status__c
                            where Productgroup__c = 'PG51'
                            and Contact__c IN: kd51Set];
    
    if(kds51list != null && kds51list.size() != 0) {
        for(Contact_Status__c ks51: kds51list){
            allkds51map.put(ks51.Contact__c, ks51);
        }     
    }
                       
    kds54list = [select id, Productgroup__c, Contact__c, Status__c from Contact_Status__c
                            where Productgroup__c = 'PG54'
                            and Contact__c IN: kd54Set];
                            
    if(kds54list != null && kds54list.size() != 0) {
        for(Contact_Status__c ks54: kds54list){
            allkds54map.put(ks54.Contact__c, ks54);
        }     
    }                                                        
    
    system.debug('#########BT2016 map.size(): ' + allkds51map.size());
    
    if(!kds54map.isEmpty()) {
        for(id kdid: kds54map.keySet()) {
            if(allkds51map.get(kdid) == null) {
                 kdSet.add(kdid);
            }
            else if(allkds51map.get(kdid).Status__c == 'Kunde' 
                       || allkds51map.get(kdid).Status__c == 'Kündigung'
                       || allkds51map.get(kdid).Status__c == 'Vorgang geschlossen') {
                kdSet.add(kdid);
            }            
        }                                                       
    }
    
    if(!kds51map.isEmpty()) {
        for(id kid: kds51map.keySet()) {
            if(allkds54map.get(kid) == null) {
                 kdSet.add(kid);
            }            
            else if(allkds54map.get(kid).Status__c == 'Kunde' 
                       || allkds54map.get(kid).Status__c == 'Kündigung'
                       || allkds54map.get(kid).Status__c == 'Vorgang geschlossen') {
                 kdSet.add(kid);
            }
        }                                                       
    }
    
    if(!kdLS54map.isEmpty()) {
        List<Delivery_Line__c> LPlist = [SELECT id, Contact__c, Abrechnungsstatus_Krankenkasse__c,
                                                        Delivery_Note__r.Delivery_Note_text__c
                                                    FROM Delivery_Line__c
                                                    WHERE Contact__c IN : kdLS54map.keySet() 
                                                    AND Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'
                                                    AND Delivery_Note__r.Delivery_Note_text__c = '54'];
                                              
        if((LPList != null) && (LPList.size() > 0)) {
            for(Delivery_Line__c LP : LPList) {
                If (kdLS54map.get(LP.Contact__c).status__c == 'Kunde'){
                    LP.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
                }
                else {
                    if (kdLS54map.get(LP.Contact__c).status__c == 'Kündigung' && kdLS54map.get(LP.Contact__c).K_ndigungsgrund__c == 'Ablehnung durch Pflegekasse') {
                        LP.Abrechnungsstatus_Krankenkasse__c = 'Nachträgliche Ablehnung';
                    } 
                }    
            }
            try {
                update LPList;
            }
            catch(system.exception e) {
                system.debug('######################### error update LP' + e);
            }    
        }       
    }
    
    if(!kdLS51map.isEmpty()) {
        List<Delivery_Line__c> LPlist = [SELECT id, Contact__c, Abrechnungsstatus_Krankenkasse__c,
                                                        Delivery_Note__r.Delivery_Note_text__c
                                                    FROM Delivery_Line__c
                                                    WHERE Contact__c IN : kdLS51map.keySet() 
                                                    AND Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'
                                                    AND Delivery_Note__r.Delivery_Note_text__c = '51'];
                                              
        if((LPList != null) && (LPList.size() > 0)) {
            for(Delivery_Line__c LP : LPList) {
                If (kdLS51map.get(LP.Contact__c).status__c == 'Kunde'){
                    LP.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
                }
                else {
                    if (kdLS51map.get(LP.Contact__c).status__c == 'Kündigung' && kdLS51map.get(LP.Contact__c).K_ndigungsgrund__c == 'Ablehnung durch Pflegekasse') {
                        LP.Abrechnungsstatus_Krankenkasse__c = 'Nachträgliche Ablehnung';
                    } 
                }    
            }
            try {
                update LPList;
            }
            catch(system.exception e) {
                system.debug('######################### error update LP' + e);
            }    
        }       
    }    
    
    if(!kdAbgSet.isEmpty()) {
            list<Follow_up_Task__c> tsList = [SELECT id, Status__c 
                            FROM Follow_up_Task__c 
                            WHERE Subject__c = 'Nachtelefonie von Interessenten'
                            AND Status__c != 'Geschlossen' 
                            AND Contact__c IN :kdAbgSet];
            if((tsList != null) && (tsList.size() > 0)) {
                for(Follow_up_Task__c ts : tsList) {
                    ts.Status__c = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            } 
    }
    
    if(!kdSet.isEmpty()) {
            list<task> tsList = [SELECT id, Status 
                            FROM task 
                            WHERE Subject = 'Nachfassen bei PK wg. offener KÜ'
                            AND isClosed = false 
                            AND WhatId IN :kdSet];
            if((tsList != null) && (tsList.size() > 0)) {
                for(task ts : tsList) {
                    ts.Status = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            } 
    } 
}