/*
*   Autor: MS
*   Stand: 11.9.2012
*   Beschreibung: Die Klasse ist der Controller für die Pages AB_BKK/KK_nur_anzeigen.
*               Erstellt also die Abrechnungen für die Krankenkasse. Erstellt außerdem eine entsprechende Rechnung,
*               damit daraus ein Buchungssatz erstellt werden kann.
*   
*   deployed am 11.9.12
*wds            05.10.12  Modifikation der Berechnung des KK-Preises bei normalen Genehmigungen! noch nicht deployed
*wds            13.10.12 deployed, Anlage 4 Preis durch Gesamtmenge * Liefermenge
*
*wds            04.09.13 ein systemdebug war fehlerhaft, das habe ich herausgenommen
*
*   Geändert    28.07.2014 ACR??? Abbruch durch zu viele DML
*am Änderungen: Die RP's werden zuerst in die Liste geschrieben und dann inserted und Sortierung eingefügt
*
*wds            11.08.2014 ACR nn  storniert und andere Kriterien bei der Abrechnung berücksichtigen!
*
*/
//      geändert am 19.08.2014 durch WDS    ACR 266: Preis für Anlage 4 Artikel aus Artikelstamm holen!
//
//      geändert am 19.08.2014 durch AM     ACR 265: Preislisteneitrag__r.abrechenbar__c == "nach Abrechnungszeitraum" muss berücksichtigt werden!
//      geändert am 20.08.2014 durch WDS    ACR 267: Die Kundennr des Abrechners muss mit in Rechnungen__c geschrieben werden!
//      geändert am 25.01.2016 durch BT     #107705482 Das Feld Abrechnungsstatus_Krankenkasse__c wird auf "Abgerechnet über AS-B" gesetzt.
//      geändert am 29.01.2016 durch BT     Das Feld 'Geburtsdatum__c' wird durch das Feld 'Geburtsdatum_text__c' erstetzt

