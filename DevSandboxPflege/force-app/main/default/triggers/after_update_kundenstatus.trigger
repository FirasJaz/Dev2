//****************************************************************************************************************************
// Erstellt dd.mm.yyyy     von xxx
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
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// xxxxxx
//
//
//****************************************************************************************************************************
//Änderungen:
//    12.04.2017 von BT Mailversand und Taskerstellung, wenn Kündigungsgrund == 'Ablehnung durch Pflegekasse'
//****************************************************************************************************************************
trigger after_update_kundenstatus on Kundenstatus__c (after update) {
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
    List<Kundenstatus__c> kds51list = new List<Kundenstatus__c>();
    List<Kundenstatus__c> kds54list = new List<Kundenstatus__c>();
    map<id, Kundenstatus__c> kds51map = new map<id, Kundenstatus__c>();
    map<id, Kundenstatus__c> kds54map = new map<id, Kundenstatus__c>();   
    map<id, Kundenstatus__c> allkds51map = new map<id, Kundenstatus__c>();
    map<id, Kundenstatus__c> allkds54map = new map<id, Kundenstatus__c>();    
    map<id, Kundenstatus__c> kdLS51map = new map<id, Kundenstatus__c>();
    map<id, Kundenstatus__c> kdLS54map = new map<id, Kundenstatus__c>();
    map<id, string> kdtknameMap = new map<id, string>();    
    
    for (Kundenstatus__c KS : Trigger.new) {

        if ((KS.status__c == 'Kunde' && trigger.OldMap.get(KS.id).status__c != 'Kunde')
            || (KS.status__c == 'Kündigung' && trigger.OldMap.get(KS.id).status__c != 'Kündigung')) {        
                if(KS.Produktgruppe__c == 'PG54') kdLS54map.put(KS.Kunde__c, KS);
                if(KS.Produktgruppe__c == 'PG51') kdLS51map.put(KS.Kunde__c, KS);      
                
                if(KS.status__c == 'Kündigung' && trigger.OldMap.get(KS.id).status__c != 'Kündigung' 
                        && KS.K_ndigungsgrund__c == 'Ablehnung durch Pflegekasse') {                
                    
                    if(KS.K_ndigungsbemerkung__c == 'Keine Pflegestufe vorhanden') {
                          Mail_versenden_class.sendMail(KS.Kunde__c, 'Curabox_Ablehnung_kein_Pflegegrad');
                          if(Mail_versenden_class.error == false) {
                              Task_erstellen_class.createTask(new set<id>{KS.Kunde__c}, 'Ablehnung durch Pflegekasse');
                          }
                    } 
                     
                    if(KS.K_ndigungsbemerkung__c == 'Keine private Pflegeperson vorhanden') {
                          Mail_versenden_class.sendMail(KS.Kunde__c, 'Curabox_Ablehnung_keine_Pflegeperson');
                          if(Mail_versenden_class.error == false) {
                              Task_erstellen_class.createTask(new set<id>{KS.Kunde__c}, 'Ablehnung keine Pflegeperson');         
                          }        
                    }
                     
                    if(KS.K_ndigungsbemerkung__c == 'Anderer Leistungserbringer') {
                         Mail_versenden_class.sendMail(KS.Kunde__c, 'Curabox_Ablehnung_anderer_LE');
                         if(Mail_versenden_class.error == false) {
                             Task_erstellen_class.createTask(new set<id>{KS.Kunde__c}, 'Ablehnung anderer LE');         
                         }
                    }
                }    
        }
        
        if ((KS.status__c == 'Vorgang geschlossen' && trigger.OldMap.get(KS.id).status__c != 'Vorgang geschlossen')
            || (KS.status__c == 'Kündigung' && trigger.OldMap.get(KS.id).status__c != 'Kündigung'))
            {
                kdAbgSet.add(KS.Kunde__c);
        }                         
                                
        if ((KS.status__c == 'Vorgang geschlossen' && trigger.OldMap.get(KS.id).status__c != 'Vorgang geschlossen')
            || (KS.status__c == 'Kündigung' && trigger.OldMap.get(KS.id).status__c != 'Kündigung')
            || (KS.status__c == 'Kunde' && trigger.OldMap.get(KS.id).status__c != 'Kunde')) {                                     
            if(KS.Produktgruppe__c == 'PG54') {
                kds54map.put(KS.Kunde__c, KS);
                kd51Set.add(KS.Kunde__c);
            }
            
            if(KS.Produktgruppe__c == 'PG51') {
                kds51map.put(KS.Kunde__c, KS);
                kd54Set.add(KS.Kunde__c); 
            }
        }              
    }              
    
    kds51list = [select id, Produktgruppe__c, Kunde__c, Status__c from Kundenstatus__c
                            where Produktgruppe__c = 'PG51'
                            and Kunde__c IN: kd51Set];
    
    if(kds51list != null && kds51list.size() != 0) {
        for(Kundenstatus__c ks51: kds51list){
            allkds51map.put(ks51.Kunde__c, ks51);
        }     
    }
                       
    kds54list = [select id, Produktgruppe__c, Kunde__c, Status__c from Kundenstatus__c
                            where Produktgruppe__c = 'PG54'
                            and Kunde__c IN: kd54Set];
                            
    if(kds54list != null && kds54list.size() != 0) {
        for(Kundenstatus__c ks54: kds54list){
            allkds54map.put(ks54.Kunde__c, ks54);
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
        List<Lieferscheinposition__c> LPlist = [SELECT id, Kunde__c, Unterschrift__c, 
                                                        Abrechnungsstatus_Krankenkasse__c,
                                                        Lieferschein__r.Lieferschein_text__c
                                                    FROM Lieferscheinposition__c
                                                    WHERE Kunde__c IN : kdLS54map.keySet() 
                                                    AND Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'
                                                    AND Lieferschein__r.Lieferschein_text__c = '54'
                                                    AND Unterschrift__c = true];
                                              
        if((LPList != null) && (LPList.size() > 0)) {
            for(Lieferscheinposition__c LP : LPList) {
                If (kdLS54map.get(LP.Kunde__c).status__c == 'Kunde'){
                    LP.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
                }
                else {
                    if (kdLS54map.get(LP.Kunde__c).status__c == 'Kündigung' && kdLS54map.get(LP.Kunde__c).K_ndigungsgrund__c == 'Ablehnung durch Pflegekasse') {
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
        List<Lieferscheinposition__c> LPlist = [SELECT id, Kunde__c, Unterschrift__c, 
                                                        Abrechnungsstatus_Krankenkasse__c,
                                                        Lieferschein__r.Lieferschein_text__c
                                                    FROM Lieferscheinposition__c
                                                    WHERE Kunde__c IN : kdLS51map.keySet() 
                                                    AND Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'
                                                    AND Lieferschein__r.Lieferschein_text__c = '51'
                                                    AND Unterschrift__c = true];
                                              
        if((LPList != null) && (LPList.size() > 0)) {
            for(Lieferscheinposition__c LP : LPList) {
                If (kdLS51map.get(LP.Kunde__c).status__c == 'Kunde'){
                    LP.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
                }
                else {
                    if (kdLS51map.get(LP.Kunde__c).status__c == 'Kündigung' && kdLS51map.get(LP.Kunde__c).K_ndigungsgrund__c == 'Ablehnung durch Pflegekasse') {
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
            list<task> tsList = [SELECT id, Status 
                            FROM task 
                            WHERE Subject = 'Nachtelefonie von Interessenten'
                            AND isClosed = false 
                            AND WhatId IN :kdAbgSet];
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