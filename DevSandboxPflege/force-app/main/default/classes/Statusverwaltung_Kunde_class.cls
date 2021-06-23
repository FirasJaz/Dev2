//****************************************************************************************************************************
// Erstellt 10.08.2015     von wds
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
// Sorgt das Anlegen und Ändern von Stati-Informationen zum Kunden #100636896
//
//
//****************************************************************************************************************************
//Änderungen:
//
// 
// 25.08.2015 von AM Funktion für trigger
// 26.08.2015 von wds Recordtyp eingebaut und Status modifiziert
// 27.08.2015 von wds #102160038 zusätzliche Felder belegen
// 21.09.2015 von BT  #102159728 PG51 auf Kandidat setzen
// 24.09.2015 von wds #100106578 Status "shop" setzen
// 29.12.2015 von AM #110237326 CRM_Ticket_ID__c hinzugefügt
// 08.02.2015 von wds #111866741 auch bei Vorgang geschlossen Status auf 'Kandidat' setzen
// 15.12.2016 von BT  #135040991 Das Feld "Antrag bewilligt/abgelehnt am" im Kundenstatus wird nicht mehr überschrieben
// 30.12.2016 von BT  #134953285 Kundenstatus werden aktualisiert, wenn ein Antrag hochgeladen wird
// 12.04.2017 von BT  Mailversand und Taskerstellung, wenn neuer Antrag hochgeladen wird.
//****************************************************************************************************************************
public with sharing class Statusverwaltung_Kunde_class {
   

        
    public static void insert_neuen_kundenstatus(List<Kunde__c> Kunden) {
    
        List<Kundenstatus__c> Kundenstatus = new List<Kundenstatus__c>{}; 
        Kundenstatus__c KS1;
        Kundenstatus__c KS2;
        Kundenstatus__c KS3;
        Kundenstatus__c KS4;
//
//      für alle Kunden 
//       
        for (Kunde__c kd : Kunden) {
//                
//         Status als Interessent eintragen
//
            KS1 = new Kundenstatus__c();
            KS2 = new Kundenstatus__c();
            KS3 = new Kundenstatus__c();
            KS4 = new Kundenstatus__c();
            
            if (kd.produktgruppe__c.contains('PG54')){
                id rtid1 = null;                                
                list<RecordType> rtList1 = [SELECT Id FROM RecordType WHERE sObjectType='Kundenstatus__c' AND Name=: '§54'];
                if((rtList1 != null) && (rtList1.size() > 0)) {
                    rtId1 = rtList1[0].id;
                } 
                       
                KS1.RecordTypeId = rtid1;
                KS1.Status__c = 'Interessent';
                KS1.Produktgruppe__c = 'PG54';
                KS1.Kunde__c = kd.id; 
                KS1.Ursprungsanfrage__c = kd.Ursprungsanfrage__c;
                KS1.Tracking_Order_ID__c = kd.Tracking_order_id__c;
                KS1.Mitarbeiter__c = kd.Mitarbeiter__c;
                KS1.CRM_Ticket_ID__c = kd.CRM_Ticket__c;
                Kundenstatus.add(KS1);                
            }
            
            if (kd.produktgruppe__c.contains('PG51')){
                id rtid2 = null;                                
                list<RecordType> rtList2 = [SELECT Id FROM RecordType WHERE sObjectType='Kundenstatus__c' AND Name=: '§51'];
                if((rtList2 != null) && (rtList2.size() > 0)) {
                    rtId2 = rtList2[0].id;
                }   
                    
                KS2.RecordTypeId = rtid2;
                KS2.Status__c = 'Interessent';
                KS2.Produktgruppe__c = 'PG51';
                KS2.Kunde__c = kd.id;
                KS2.Ursprungsanfrage__c = kd.Ursprungsanfrage__c;
                KS2.Tracking_Order_ID__c = kd.Tracking_order_id__c;
                KS2.Mitarbeiter__c = kd.Mitarbeiter__c;  
                KS2.CRM_Ticket_ID__c = kd.CRM_Ticket__c;                
                Kundenstatus.add(KS2);                
            }
            
            if (kd.produktgruppe__c.contains('Inko')) {
                id rtid3 = null;                                
                list<RecordType> rtList3 = [SELECT Id FROM RecordType WHERE sObjectType='Kundenstatus__c' AND Name=: 'Inko'];
                if((rtList3 != null) && (rtList3.size() > 0)) {
                    rtId3 = rtList3[0].id;
                }
                
                       
                KS3.RecordTypeId = rtid3;
                
                KS3.Status__c = kd.next_step__c;
                KS3.Produktgruppe__c = 'Inko';
                KS3.Kunde__c = kd.id;
                KS3.Ursprungsanfrage__c = kd.Ursprungsanfrage__c;
                KS3.Tracking_Order_ID__c = kd.Tracking_order_id__c;
                KS3.Mitarbeiter__c = kd.Mitarbeiter__c;   
                KS3.CRM_Ticket_ID__c = kd.CRM_Ticket__c;                
                Kundenstatus.add(KS3);
            }
            
            if (kd.produktgruppe__c.contains('Shop')) {
                id rtid4 = null;                                
                list<RecordType> rtList4 = [SELECT Id FROM RecordType WHERE sObjectType='Kundenstatus__c' AND Name=: 'Shop'];
                if((rtList4 != null) && (rtList4.size() > 0)) {
                    rtId4 = rtList4[0].id;
                }
                
                       
                KS4.RecordTypeId = rtid4;
                
                KS4.Status__c = kd.next_step__c;
                KS4.Produktgruppe__c = 'Shop';
                KS4.Kunde__c = kd.id;
                KS4.Ursprungsanfrage__c = kd.Ursprungsanfrage__c;
                KS4.Tracking_Order_ID__c = kd.Tracking_order_id__c;
                KS4.Mitarbeiter__c = kd.Mitarbeiter__c; 
                KS4.CRM_Ticket_ID__c = kd.CRM_Ticket__c;                
                Kundenstatus.add(KS4);
            }
            
        
        }
//
//          insert der Adressen
//
        try {
            insert Kundenstatus;
        }catch (system.Dmlexception d){
            
        }           
    }
   
    public static boolean attachmentUpload(set<id> kdset, string pg, string stat) {
        boolean error = false;
        map<id, Kundenstatus__c> ksuMap = new map<id, Kundenstatus__c>();
        list<Kundenstatus__c> ksiList = new list<Kundenstatus__c>();
        
        list<Kundenstatus__c> ksList = [SELECT id, Kunde__c, Status__c, Produktgruppe__c, 
                                                K_ndigungsgrund__c, K_ndigungsdatum__c, K_ndigungsbemerkung__c,
                                                Antrag_eingegangen_am__c, Antrag_bewilligt_abgelehnt_am__c
                                        FROM Kundenstatus__c
                                        WHERE Kunde__c IN :kdset
                                        AND Produktgruppe__c = :pg];
        if((ksList != null) && (ksList.size() > 0)) {
            for(Kundenstatus__c KS : ksList) {
                KS.Status__c = stat;
                if(stat == 'Kandidat') {
                    KS.Antrag_eingegangen_am__c = date.today();
                }
                else {
                    if(KS.Antrag_bewilligt_abgelehnt_am__c == null) KS.Antrag_bewilligt_abgelehnt_am__c = date.today();
                }
                ksuMap.put(KS.Kunde__c, KS);
            }
            if(ksList.size() < kdset.size()) {
                for(id kdid : kdset) {
                    if(!ksuMap.containsKey(kdid)) {
                        Kundenstatus__c KSi = new Kundenstatus__c(Kunde__c = kdid, Status__c = stat, Produktgruppe__c = pg);
                        if(stat == 'Kandidat') {
                            KSi.Antrag_eingegangen_am__c = date.today();
                        }
                        else {
                            KSi.Antrag_bewilligt_abgelehnt_am__c = date.today();
                        }
                        ksiList.add(KSi);
                    }
                }                   
            }
            if(!ksuMap.isEmpty()) {
                try {
                    update ksuMap.values();
                }
                catch (System.Exception e) {
                    system.debug('######################### error update ksuMap ' + e);
                }
            }
            if(!ksiList.isEmpty()) {
                try {
                    insert ksiList;
                }
                catch (System.Exception e) {
                    system.debug('######################### error inser ksiList ' + e);
                }
            }       
        }       
        return error;
    }
    
    public static boolean attachmentUpload(set<id> kdset, string stat) {
        boolean error = false;
        map<id, Kundenstatus__c> ksuMap = new map<id, Kundenstatus__c>();
        list<Kundenstatus__c> ksiList = new list<Kundenstatus__c>();
        system.debug('#######################00000'); 
        list<Kundenstatus__c> ksList = [SELECT id, Kunde__c, Status__c, Produktgruppe__c, 
                                                K_ndigungsgrund__c, K_ndigungsdatum__c, K_ndigungsbemerkung__c,
                                                Antrag_eingegangen_am__c, Antrag_bewilligt_abgelehnt_am__c
                                        FROM Kundenstatus__c
                                        WHERE Kunde__c IN :kdset
                                        AND Produktgruppe__c IN ('PG54', 'PG51')
                                        AND Status__c in ('Interessent', 'Vorgang geschlossen')];
        if((ksList != null) && (ksList.size() > 0)) {
            for(Kundenstatus__c KS : ksList) {              
                KS.Status__c = stat;                  
                      
                if(stat == 'Kandidat') {
                    KS.Antrag_eingegangen_am__c = date.today();
                }
            }

                try {
                    update ksList;
                }
                catch (System.Exception e) {
                    system.debug('######################### error update ksList' + e);
                }
       
            if(!ksiList.isEmpty()) {
                try {
                    insert ksiList;
                }
                catch (System.Exception e) {
                    system.debug('######################### error inser ksiList ' + e);
                }
            }       
        }       
        return error;
    }
    
    public static boolean updateKS(set<id> kdset, string stat, string pg) {
        boolean error = false;
        map<id, Kundenstatus__c> ksuMap = new map<id, Kundenstatus__c>();
        list<Kundenstatus__c> ksiList = new list<Kundenstatus__c>();
        system.debug('#######################00000'); 
        list<Kundenstatus__c> ksList = [SELECT id, Kunde__c, Status__c, Produktgruppe__c, 
                                                K_ndigungsgrund__c, K_ndigungsdatum__c, K_ndigungsbemerkung__c,
                                                Antrag_eingegangen_am__c, Antrag_bewilligt_abgelehnt_am__c
                                        FROM Kundenstatus__c
                                        WHERE Kunde__c IN :kdset
                                        AND Produktgruppe__c IN ('PG54', 'PG51')
                                        AND Status__c in ('Interessent', 'Vorgang geschlossen')];
        if((ksList != null) && (ksList.size() > 0)) {
            for(Kundenstatus__c KS : ksList) {     
                if(KS.Produktgruppe__c == pg) {    
                    KS.Status__c = stat;                  
                      
                    if(stat == 'Kandidat') {
                        KS.Antrag_eingegangen_am__c = date.today();
                    }
                }
                else {
                    KS.Status__c = 'Vorgang geschlossen';
                }

            }

                try {
                    update ksList;
                }
                catch (System.Exception e) {
                    system.debug('######################### error update ksList' + e);
                }
       
            if(!ksiList.isEmpty()) {
                try {
                    insert ksiList;
                }
                catch (System.Exception e) {
                    system.debug('######################### error inser ksiList ' + e);
                }
            }       
        }     
        
        if(stat == 'Kandidat' && pg == 'PG54') {
            set<id> kidSet = new set<id>();
            set<id> kSet = new set<id>();
            list<Kundenstatus__c> kdsList = new list<Kundenstatus__c>([SELECT id, Kunde__c, Status__c, Produktgruppe__c
                                                                        FROM Kundenstatus__c
                                                                        WHERE Kunde__c IN :kdset
                                                                        AND Produktgruppe__c = 'PG51'
                                                                        AND Status__c in ('Kandidat', 'Kunde', 'Kündigung')]); 
            
            for(Kundenstatus__c ks: kdsList){
                kidSet.add(ks.kunde__c);
            }   
                        
            for(id kid: kdset) {
                if(!kidSet.contains(kid)) kSet.add(kid);
            }
                
            if(kSet.size() > 0) {
                for(Id kdid: kSet){
                    Mail_versenden_class.sendMail(kdid, 'Curabox_ist_PG51_gew_nscht');
                    if(Mail_versenden_class.error == false) {
                        Task_erstellen_class.createTask(new set<id>{kdid}, 'Ist PG51 gewünscht ?');
                    }
                }
            }
                                                                                
        } 
        return error;
    }

}