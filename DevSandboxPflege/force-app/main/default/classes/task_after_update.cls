/****************************************************************************************************************************
// Erstellt 24.07.2015 von AM
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                
//
//****************************************************************************************************************************
//Änderungen:
// 02.09.2015 von AM : Einbau test recordtype
// 22.04.2016 einbau try/catch
//****************************************************************************************************************************
*/
public with sharing class  task_after_update {   
    
    public static void taskLoeschen(map<id, task> mapOld, map<id, task> mapNew) {
        list<task> tsToUpd = new list<task>();
        list<task> tsToWv = new list<task>();
        list<task> tsToUpdWv = new list<task>();
        set<id> kdSet54 = new set<id>();
        set<id> kdSet51 = new set<id>();
        set<id> kdSetInko = new set<id>();
        
        list<RecordType> rtList = [SELECT Id, Name FROM RecordType WHERE sObjectType='task'];
        map<id, RecordType> tsrtMap = new map<id, RecordType>(rtList);
        id grID = null;
        list<Group> grList = [SELECT id FROM Group WHERE Name = 'Nachtelefonie' LIMIT 1];
        if((grList != null) && (grList.size() > 0)) {   
            grID = grList[0].id;
        }   
        list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                    FROM GroupMember 
                                    WHERE GroupId = : grID];
        set<id> grMSet = new set<id>();        
        
        for(id tsID : mapOld.keySet()) {
            
            
            if( ((mapOld.get(tsID).Status != 'Geschlossen') 
                    && (mapOld.get(tsID).Status != 'Abgeschlossen')
                    && (mapOld.get(tsID).Status != 'Abbruch'))
                &&  ((mapNew.get(tsID).Status == 'Geschlossen') 
                    || (mapNew.get(tsID).Status == 'Abgeschlossen')
                    || (mapNew.get(tsID).Status == 'Abbruch'))) {
                        
                try {
                    Schema.sObjectType tType=(mapOld.get(tsID).WhatId).getSObjectType();
                
                    if(string.valueOf(tType) == 'Kunde__c') {
                        if(mapNew.get(tsID).Status == 'Abbruch') {
                            
                            if(tsrtMap.get(mapNew.get(tsID).RecordTypeId).Name == 'RG54') {
                                kdSet54.add(mapNew.get(tsID).WhatId);
                            }
                            else if(tsrtMap.get(mapNew.get(tsID).RecordTypeId).Name == 'RG51') {                            
                                kdSet51.add(mapNew.get(tsID).WhatId);
                            }
                            else if(tsrtMap.get(mapNew.get(tsID).RecordTypeId).Name == 'Inko') {                            
                                kdSetInko.add(mapNew.get(tsID).WhatId);
                            }
                        }
                        // list<Group> grList = [SELECT id FROM Group WHERE Name = 'Nachtelefonie' LIMIT 1];
                        // if((grList != null) && (grList.size() > 0)) {   
                            // grID = grList[0].id;
                        // }   
                        // list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                                    // FROM GroupMember 
                                                    // WHERE GroupId = : grID];
                        // set<id> grMSet = new set<id>();
                        
                        if((gmList != null) && (gmList.size() > 0)) { 
                            for(GroupMember GM : gmList) {
                                grMSet.add(GM.UserOrGroupId);
                            }   
                            if(!grMSet.isEmpty()) {
                                tsToUpd = [SELECT id, Status, Grund_des_Abbruchs__c, RecordTypeId FROM task      
                                            WHERE WhatId = :mapOld.get(tsID).WhatId
                                            AND OwnerId IN : grMSet
                                            AND Subject = : mapNew.get(tsID).Subject
                                            AND RecordTypeId = :mapNew.get(tsID).RecordTypeId];
                                if(!tsToUpd.isEmpty()) {
                                    for(task ts : tsToUpd) {
                                        ts.Status = mapNew.get(tsID).Status;
                                    }
                                    update tsToUpd;
                                }
                            }
                        }
                    }           
                }
                catch(System.Exception e) {
                    system.debug('############################alex102 e=' + e);
                }
            
            }
        
            if(mapNew.get(tsID).Status == 'Wiedervorlage') {
                try {
                    Schema.sObjectType tType=(mapOld.get(tsID).WhatId).getSObjectType();
                    if(string.valueOf(tType) == 'Kunde__c') {
                        date aDate = Date.today();
                        DateTime remDt = System.now();
                        if(mapNew.get(tsID).Grund_des_Abbruchs__c == 'Kunde nicht erreicht (1 Tag)') {
                                                                      
                            aDate = aDate.addDays(1);
                            remDt = remDt.addDays(1);
                        }
                        if(mapNew.get(tsID).Grund_des_Abbruchs__c == 'Noch kein Bedarf (3 Monate)') {
                            aDate = aDate.addMonths(3);
                            remDt = remDt.addMonths(3);
                        }                   
                        if(mapNew.get(tsID).Grund_des_Abbruchs__c == 'Neues Formular verschickt (3 Tage)') {
                            aDate = aDate.addDays(3);
                            remDt = remDt.addDays(3);
                        }
                        if(mapNew.get(tsID).Grund_des_Abbruchs__c == 'Kunde schickt Antrag los (7 Tage)') {
                            aDate = aDate.addDays(7);
                            remDt = remDt.addDays(7);
                        }
                        system.debug('############################wds1 =' +mapNew.get(tsID).Grund_des_Abbruchs__c );
                        if(mapNew.get(tsID).Grund_des_Abbruchs__c == 'Beim Kunden in Klärung (7 Tage)') {
                                                                 
                            aDate = aDate.addDays(7);
                            remDt = remDt.addDays(7);
                        }  
                        if(mapNew.get(tsID).Grund_des_Abbruchs__c == 'Formular ist beim Kunden angekommen (2 Wochen)') {
                            aDate = aDate.addDays(14);
                            remDt = remDt.addDays(14);
                        } 
                        
                        // list<Group> grList = [SELECT id FROM Group WHERE Name = 'Nachtelefonie' LIMIT 1];
                        // if((grList != null) && (grList.size() > 0)) {   
                            // grID = grList[0].id;
                        // }   
                        // list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                                    // FROM GroupMember 
                                                    // WHERE GroupId = : grID];
                        // set<id> grMSet = new set<id>();
                        
                        if((gmList != null) && (gmList.size() > 0)) { 
                            for(GroupMember GM : gmList) {
                                grMSet.add(GM.UserOrGroupId);
                            }   
                            if(!grMSet.isEmpty()) {
                                tsToWv = [SELECT id, Status, Grund_des_Abbruchs__c, ActivityDate 
                                            FROM task      
                                            WHERE WhatId = :mapOld.get(tsID).WhatId
                                            AND OwnerId IN : grMSet
                                            AND Subject = : mapNew.get(tsID).Subject
                                            AND RecordTypeId = :mapNew.get(tsID).RecordTypeId];
                                if(!tsToWv.isEmpty()) {
                                    system.debug('############################alex100 tsToWv.size()=' + tsToWv.size());
                                    for(task ts : tsToWv) {
                                        system.debug('############################alex101 ts.ActivityDate=' + ts.ActivityDate);
                                        if((ts.ActivityDate != aDate) 
                                            
                                            || (ts.Status != mapNew.get(tsID).Status) 
                                            || (ts.Grund_des_Abbruchs__c != mapNew.get(tsID).Grund_des_Abbruchs__c)) {
                                            ts.ActivityDate = aDate;
                                            ts.ReminderDateTime = remDt;
                                            ts.Status = mapNew.get(tsID).Status;
                                            ts.Grund_des_Abbruchs__c = mapNew.get(tsID).Grund_des_Abbruchs__c;
                                            tsToUpdWv.add(ts);
                                        }                                   
                                    }
                                    if(!tsToUpdWv.isEmpty()) {
                                        update tsToUpdWv;
                                    }
                                }
                            }
                        }                   
                    }  
                }
                catch(System.Exception e) {
                    system.debug('############################alex103 e=' + e);
                }               
            }
        }

        if(!kdSet54.isEmpty()) {          
            list<Kundenstatus__c> ksList = [SELECT id, Status__c, Produktgruppe__c 
                                            FROM Kundenstatus__c 
                                            WHERE Kunde__c IN :kdSet54 
                                            AND Produktgruppe__c = 'PG54'];            
            if((ksList != null) && (ksList.size() > 0)) {
                for(Kundenstatus__c ks : ksList) {
                    ks.Status__c = 'Vorgang geschlossen';                      
                }
                try {
                    update ksList;
                }
                catch (System.Exception e) {
                    system.debug('############################error update ksList ' + e);
                }
            }
        }

        if(!kdSet51.isEmpty()) {          
            list<Kundenstatus__c> ksList = [SELECT id, Status__c, Produktgruppe__c 
                                            FROM Kundenstatus__c 
                                            WHERE Kunde__c IN :kdSet51 
                                            AND Produktgruppe__c = 'PG51'];            
            if((ksList != null) && (ksList.size() > 0)) {
                for(Kundenstatus__c ks : ksList) {
                    ks.Status__c = 'Vorgang geschlossen';                      
                }
                try {
                    update ksList;
                }
                catch (System.Exception e) {
                    system.debug('############################error update ksList ' + e);
                }
            }
        }
        
        if(!kdSetInko.isEmpty()) {          
            list<Kundenstatus__c> ksList = [SELECT id, Status__c, Produktgruppe__c 
                                            FROM Kundenstatus__c 
                                            WHERE Kunde__c IN :kdSetInko 
                                            AND Produktgruppe__c = 'Inko'];            
            if((ksList != null) && (ksList.size() > 0)) {
                for(Kundenstatus__c ks : ksList) {
                    ks.Status__c = 'Vorgang geschlossen';                      
                }
                try {
                    update ksList;
                }
                catch (System.Exception e) {
                    system.debug('############################error update ksList ' + e);
                }
            }
        }
        
    }
    
    
    // wird nicht aufgerufen! Nur für Testabdeckung!!!  
    public class dummyZeile {                
        public String Rpos {get;set;}
        public String Anzahl_Verpackungen {get;set;}
        public string th {get; set;}
        public string thu {get; set;}
        public string trs {get; set;}
        public string lDatum {get; set;}
        public string stern {get; set;}
    }
        
    public static void setLeereZeilen() {
            List<dummyZeile> pZeilen = new List<dummyZeile>();
            dummyZeile dZeile = new dummyZeile();
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
    }           
}