public with sharing class AB_KK_nur_anzeigen_controller_class {
        
        public List<Lieferscheinposition__c> LsPs = new List<Lieferscheinposition__c>();
        public List<Lieferscheinposition__c> LPall = new List<Lieferscheinposition__c>();
        public List<Preislisteneintrag__c> PLElistAr = new List<Preislisteneintrag__c>();
        public List<Preislisteneintrag__c> PLElistGr = new List<Preislisteneintrag__c>();
        public Map<string, string> mapArPLE = new Map<string, string>();
        public Map<string, string> mapAgPLE = new Map<string, string>();
        public Set<ID> setKK = new Set<ID>();
        public Set<ID> setAR = new Set<ID>();
        public Set<ID> setAG = new Set<ID>();
        public set<id> setLS = new set<id>();
        public List<Zeile> Zeilen = new List<Zeile>();
        public List<ZeileBKK> ZeilenBKK = new List<ZeileBKK>();

        public Map<String, Zeile> FPZeilen = new Map<String, Zeile>();
        public Map<String, ZeileBKK> FPZeilenBKK = new Map<String, ZeileBKK>();
        public Map<String, Rechnungsposition__c> FPRps = new Map<String, Rechnungsposition__c>();
        public List<Rechnungsposition__c> RPins = new List<Rechnungsposition__c>();
        
        public Summe ABSumme = new Summe();
        
        public Kunde__c Abrechnungsfirma;
        
        private Kunde__c Kunde;
        private  Anschrift__c Anschrift;
        
        public String Rechnungsnummer;
        
        public Integer zcount = 0;
        public Integer rcount = 0;
        public integer maxLines = 0;
        public integer maxLinesFirstPage = 22;
        public integer maxLinesNextPage = 40;
        public integer maxLinesLastPage = 22;
        private integer gesamtSeien = 0;
        private integer gesamtKunden = 0;
        private integer gesamtZeilen = 0;
        private boolean lastPage = false;
        
        
        public string kkName = ''; 
        public string kkstr = '';
        public string medifox = '';
        public boolean isInox = false;
        public boolean isMedifox = false;
        
        private Rechnung__c RG;
        public CompanyInfo__c FirmenInfo {get; set;}
        // Die Kundennummer beim Abrechner!
        public Decimal Kundennummer;
        
        public boolean sw = false;
        
        public string sNetto = '';
        public string sMW7 = '';
        public string sMW19 = '';
        public string sBrutto = '';
        public string sTotal = '';
        public string zuBerechnenderMonat = null;
        public string faelligAm = null;
        
        public class Zeile {
                public String Rpos {get;set;}
                public String PatientenName {get;set;}
                public String LsNr {get;set;}
                public String FP {get;set;}
                public String Artikel {get;set;}
                public Integer MwSt {get;set;}
                public string menge {get;set;}
                public string sMwSt {get;set;}
                public Decimal Endbetrag {get;set;}
                public string sEndbetrag {get;set;}
                public string seitenw {get;set;}
                public string th {get; set;}
                public string einheit {get; set;}
                public string ptype {get; set;}
                public boolean kdTopic {get; set;}
                public boolean az {get; set;}
                public boolean kk {get; set;}
                public boolean pos {get; set;}
                public boolean leer {get; set;}
                public boolean sum {get; set;}
                public string gbDat {get; set;}
                public string ikNummer {get; set;}
        }
        
        public class ZeileBKK {
                public String Nachname {get;set;}
                public String Vorname {get;set;}
                public String KV_Nummer {get;set;}
                public String Strasse {get;set;}
                public String Ort {get;set;}
                public String PLZ {get;set;}
                public Date Versorgungsbeginn {get;set;}
                public String Zustelldienst {get;set;}
                public String Auslieferungsnummer {get;set;}
        }
        
        public class Summe {
                
                public Summe(){
                        this.ANetto = 0;
                        this.ABrutto = 0;
                        this.AMwSt = 0;
                        this.BNetto = 0;
                        this.BBrutto = 0;
                        this.BMwSt = 0;
                }
                
                public Decimal ANetto {get;set;}
                public Decimal ABrutto {get;set;}
                public Decimal AMwSt {get;set;}
                public Decimal BBrutto {get;set;}
                public Decimal BNetto {get;set;}
                public Decimal BMwSt {get;set;}
                
                
        }
        
        public AB_KK_nur_anzeigen_controller_class() {
        }
        
        public AB_KK_nur_anzeigen_controller_class(ApexPages.StandardSetController lieferscheinpositionen){
                lieferscheinpositionen.setPageSize(30);
                // LsPs = lieferscheinpositionen.getRecords();
                kkName = ApexPages.CurrentPage().getParameters().get('kk');
                kkstr = ApexPages.CurrentPage().getParameters().get('kk');
                medifox = ApexPages.CurrentPage().getParameters().get('medifox');
                system.debug('###############Alex_000 kkstr=' + kkstr);
                
                if(medifox == 'yes') isMedifox = true;
                system.debug('###############Alex_002 medifox=' + medifox);
        }
        
        /*
        processAB_BKK
        ist für die erstellung der Excel-Datei die zur Abrechnung einer bestimmten Fallpauschalen-Art
        gedacht ist.
        macht zum teil das gleiche wie processAB_KK...
        */
        public PageReference processAB_BKK(){                
                return null;
        }
        
        // Alles befindet sich in dieser Funktion, da nur hier DML-Sachen durchgeführt werden können
        public PageReference processAB_KK(){
            FirmenInfo = CompanyInfo__c.getValues('Default');
            if (FirmenInfo != null) {
        //        if(FirmenInfo.GF__c.contains(', ')){
        //            String[] GF = FirmenInfo.GF__c.split(', ',2);
        //            FirmenInfo.GF__c = GF[0] + '<br />'+GF[1];
        //        }   
            }
            Kunde = [SELECT Name, Stra_e__c, Hausnummer__c, PLZ__c, Ort__c, Kundennummer__c, komb_Name__c,
                            Name__c, Vorname__c
                   FROM Kunde__c
                  WHERE Name = :AB_KK__c.getInstance('AB_KK_Einstellungen').Abrechnungsfirma__c]; 
                maxLines = maxLinesFirstPage;           
            
                Rechnung__c ABRechnung = new Rechnung__c(PDF_generiert__c = true);
                Abrechnungsfirma = [SELECT
                                            Name, Stra_e__c, Hausnummer__c, PLZ__c, Ort__c, Kundennummer__c
                                    FROM
                                            Kunde__c
                                    WHERE
                                            Name = :AB_KK__c.getInstance('AB_KK_Einstellungen').Abrechnungsfirma__c];
                ABRechnung.Kunde__c = Kunde.ID;
                ABRechnung.Buchungstext__c = 'KK-Abrechnungsbeleg';
                ABRechnung.Kundenkonto__c = string.ValueOf(Abrechnungsfirma.Kundennummer__c);
                insert ABRechnung;
                RG = [SELECT Name, PDF_generiert__c, CreatedBy.Name,  createddate 
                        FROM Rechnung__c 
                        WHERE Id = :ABRechnung.Id];
                Rechnungsnummer = RG.Name;

                Kundennummer = AB_KK__c.getInstance('AB_KK_Einstellungen').Kundennummer__c;

                RPins = new List<Rechnungsposition__c>();
                system.debug('############### Alex101 isMedifox=' + isMedifox); 
                Lieferscheinposition__c[] LPall = [SELECT
                                                      Lieferschein__c,
                                                      Lieferschein__r.Name,
                                                      Kunde__r.Name,
                                                      Kunde__c,
                                                      Auftragsposition__c,
                                                      Auftragsposition__r.Gesamtpreis__c,
                                                      Auftragsposition__r.Positionsart__c,
                                                      Auftragsposition__r.Auftrag__r.Fallpauschale__r.Name,
                                                      Auftragsposition__r.Auftrag__r.FP_abgerechnet_bis__c,
                                                      Auftragsposition__r.GenAnzVerp__c,
                                                      Auftragsposition__r.Auftrag__c,
                                                      Auftragsposition__r.Name,
                                                      Auftragsposition__r.Preis__c,
                                                      Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c,
                                                      Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Name,
                                                      Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.IK_Nummer__c,
                                                      Auftragsposition__r.Auftrag__r.Kunde__r.Geburtsdatum_text__c,
                                                      Auftragsposition__r.Auftrag__r.Kunde__r.Versichertennummer__c,
                                                      Artikel__c,
                                                      Artikel__r.a_pac_apo_Mwst__c,
                                                      Artikel__r.Artikelgruppe__c,
                                                      Artikel__r.Artikelgruppe__r.Name,
                                                      Artikel__r.Anlage_4_Preis__c,
                                                      Artikel__r.Einheit__c,
                                                      Menge__c,
                                                      VZ_von__c,
                                                      VZ_bis__c
                                                    FROM Lieferscheinposition__c                                                           
                    WHERE Abrechnungsstatus_Krankenkasse__c = 'abrechenbar'
                      AND Status__c != 'storniert' 
                      AND Unterschrift__c != false                                                                
                      AND Lieferschein__c != null
                      AND Auftragsposition__r.Auftrag__r.Fallpauschale__c = null
                      
                      AND Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.type != 'Sonstige'
                      AND Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Name LIKE: '%' + kkstr + '%'
                      AND Auftragsposition__r.Auftrag__r.Kunde__r.Medifox_2__c = :isMedifox
                 ORDER BY Kunde__c, Lieferschein__r.Name ASC
                 LIMIT 2000 ];
                // Die KK_Preise liegen entweder im Auftrag oder in der Auftragsposition
                // je nachdem ob Fallpauschale oder nicht
 
                system.debug('############### Alex001 LsPs.size() ' + LsPs.size()); 
                Set<ID> AuftragsposIDSet = new Set<ID>();
               
                // Die IDSets füllen
                id tempKdid = null;
                for (Lieferscheinposition__c LsP : LPall)
                {
                    if((tempKdid != LsP.Kunde__c) || (tempKdid == null)) {
                        // Kunde bedeutet 3 Zeilen
                        gesamtKunden++;
                    }
                    tempKdid = LsP.Kunde__c;
                    if(LsP.Auftragsposition__r.Positionsart__c != 'Anl4') {
                       AuftragsposIDSet.add(LsP.Auftragsposition__c);
                    }
                    setKK.add(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c);
                    setAR.add(lsp.Artikel__c);
                    setAG.add(lsp.Artikel__r.Artikelgruppe__c);  
                    setLS.add(lsp.Lieferschein__c);
                }
                gesamtZeilen = gesamtKunden + LPall.size();
                system.debug('#############alex901 LsPs.size()=' + LPall.size() + ' gesamtZeilen=' + gesamtZeilen);
                
                
                
                
                 list<Lieferbest_tigung__c> lbList = [SELECT id, Rechnung__c, Rechnungsname__c
                                FROM Lieferbest_tigung__c 
                                WHERE Lieferschein__c IN : setLS];
                 if ((lbList != null) && (lbList.size() > 0)) {
                     for(Lieferbest_tigung__c lb : lbList) {
                        lb.Rechnung__c = RG.id;
                        lb.Rechnungsname__c = Rechnungsnummer;                  
                     }
                     
                     update lbList;
                 }
                 
                 
                 PLElistAr = [SELECT id, Artikel__c, Krankenkasse__c, abrechenbar__c FROM Preislisteneintrag__c
                                WHERE Artikel__c IN :setAR
                                AND Krankenkasse__c IN :setKK];
                if ((PLElistAr != null) && (PLElistAr.size() > 0)) {
                        for(Preislisteneintrag__c ple : PLElistAr) {
                            string mKey = string.valueOf(ple.Artikel__c) + '_' + string.valueOf(ple.Krankenkasse__c);
                            mapArPLE.put(mKey, ple.abrechenbar__c);
                        }
                }
                PLElistGr = [SELECT id, Artikelgruppe__c, Krankenkasse__c, abrechenbar__c FROM Preislisteneintrag__c
                                WHERE Artikelgruppe__c IN :setAG
                                AND Krankenkasse__c IN :setKK];
                if ((PLElistGr != null) && (PLElistGr.size() > 0)) {
                        for(Preislisteneintrag__c ple : PLElistGr) {
                            string mKey = string.valueOf(ple.Artikelgruppe__c) + '_' + string.valueOf(ple.Krankenkasse__c);
                            mapAgPLE.put(mKey, ple.abrechenbar__c);
                        }
                }   
                             
                // KVA_Positionen holen und KK_Preis in Map schreiben
                KVA_Position__c[] KVA_Positionen = [SELECT Auftragsposition__c, KK_Preis__c        
                                                    FROM KVA_Position__c        
                                                    WHERE Auftragsposition__c IN :AuftragsposIDSet];
                                                            
                Map<ID, Decimal> Auftragspos_KK = new Map<ID, Decimal>();
                for(KVA_Position__c KVA_Pos : KVA_Positionen)
                {
                        Auftragspos_KK.put(KVA_Pos.Auftragsposition__c,KVA_Pos.KK_Preis__c);
                }
                
                
                // Zeilen für Abrechung erstellen (zusammenführung der ganzen DAten)
                // Außerdem erstellung der Rechnungspositionen
                Zeile lZeile = new Zeile();
                lZeile.Rpos = '. ';
                lZeile.sMwSt = ' ';
                lZeile.einheit = ' ';
                lZeile.th = 'color:white;border: white solid 1px;';
                lZeile.kdTopic = false;
                lZeile.az = false;
                lZeile.pos = false;
                lZeile.kk= false;
                lZeile.leer = true;
                lZeile.sum = false;
                
                Zeile hZeile = new Zeile();               
                hZeile.Rpos = 'Pos.';
                hZeile.PatientenName = 'Patientenname';
                hZeile.FP = 'Produkte';
                hZeile.einheit = 'Mengeneinheit';
                hZeile.menge = 'Menge';
                hZeile.LsNr = 'LS-Nr.';
                hZeile.sEndbetrag = 'Endbetrag';
                hZeile.th = 'font-weight:normal; border-bottom:black solid 1px;border-top:black solid 1px;';
                hZeile.az = false;
                hZeile.kdTopic = false;
                hZeile.az = false;
                hZeile.pos = true;
                hZeile.kk= false;
                hZeile.leer = false;                
                hZeile.sum = false;
                
                LsPs = lpSelektieren(LPall);
                tempKdid = null;
                integer curKunde = 0;
                // Zeilen.add(hZeile);
                for (Lieferscheinposition__c LsP : LsPs)
                {
                        if((tempKdid != LsP.Kunde__c) || (tempKdid == null)) {
                            Zeile tmpZeile = new Zeile();
                            curKunde++;                         
                            if((gesamtKunden > 2) && (gesamtZeilen > 20)) {
                                system.debug('#############alex901 curKunde=' + curKunde + ' gesamtKunden=' + gesamtKunden);
                                if(curKunde == (gesamtKunden )){
                                    system.debug('#############alex902 curKunde=' + curKunde + ' gesamtKunden=' + gesamtKunden);
                                    tmpZeile.seitenw = 'page-break-before:always;';
                                    lastPage = true;
                                }                               
                            }                           
                            tmpZeile.ptype = 'K';
                            tmpZeile.kdTopic = true;
                            tmpZeile.az = false;
                            tmpZeile.pos = false;
                            tmpZeile.kk= false;
                            tmpZeile.leer = false;
                            tmpZeile.sum = false;
                            tmpZeile.PatientenName = LsP.Kunde__r.Name;
                            tmpZeile.gbDat = '01.01.0001';
                            if(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Geburtsdatum_text__c != null) {
                                tmpZeile.gbDat = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Geburtsdatum_text__c;
                            }
                            tmpZeile.FP = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Versichertennummer__c;
                            tmpZeile.ikNummer = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.IK_Nummer__c;
                            tmpZeile.th = 'border-bottom: black solid 2px;';
                            Zeilen.add(tmpZeile);
                            
                            Zeile azZeile = new Zeile();
                            azZeile.ptype = '';
                            azZeile.az = true;
                            azZeile.kdTopic = false;
                            azZeile.pos = false;
                            azZeile.kk= false;
                            azZeile.leer = false;
                            azZeile.sum = false;
                            azZeile.PatientenName = 'Abrechnungszeitraum:';
                            string azVon = '01.01.0001';
                            string azBis = '01.01.0001';
                            if(LsP.VZ_von__c != null) {
                                azVon = LsP.VZ_von__c.format(); 
                            }
                            if(LsP.VZ_bis__c != null) {
                                azBis = LsP.VZ_bis__c.format(); 
                            }
                            azZeile.FP = azVon + ' - ' + azBis;
                            
                            Zeilen.add(azZeile);
                            zcount++;
                            zcount++;
                            zcount++;
                            zcount++;
                            Zeile kkZeile = new Zeile();
                            kkZeile.ptype = '';
                            kkZeile.az = false;
                            kkZeile.kdTopic = false;
                            kkZeile.pos = false;
                            kkZeile.kk= true;
                            kkZeile.leer = false;   
                            kkZeile.sum = false;
                            kkZeile.FP = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Name;
                            kkZeile.PatientenName = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.IK_Nummer__c;
                            Zeilen.add(kkZeile);
                            zcount++;
                            
                            rcount = 0;
                            Zeilen.add(hZeile);
                        }
                        tempKdid = LsP.Kunde__c;
                        
                        if(zuBerechnenderMonat == null) {
                            if(LsP.VZ_von__c != null) {
                                zuBerechnenderMonat = ksgFunctions.getMonat(LsP.VZ_von__c.month()) + ' ' + string.valueOf(LsP.VZ_von__c.year());
                            }
                            else {
                                if(LsP.VZ_bis__c != null) {
                                    zuBerechnenderMonat = ksgFunctions.getMonat(LsP.AZ_bis__c.month()) + ' ' + string.valueOf(LsP.AZ_bis__c.year());
                                }
                            }
                            
                        }
                        Zeile tmpZeile = new Zeile();
                        tmpZeile.ptype = 'P';
                        tmpZeile.kdTopic = false;
                        tmpZeile.az = false;
                        tmpZeile.pos = true;
                        tmpZeile.kk= false;
                        tmpZeile.leer = false;
                        tmpZeile.sum = false;
                        tmpZeile.th = 'border-bottom: black solid 1px;';
                        tmpZeile.LsNr = LsP.Lieferschein__r.Name;
                        tmpZeile.einheit = LsP.Artikel__r.Einheit__c;
                        tmpZeile.menge = string.valueOf(LsP.Menge__c);
                        // tmpZeile.PatientenName = LsP.Kunde__r.Name;
                         if((LsP.Auftragsposition__r.Positionsart__c == 'Anl4') || (LsP.Auftragsposition__r.Positionsart__c == 'privat')){
                            tmpZeile.FP = 'Anl4';
                            tmpZeile.FP = LsP.Artikel__r.Artikelgruppe__r.Name;
// ACR 266                           tmpZeile.Endbetrag = LsP.Auftragsposition__r.Gesamtpreis__c/LsP.Auftragsposition__r.GenAnzVerp__c*LsP.Menge__c;
                              tmpZeile.Endbetrag = LsP.Artikel__r.Anlage_4_Preis__c*LsP.Menge__c;
                              // tmpZeile.Endbetrag = Lsp.Auftragsposition__r.Preis__c;
                        } else {
                                tmpZeile.FP = '';
                                decimal Betrag = 0;

                                if(Auftragspos_KK.containsKey(LsP.Auftragsposition__c)) {
                                Betrag = Auftragspos_KK.get(LsP.Auftragsposition__c)/LsP.Auftragsposition__r.GenAnzVerp__c*LsP.Menge__c;
                                } 
                                tmpZeile.Endbetrag = Betrag;
                        }
                        if(tmpZeile.Endbetrag == null){
                                tmpZeile.Endbetrag = 0;
                        }
                        
                        Rechnungsposition__c tmpRP = new Rechnungsposition__c();
                        tmpRP.Lieferscheinposition__c = LsP.id;
                        tmpRP.Gesamtpreis_Brutto__c = tmpZeile.Endbetrag;
                        tmpRP.Kunde__c = Abrechnungsfirma.Id;
                        tmpRP.Rechnung__c = ABRechnung.Id;
                        tmpRP.Positionstext__c = tmpZeile.LsNr + ' ' + tmpZeile.PatientenName;
                        
                        // hier evtl mit den benutzerdefinierten Einstellungen aus MWSt Liste arbeiten!?
                        if(LsP.Artikel__r.a_pac_apo_Mwst__c == '1' ){
                                tmpZeile.MwSt = 19;
                                tmpRP.MWSt_Prozentsatz__c = '19.0 %';
                                tmpRP.MWSt1__c = tmpZeile.Endbetrag/1.19*0.19;
                        } else if(LsP.Artikel__r.a_pac_apo_Mwst__c == '2'){
                                tmpZeile.MwSt = 7;
                                tmpRP.MWSt_Prozentsatz__c = '7.0 %';
                                tmpRP.MWSt2__c = tmpZeile.Endbetrag/1.19*0.07;
                        } else {
                                // Sollte ein Artikel kein a_pac_apo_Mwst definiert haben, was soll dann genommen werden?!!?
                                tmpZeile.MwSt = 0;
                        }
                        tmpZeile.sMwSt = string.valueOf(tmpZeile.MwSt) + ' %';
                        tmpZeile.sEndbetrag = ksgFunctions.formatCurrency(tmpZeile.Endbetrag) + ' €';
                        if (tmpZeile.Endbetrag > 0) {
                            if (zcount == 0) {
                                    
                                if (maxLines == maxLinesNextPage) {
                                    Zeilen.add(lZeile);
                                    Zeilen.add(lZeile);
                                    Zeilen.add(lZeile);
                                    Zeilen.add(lZeile);
                                    Zeilen.add(lZeile);
                                }
                                Zeilen.add(hZeile);
                                
                            }
                            zcount++;
                            system.debug('#############alex101 LsPs.size()=' + LsPs.size() + ' zcount=' + zcount + ' maxLines=' + maxLines);
                            if(zcount == maxLines ) {
                                system.debug('#############alex102 LsPs.size()=' + LsPs.size() + ' zcount=' + zcount + ' maxLines=' + maxLines);
                                maxLines = maxLinesNextPage;
                                if(!lastPage) tmpZeile.seitenw = 'page-break-after:always;';
                                tmpZeile.th = 'border-bottom: black solid 1px;';
                                zcount = 0;
                            }
                            rcount++;                           
                            tmpZeile.Rpos = string.valueOf(rcount);
                            Zeilen.add(tmpZeile);
                            
                            //insert tmpRP;
                            RPins.add(tmpRP);
                        }
                        
                }
                
                
                if(RPins.size() > 0) {
                    insert RPins;                   
                }

                
                // Berechnung der Summen, die am Ende der Tabelle angezeigt werden
                // Die Liste Zeilen wird durchlaufen, da diese auch die sind, die am Ende
                // auf dem Beleg erscheinen
                for(Zeile Z : Zeilen){
                        if(Z.MwSt == 7){
                                ABSumme.AMwSt += Z.Endbetrag/1.07*0.07;
                                ABSumme.ANetto += Z.Endbetrag/1.07;
                                ABSumme.ABrutto += Z.Endbetrag;
                        }
                        if(Z.MwSt == 19){
                                ABSumme.BMwSt += Z.Endbetrag/1.19*0.19;
                                ABSumme.BNetto += Z.Endbetrag/1.19;
                                ABSumme.BBrutto += Z.Endbetrag;
                        }
                        if(Z.MwSt == 0){
                                ABSumme.BNetto += Z.Endbetrag;
                                ABSumme.BBrutto += Z.Endbetrag;
                        }
                }
                sNetto = ksgFunctions.formatCurrency(ABSumme.ANetto + ABSumme.BNetto);
                sBrutto = ksgFunctions.formatCurrency(ABSumme.ABrutto + ABSumme.BBrutto);
                sMW7 = ksgFunctions.formatCurrency(ABSumme.AMwSt);
                sMW19 = ksgFunctions.formatCurrency(ABSumme.BMwSt);
                
                Zeile endZeile = new Zeile(); 
                endZeile.th = 'border-top: black solid 2px;font-weight:bold;';
                
                endZeile.FP = 'Gesamt-Brutto-Wert';
                endZeile.sEndbetrag = sBrutto + ' €';
                endZeile.kdTopic = false;
                endZeile.az = false;
                endZeile.pos = false;
                endZeile.kk= false;
                endZeile.leer = false;
                endZeile.sum = true;
                Zeilen.add(endZeile);
                Zeilen.add(lZeile);
                Zeile mwstZeile = new Zeile(); 
                mwstZeile.kdTopic = false;
                mwstZeile.az = false;
                mwstZeile.pos = false;
                mwstZeile.kk= false;
                mwstZeile.leer = false;
                mwstZeile.sum = true;
                mwstZeile.th = 'color: #666666;font-size:11px;';
                mwstZeile.FP = 'Enthaltene Mehrwertsteuer 19%';
                mwstZeile.sEndbetrag = sMW19 + ' €';
                Zeilen.add(mwstZeile);
                Map<ID,Auftrag__c> AUToUpdate = new Map<ID,Auftrag__c>();
                for (Lieferscheinposition__c LsP : LsPs)
                {
                    //LsP.Abrechnungsstatus_Krankenkasse__c = 'abgerechnet';       
                    LsP.Abrechnungsstatus_Krankenkasse__c = 'Abgerechnet über AS-B';               
                }
                ApexPages.StandardSetController lieferscheinpositionen = new ApexPages.StandardSetController(LsPs);
                
                lieferscheinpositionen.save();
                update AUToUpdate.values();
                
                return null;
        }
        
        public List<Zeile> getZeilen(){
                return Zeilen;
        }
        
        public List<ZeileBKK> getZeilenBKK(){
                system.debug('############# getzeilenbkk' + ZeilenBKK);
                return ZeilenBKK;
        }
        
        public Summe getABSumme(){
                return ABSumme;
        }
        
        public String getSnetto() {
            return sNetto;
        }
        
        public String getSBrutto() {
            return sBrutto;
        }
        
        
        public String getStotal() {
            return sTotal;
        }
        
        public String getSMW7() {
            return sMW7;
        }
        
        public String getSMW19() {
            return sMW19;
        }
        
        public String getRechnungsnummer(){
                return Rechnungsnummer;
        }
        
        
        public Kunde__c getAbrechnungsfirma(){
                system.debug('############ '+ Abrechnungsfirma);
                return Abrechnungsfirma;
        }
        
        public Decimal getKundennummer(){
                return Kundennummer;
        }
        
        public boolean getSW(){
                return sw;
        }
        
        public Rechnung__c getRG()
        {
            if(ApexPages.currentPage().getParameters().get('inox') == '1'){
                RG.PDF_generiert__c = false;
            }
        return RG;
        }
        
        
    public CompanyInfo__c getFirmenInfo(){
        return FirmenInfo;
    }

    public Kunde__c getKunde() 
        {
            return Kunde;
        }
   
     public List<Lieferscheinposition__c> lpSelektieren(List<Lieferscheinposition__c> lpi) {
        List<Lieferscheinposition__c> lpo = new List<Lieferscheinposition__c>();
        date Heute = date.Today();
        for (Lieferscheinposition__c LsP : lpi) {
            string aKey = string.valueOf(LsP.Artikel__c) + '_' + string.valueOf(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c);
            string gKey = string.valueOf(LsP.Artikel__r.Artikelgruppe__c) + '_' + string.valueOf(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c);
            string ple_abr = mapArPLE.get(aKey);
            if (ple_abr == null) {
                ple_abr = mapAgPLE.get(gKey);
            }
            if (ple_abr == 'nach Abrechnungszeitraum') {
                if(LsP.AZ_bis__c <= Heute) {
                    lpo.add(LsP);
                }
            } else{
                lpo.add(LsP);
            }            
        }
        return lpo;
    }

    public boolean getIsMedifox() {
        return isMedifox;
    }
    
    public string getzuBerechnenderMonat() {
        return zuBerechnenderMonat;
    }
    
    public string getfaelligAm() {
        string fa = datetime.now().addMonths(1).format('dd.MM.yyyy');
        
        return fa;
    }
   
  // wird nicht aufgerufen! Nur für Testabdeckung!!!  
        public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;} 
                        public string th {get; set;}
                        public string thu {get; set;}
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
                            
          
        }        
        
        // wird nicht aufgerufen! Nur für Testabdeckung!!!       
        public void setLeereZeilen2() {
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
                            
          
        }        
        
         // wird nicht aufgerufen! Nur für Testabdeckung!!!       
        public void setLeereZeilen3() {
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
                            
          
        }        
}