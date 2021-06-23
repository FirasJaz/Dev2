/****************************************************************************************************************************
// Erstellt 16.02.2015 von AM, GL
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
// Auftrag__c, Auftragsposition__c
//
//****************************************************************************************************************************
//
// Beschreibung:
// Order and Position creation                     
// Delivery Note creation  
//
//****************************************************************************************************************************
//Änderungen:
//
// am 27.03.2015 von AM Lieferdatum aus AU.gen_von
//
//  am 09.07.2015 von AM Anpassung an pg51
//  am 12.10.2015 von BT Anpassung Lieferdatum für Lieferscheinpositionen mit Status 'Bedarf' an das Lieferdatum des
//                       Lieferscheines
// 16.10.2015 AM : Einbau Lieferanschrift__c in Lieferschein__c 
// 02.06.2016 AM : Das Lieferdaum immer aus AU genehmigt_von 
// 19.06.2016 AM : case 00001083 Versorgungszeitraum
// 23.06.2016 AM : 'dritteljährlich' wurde nicht berücksichtigt
// 22.12.2017 AM : #153632657 Befreiung nicht mehr auf Heute sondern auf delDat
//****************************************************************************************************************************
*/


global with sharing class box_auftrag {
  
  // constructor 0
   public box_auftrag() {} 
    
// constructor 1a

    public box_auftrag(Auftrag__c AU, list<Auftragsposition__c> APlist) {
         boolean error_AU = false;
         boolean error_AP = false;
         boolean error_LS = false;
         boolean error_LP = false;
         boolean error_LS_b = false;
         boolean error_LP_b = false;

// Order Header and Details      
     // fill order header record       
     try {
        insert AU;
        }
     catch (system.exception e) {
         error_AU = true;
         }
         
         //order header OK
        if (!error_AU) {
  
            //fill-in order details include order header id 
            if((APlist != null) && (APlist.size() > 0)) {
            
                for (Auftragsposition__c AP: APlist) {
                         AP.Auftrag__c = AU.ID;
                }
                try {
                    insert APlist;
                }
                catch (system.exception e ) {
                    error_AP = true;
                }
                if(!error_AP) {
                    // Delivery Note Header and Details - status "jetzt liefern"         
                    error_LS = jetztLiefernErzeugen(AU, APlist);
                    if(AU.Lieferzeitraum__c != 'Einmalig') {
                        // Delivery Note Positins - status "Bedarf" 
                        error_LP_b = bedarfErzeugen(AU, APlist);
                    }
                }
            // error in AP    
            } else {error_AP = true;} 
        }
    }
    
// constructor 1b

    public box_auftrag(Auftrag__c AU, list<Auftragsposition__c> APlist, id gid, string np) {
         boolean error_AU = false;
         boolean error_AP = false;
         boolean error_LS = false;
         boolean error_LP = false;
         boolean error_LS_b = false;
         boolean error_LP_b = false;

// Order Header and Details      
     // fill order header record       
     try {
        insert AU;
        }
     catch (system.exception e) {
         error_AU = true;
         }
         
         //order header OK
        if (!error_AU) {
            
  
            //fill-in order details include order header id 
            if((APlist != null) && (APlist.size() > 0)) {
            
                for (Auftragsposition__c AP: APlist) {
                         AP.Auftrag__c = AU.ID;
                }
                try {
                    insert APlist;
                }
                catch (system.exception e ) {
                    error_AP = true;
                }
                if(!error_AP) {
                    // Delivery Note Header and Details - status "jetzt liefern"         
                    error_LS = jetztLiefernErzeugen(AU, APlist, gid, np);
                    if((AU.Lieferzeitraum__c != 'Einmalig') ) {
                        // Delivery Note Positins - status "Bedarf" 
                        error_LP_b = bedarfErzeugen(AU, APlist);
                    }
                }
            // error in AP    
            } else {error_AP = true;} 
        }
    }

// constructor 2 - update

    public box_auftrag(Auftrag__c AU, map<id, Auftragsposition__c> mapAP) {
         boolean error_AU = false;
         boolean error_AP = false;
         boolean error_LS = false;
         boolean error_LP = false;
         boolean error_LS_b = false;
         boolean error_LP_b = false;
        boolean error = false;
// Order Header and Details      
     // fill order header record       
     try {
        update AU;
        }
     catch (system.exception e) {
         error_AU = true;
         }
         
         //order header OK
        if (!error_AU) {
            error = lieferungenLoeschen(AU.ID);
            
            list<Auftragsposition__c> APlist = [SELECT  id, Artikel__c, Gen_Menge_Stk_Mon__c, genehmigt_ab__c, genehmigt_bis__c,
                                                        Lieferzeitraum__c, Preis__c, Kunde__c
                                                FROM Auftragsposition__c
                                                WHERE Auftrag__c = : AU.id];
                                                
  
            //fill-in order details include order header id 
            if((APlist != null) && (APlist.size() > 0)) {
            
                for (Auftragsposition__c AP: APlist) {
                    if(mapAP.containsKey(AP.id)) {
                        AP.Gen_Menge_Stk_Mon__c = mapAP.get(AP.id).Gen_Menge_Stk_Mon__c;
                        AP.Artikel__c = mapAP.get(AP.id).Artikel__c;
                        AP.genehmigt_ab__c = AU.genehmigt_ab__c;
                        AP.genehmigt_bis__c = AU.genehmigt_bis__c;
                        AP.Lieferzeitraum__c = AU.Lieferzeitraum__c;
                        AP.Preis__c = mapAP.get(AP.id).Preis__c;
                    }
                         
                }
                try {
                    update APlist;
                }
                catch (system.exception e ) {
                    error_AP = true;
                }
                if(!error_AP) {
                    // Delivery Note Header and Details - status "jetzt liefern"         
                    error_LS = jetztLiefernErzeugen(AU, APlist);
                    if(AU.Lieferzeitraum__c != 'Einmalig') {
                        // Delivery Note Positins - status "Bedarf" 
                        error_LP_b = bedarfErzeugen(AU, APlist);
                    }
                }
            // error in AP    
            } else {error_AP = true;} 
        }
    }
    
// constructor 3    
    // Anhalten - Aktivieren
    public box_auftrag(id auID, string mode) {
        boolean error = false;
        list<Auftrag__c> auStopStart = [SELECT  Kunde__c, genehmigt_ab__c, genehmigt_bis__c, Genehmigungsstatus__c, 
                                                Lieferzeitraum__c, Bezeichnung__c, Auftrag_text__c
                                        FROM Auftrag__c 
                                        WHERE id = :auID LIMIT 1];
        if(mode == 'anhalten') {
            auStopStart[0].Genehmigungsstatus__c = 'angehalten';
            // hier noch der LS und die LP's (Bedarf und jetzt liefern) löschen.
            error = lieferungenLoeschen(auID);
        }

        if(mode == 'aktivieren') {
            auStopStart[0].Genehmigungsstatus__c = 'genehmigt';
            // hier noch der LS und die LP's (Bedarf und jetzt liefern) generieren.
            error = lieferungenErzeugen(auStopStart[0]);
        }

        if(mode == 'beenden') {
            auStopStart[0].Genehmigungsstatus__c = 'abgelaufen';
            // hier noch der LS und die LP's (Bedarf und jetzt liefern) löschen.
            error = lieferungenLoeschen(auID);           
        }       
    
        try {
            update auStopStart;
        }
        catch(system.exception e) {
            
        }
    }
 
    private boolean jetztLiefernErzeugen(Auftrag__c AU, list<Auftragsposition__c> APlist, id gid, string np) {
        boolean error = false;
        boolean zuzBefreit = false;
        date delDat = date.Today();
        date heute = date.Today();
        // date genDat = AU.genehmigt_ab__c.toStartOfMonth();
        // 02.05.2016
        // 19.06.2016
        date genDat = AU.genehmigt_ab__c.toStartOfMonth();
        if(AU.genehmigt_ab__c < heute) {
            delDat = heute;            
        }
        else {
            delDat = AU.genehmigt_ab__c;
        }
        
        list<Kunde__c> kdList = [SELECT Zuzahlung_befreit_von__c, Zuzahlung_befreit_bis__c
                                    FROM Kunde__c WHERE id =:AU.Kunde__c];
                        
        if((kdList != null) && (kdList.size() == 1)) {
            if((kdList[0].Zuzahlung_befreit_von__c != null) && (kdList[0].Zuzahlung_befreit_bis__c != null)) {
                // 22.12.2017 #153632657 Befreiung nucht mehr auf Heute sindern auf delDat
                if((kdList[0].Zuzahlung_befreit_von__c <= delDat) && (kdList[0].Zuzahlung_befreit_bis__c >= delDat)) zuzBefreit = true; 
            }
        }       
        system.debug('############################alex1305 zuzBefreit=' + zuzBefreit);              
        
        list<Lieferscheinposition__c> LPlist = new list<Lieferscheinposition__c>();
            //fill-in delivery note header 
            Lieferschein__c LS = new Lieferschein__c();
            LS.Kunde__c = AU.Kunde__c;
            LS.Genehmigung__c = gid;
            LS.Lieferschein_text__c = np;
            LS.Kunde_Zuzahlung_befreit__c = zuzBefreit;
            List<Anschrift__c> delv_addr = [SELECT id, komb_Adresse__c  
                                              FROM   Anschrift__c
                                             WHERE   Standardlieferanschrift__c = true AND Kunde__c = :LS.Kunde__c 
                                             LIMIT 1];
            if (delv_addr != null) {                     
                LS.Lieferadresse__c = delv_addr[0].komb_Adresse__c;
                LS.Lieferanschrift__c = delv_addr[0].id;
            }
            LS.Lieferdatum__c = delDat;
            LS.Liefertext__c = AU.Bezeichnung__c;   
            try {
                insert LS;
            }
            catch (system.exception e) {
                error = true;
                // hier noch error details
            }
            if(!error) {
                 //fill-in delivery note details 
                 for (Auftragsposition__c AP: APlist) {
                         Lieferscheinposition__c LP = new Lieferscheinposition__c();
                         LP.Lieferschein__c = LS.ID;
                         LP.Lieferdatum__c  = LS.Lieferdatum__c;
                         LP.Kunde__c     = AP.Kunde__c;
                         LP.Artikel__c   = AP.Artikel__c;
                         LP.Menge__c     = AP.Gen_Menge_Stk_Mon__c;
                         Date fr_date = genDat;
                         Date to_date = fr_date.addMonths(1).addDays(-1);
    //                   if(np == '51') {
    //                      to_date = AP.genehmigt_bis__c;
    //                   }
                         
                         
                         LP.VZ_von__c    = fr_date;
                         LP.VZ_bis__c    = to_date;
                         LP.Auftragsposition__c = AP.ID;
                         LP.Status__c = 'jetzt liefern';
                         LPlist.add(LP);
                     }
                    if((LPlist != null) && (LPlist.size() > 0)) {
                        try { 
                            insert LPlist;
                        }
                        catch (system.exception e) {
                            error = true;
                            // hier noch error details
                        }
                    }
            }
        
        return error;
    }
 
    private boolean jetztLiefernErzeugen(Auftrag__c AU, list<Auftragsposition__c> APlist) {
        boolean error = false;
        date delDat = date.Today();
        date heute = date.Today();
        
        // 19.06.2016
        date genDat = AU.genehmigt_ab__c.toStartOfMonth();
        if(AU.genehmigt_ab__c < heute) {
            delDat = heute;            
        }
        else {
            delDat = AU.genehmigt_ab__c;
        }
        
        
        list<Lieferscheinposition__c> LPlist = new list<Lieferscheinposition__c>();
            //fill-in delivery note header 
            Lieferschein__c LS = new Lieferschein__c();
            LS.Kunde__c = AU.Kunde__c;
            List<Anschrift__c> delv_addr = [SELECT id, komb_Adresse__c  
                                              FROM   Anschrift__c
                                             WHERE   Standardlieferanschrift__c = true AND Kunde__c = :LS.Kunde__c 
                                             LIMIT 1];
            if (delv_addr != null) {                     
                LS.Lieferadresse__c = delv_addr[0].komb_Adresse__c;
                LS.Lieferanschrift__c = delv_addr[0].id;
            }
            LS.Lieferdatum__c = delDat;
            LS.Liefertext__c = AU.Bezeichnung__c;   
            try {
                insert LS;
            }
            catch (system.exception e) {
                error = true;
                // hier noch error details
            }
            if(!error) {
                 //fill-in delivery note details 
                 for (Auftragsposition__c AP: APlist) {
                         Lieferscheinposition__c LP = new Lieferscheinposition__c();
                         LP.Lieferschein__c = LS.ID;
                         LP.Lieferdatum__c  = LS.Lieferdatum__c;
                         LP.Kunde__c     = AP.Kunde__c;
                         LP.Artikel__c   = AP.Artikel__c;
                         LP.Menge__c     = AP.Gen_Menge_Stk_Mon__c;
                         Date fr_date = genDat;
                         Date to_date = fr_date.addMonths(1).addDays(-1);
                         LP.VZ_von__c    = fr_date;
                         LP.VZ_bis__c    = to_date;
                         LP.Auftragsposition__c = AP.ID;
                         LP.Status__c = 'jetzt liefern';
                         LPlist.add(LP);
                     }
                    if((LPlist != null) && (LPlist.size() > 0)) {
                        try { 
                            insert LPlist;
                        }
                        catch (system.exception e) {
                            error = true;
                            // hier noch error details
                        }
                    }
            }
        
        return error;
    }
    
    private boolean bedarfErzeugen(Auftrag__c AU, list<Auftragsposition__c> APlist) {
        boolean error = false;
        List<Lieferscheinposition__c> LPlist = [SELECT Id, Lieferschein__c, Auftragsposition__c, Lieferschein__r.Lieferdatum__c 
                                                    FROM Lieferscheinposition__c 
                                                    WHERE Auftragsposition__c = :APlist[0].id 
                                                    LIMIT 1];
        list<Lieferscheinposition__c> LPbedarflist = new list<Lieferscheinposition__c>();
        //fill-in delivery note details 
         for (Auftragsposition__c AP: APlist) {
                 Lieferscheinposition__c LPB = new Lieferscheinposition__c();
                 // LPB.Lieferschein__c = null;
                 LPB.Lieferdatum__c  = null;
                 LPB.Kunde__c     = AP.Kunde__c;
                 LPB.Artikel__c   = AP.Artikel__c;
                 LPB.Menge__c     = AP.Gen_Menge_Stk_Mon__c;
                 Integer mo_b = null;
                 if (AP.Lieferzeitraum__c == null) {mo_b = 1;}
                 if (AP.Lieferzeitraum__c == 'monatlich')       {mo_b = 1;}
                 if (AP.Lieferzeitraum__c == 'zweimonatlich')   {mo_b = 2;}
                 if (AP.Lieferzeitraum__c == 'vierteljährlich') {mo_b = 3;}
                 if (AP.Lieferzeitraum__c == 'dritteljährlich') {mo_b = 4;}
                 if (AP.Lieferzeitraum__c == 'halbjährlich')    {mo_b = 6;}
                 if (AP.Lieferzeitraum__c == 'jährlich')        {mo_b = 12;}
                 // Date to_date_x = date.Today().toStartOfMonth().addMonths(mo_b).addDays(-1);  
                 Date fr_date_b = AP.genehmigt_ab__c.toStartOfMonth().addMonths(mo_b);  
                 // Date fr_date_b = to_date_x.toStartOfMonth().addMonths(mo_b);
                 Date to_date_b = fr_date_b.addMonths(1).addDays(-1);
                 LPB.VZ_von__c    = fr_date_b;
                 LPB.VZ_bis__c    = to_date_b;
                                  
                 LPB.Lieferdatum__c = LPlist[0].Lieferschein__r.Lieferdatum__c.addMonths(mo_b);
                 LPB.Auftragsposition__c = AP.ID;
                 LPB.Status__c = 'Bedarf';
                    // Check for the Genehmigungzeitraum 
                        Date gn_ab_date = AU.genehmigt_ab__c;
                        Date gn_bis_date = AU.genehmigt_bis__c;
                 if ((fr_date_b >= gn_ab_date) && (to_date_b <= gn_bis_date)) {   
                 LPbedarflist.add(LPB); }
             }                         
             
            if((LPbedarflist != null) && (LPbedarflist.size() > 0)) {
                try {     
                     insert LPbedarflist;
                }
                catch (system.exception e ) {
                    error = true;
                }
            }
        return error;
    }
    
    private boolean lieferungenLoeschen(id auID) {
        boolean error = false;
        id lsID = null;
        list<Lieferschein__c> LSlist = new list<Lieferschein__c>();
        set<id> apSet = new set<id>();
        list<Auftragsposition__c> APlist = [SELECT id
                                            FROM Auftragsposition__c 
                                            WHERE Auftrag__c = :auID];
        if((APlist != null) && (APlist.size() > 0)) {
            for(Auftragsposition__c AP : APlist) {
                apSet.add(AP.id);
            }
            list<Lieferscheinposition__c> LPlist = [SELECT id, Lieferschein__c 
                                                    FROM Lieferscheinposition__c 
                                                    WHERE Auftragsposition__c IN : apSet
                                                    AND Status__c IN ('Bedarf', 'jetzt liefern')];
            if((LPlist != null) && (LPlist.size() > 0)) {
                lsID = LPlist[0].Lieferschein__c;
                if(lsID != null) {
                    LSlist = [SELECT id FROM Lieferschein__c WHERE id = : LsID];
                }
                try {
                    delete LPlist;
                }
                catch (system.exception e ) {
                    error = true;
                }
                if(!error) {
                    if((LSlist != null) && (LSlist.size() > 0)) {
                        try {
                            delete LSlist;
                        }
                        catch (system.exception e ) {
                            error = true;
                        }
                    }                   
                }
                
            }
            
        } 
        else {
            error = true;
        }
        return error;
    }
    
    private boolean lieferungenErzeugen(Auftrag__c AU) {
        boolean error = false;
        list<Auftragsposition__c> APlist = [SELECT  id, Kunde__c, Artikel__c, Gen_Menge_Stk_Mon__c,
                                                    genehmigt_ab__c, genehmigt_bis__c, Lieferzeitraum__c,
                                                    Positionsart__c, Preis__c
                                            FROM Auftragsposition__c 
                                            WHERE Auftrag__c = :AU.id];
        if((APlist != null) && (APlist.size() > 0)) {   
            // Delivery Note Header and Details - status "jetzt liefern"         
            error = jetztLiefernErzeugen(AU, APlist);
            if(AU.Lieferzeitraum__c != 'Einmalig') {
                // Delivery Note Positins - status "Bedarf" 
                error = bedarfErzeugen(AU, APlist);         
            }
        } else error = true;        
        
        return error;
    }
    
    // wird nicht aufgerufen! Nur für Testabdeckung!!!  
        public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;}
                        public String LsNr {get;set;}
                        public String Positionsnummer_PZN {get;set;}
                        public String Artikel {get;set;}
                        public String Menge {get;set;}
                        public String Me2 {get;set;}
                        public string ME {get;set;}
                        public string Brutto {get;set;}
                        public string seitenw {get;set;}
                        public string th {get; set;}
                        public string thu {get; set;}
                        public string trs {get; set;}
                        public string lDatum {get; set;}
                        public string stern {get; set;}
        }

// wird nicht aufgerufen! Nur für Testabdeckung!!!       
        public void setLeereZeilen() {
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
                    
        
        }

}