/****************************************************************************************************************************
// Erstellt 10.02.2015 von AM
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
// KdID
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Soll BarVerkaufWizardController ersetzen
// 
//****************************************************************************************************************************
//Änderungen:
//  02.04.2015 von AM: Sortierung von Einmalhandschuhe (Mantis 87)
//  09.04.2015 von WDS: Anzeige des Genehmigungsstatusses im Auftrag angepaßt
//  22.04.2015 von AM:  Prüfen auf GenMenge = 0. Wenn ja - keine Genehmigung
//                      Wenn curabox editierbar - soll er Auswählbar sein aber nur die genehmigten Positionen
//                      Wenn nicht editirbar - nicht Auswählbar.
//
//  09.07.2015  vin AM Anpassen an pg51
//
// 25.08.2015 #100636896. Kundenstatus
// 03.09.2015 #102591248. Artikelgruppe mit "keine Genehmigungspflicht"
// 29.03.2016 Genehmigung in "jetzt liefern" auf Datum_bis prüfen.
// 02.06.2016 AM : Wenn >1 Genehmigung wurde beim dem neuen Auftrag das alte Datum gen_bis genommen          
// 04.12.2017   AM      #153054057 Bei Anträgen ohne Enddatum wird das Jahr heute + 100 Jahre   
//****************************************************************************************************************************
*/

public with sharing class box_method {
    private list<Pflegebox__c> festBoxList = new list<Pflegebox__c>();
    private list<SelectOption> BoxSelect {get; set;} 
    private list<Artikel__c> arList {get; set;} 
    private id selectedBox = null;
    private string selectedBoxName {get; set;} 
    private id selectedArtikel = null;
    private id selectedGr = null;
    private id KdID = null;
    
    private list<VPflegeboxArtikelgruppe__c> pbAgList {get; set;}
    private decimal gesamtPreis {get; set;}
    private string gesamtPreisFarbe {get; set;}
    private decimal gesamtPreisEdit {get; set;}
    private string gesamtPreisFarbeEdit {get; set;}
    private list<PflegeboxSettings__c> pbset {get;set;}
    private decimal maxprice {get;set;}
    private decimal minprice {get;set;}
    public Auftrag__c nAU = new Auftrag__c();
    
    private map<id, Pflegebox__c> pbMap = new map<id, Pflegebox__c>();
    private string KdHanschueGr {get; set;}
    private id  KdHanschueId = null;
    
    private boolean einmalig = false;
    private boolean rLieferung = false;
    private integer rlMultiplikator = 1;
    public string muTxt = null;
    
    private date boxGenehmigtAb {get; set;}
    private date boxGenehmigtBis {get; set;}
    private boolean boxGenehmigtUnbefristet {get; set;}
    private boolean editierbar = false;
    private boolean kandidat = false;
    private boolean kandidat51 = false;
    
    // public Map<String, Schema.RecordTypeInfo> auRecordTypeInfo = Schema.SObjectType.Auftrag__c.getDescribe().getRecordTypeInfosByName();
    
    private class pbAgGn {
        public String agrp {get;set;}
        public id agID {get;set;}
        public id genID {get;set;}
        public String nach_paragraph {get;set;} 
        public String menge {get;set;}  
        public decimal bmenge {get;set;}            
        public String genbis {get;set;}
        public String genab {get;set;}
        public String genStatus {get;set;}
        public String genmenge {get;set;}
        public String genstyle {get;set;}
        public map<id, Artikel__c> arMap {get; set;}
        public list<SelectOption> artikelSelect {get; set;}
        public id selectedArtikel {get; set;}
        public decimal preis {get; set;}
        public decimal pospreis {get; set;}
        public boolean editierbar {get; set;} 
        public boolean nur_einmalig_bestellbar = false; 
        public id apID {get; set;}
        public string apName {get; set;}
        public boolean keineGenehmigung = false;
        public boolean keine_genehmigungspflicht = false; 
        public decimal genMg {get; set;}
        
        public boolean getkeineGenehmigung() {
            return keineGenehmigung;
        }

        public boolean getNur_einmalig_bestellbar() {
            return nur_einmalig_bestellbar;
        }    

        public boolean getKeine_genehmigungspflicht() {
            return keine_genehmigungspflicht;
        }
        
        public boolean geteditierbar() {
            return editierbar;
        }
    }
    public boolean nur_einmalig_bestellbar = false; 
    private list<pbAgGn> pbAgGnList {get; set;}
    private list<pbAgGn> pbAgGnListEdit {get; set;}

    
    private boolean boxKeineGenehmigung = false;
    private boolean boxError = false;
    private string errorMessage {get; set;}

    // dummy constructor
    public box_method(string dummy) {
    }
    
    public box_method() {
        festBoxList = lesenBox();
        initPB();
    }
    
    public box_method(ID KdID) {
        this.KdID = KdID;
        string boxName = 'Anl4_Stückliste';
        system.debug('############################alex301 KdID=' + KdID);
        try {
            boxName = Anl4_Stueckliste__c.getInstance('Name').Bezeichnung__c;
        }
        catch(system.exception e) {
            boxError = true;
            errorMessage = 'Keine ' + boxName + ' Name gefunden.';
            system.debug('############################alex400 errorMessage=' + errorMessage);
        } 
       
        if(!boxError) {
          try {
            pbset = PflegeboxSettings__c.getall().values();
          maxprice = pbset[0].MaxPreis__c;
          minprice = pbset[0].MinPreis__c;   
          }
          catch (system.exception e) {
            boxError = true;
            errorMessage = 'Keine ' + boxName + '-Einstellungen gefunden.';
            system.debug('############################alex401 errorMessage=' + errorMessage);
          }
          if(!boxError) {
            this.selectedBox = wunschbox(KdID);
            system.debug('############################alex302 selectedBox=' + selectedBox);
            festBoxList = lesenBox();       
            system.debug('############################alex303 festBoxList.size()=' + festBoxList.size());
            if(festBoxList.size() > 0) {          
              initPB();
            }
            else {
              boxError = true;
              errorMessage = 'Keine ' + boxName + ' gefunden.';          
            }
          }
      }
    }
    
    public boolean hasError() {
      return boxError;
    }
    
    public string getErrorMessage() {
      return errorMessage;     
    }
    
    public void initPB() {
        BoxSelect = fillBoxSelect(festBoxList);
        pbAgGnList = createPbAgGnList();        
    }

    private id wunschbox(id KdID) {
        id wBox = null;
        list<Kunde__c> kdList = [SELECT Wunschbox__c, Gr_e_Einmalhandschuhe__c, bevorzugter_Art_f_r_Einmalhandsch__c
                                    FROM Kunde__c WHERE id = :KdID ];
        if((kdList != null) && (kdList.size() > 0)) {
            wBox = kdList[0].Wunschbox__c;
            // if(kdList[0].Status__c == 'Kandidat') kandidat = true;
            KdHanschueGr = '--' + kdList[0].Gr_e_Einmalhandschuhe__c + '--';
            if(kdList[0].bevorzugter_Art_f_r_Einmalhandsch__c != null) {
                KdHanschueId = kdList[0].bevorzugter_Art_f_r_Einmalhandsch__c;
            }
        }
        list<Kundenstatus__c> ksList = [SELECT id, Status__c, Produktgruppe__c 
                                            FROM Kundenstatus__c 
                                            WHERE Kunde__c = :KdID];
        if((ksList != null) && (ksList.size() > 0)) {
            for(Kundenstatus__c ks : ksList) {
                if((ks.Status__c == 'Kandidat') && (ks.Produktgruppe__c == 'PG54')) kandidat = true;
                if((ks.Status__c == 'Kandidat') && (ks.Produktgruppe__c == 'PG51')) kandidat51 = true;
            }
        }
        
        return wBox;
    }
    
    private list<Pflegebox__c> lesenBox() {
        list<Pflegebox__c> festBoxList = [SELECT id, Name, nur_einmalig_bestellbar__c, editierbar__c
                                            FROM Pflegebox__c                                            
                                            ORDER BY Name];
        return festBoxList;
    }
    
    private list<SelectOption> fillBoxSelect(list<Pflegebox__c> pbl) {
        List<SelectOption> options = new List<SelectOption>();
        for(Pflegebox__c pb : pbl) {
            pbMap.put(pb.id, pb);
            options.add(new SelectOption(pb.id, pb.name));          
            if(selectedBox == null) selectedBox = pb.id;
            if(selectedBox == pb.id) selectedBoxName = pb.Name;
        }
        return options;
    }
    
    private list<pbAgGn> createPbAgGnList() {
        system.debug('############################alex601 selectedBox=' + selectedBox);
        id gen_id = null;
        
        if(einmalig) {
            nur_einmalig_bestellbar = true;
        }
        else {
            nur_einmalig_bestellbar = pbMap.get(selectedBox).nur_einmalig_bestellbar__c;
        }
        editierbar = pbMap.get(selectedBox).editierbar__c;
        list<pbAgGn> pbAgGnList = new list<pbAgGn>();
        set<id> agIDset = new set<id>();
        boxKeineGenehmigung = false;
        map<id, Genehmigungsposition__c> gpMap = new map<id, Genehmigungsposition__c>();
        
        pbAgList = lesenPbArtikelgruppen(selectedBox);
        for(VPflegeboxArtikelgruppe__c vpa : pbAgList) {
            agIDset.add(vpa.Artikelgruppe__c);
        }
        system.debug('############################alex602 agIDset=' + agIDset);
        arList = [SELECT id, Name, Artikelgruppe__c, Anlage_4_Preis__c, Standardartikel_f_r_Pflegeboxen__c, v_pos_1_Name__c
                            FROM Artikel__c 
                            WHERE Artikelgruppe__c IN : agIDset
                            ORDER BY Sortierung__c ASC NULLS LAST];

                        
        
        list<Genehmigungsposition__c> gpList = [SELECT id, Artikelgruppe__c, genehmigt_ab__c, genehmigt_bis__c, unbefristet_genehmigt__c, 
                                                        Gen_Menge_Stk_Mon__c, Genehmigung__r.Genehmigungsstatus__c, Genehmigung__r.Status__c,
                                                        Genehmigung__c
                                                FROM Genehmigungsposition__c
                                                WHERE Genehmigung__r.Kunde__c = :KdID
                                                AND Genehmigung__r.Status__c IN ('Bewilligung', 'Teilbewilligung')
                                                AND (genehmigt_bis__c = null OR genehmigt_bis__c >= :date.TODAY())
                                                AND Artikelgruppe__c IN : agIDset
                                                ORDER BY Genehmigung__r.CreatedDate DESC];
        if((gpList != null) && ( gpList.size() > 0)) {
            // 02.06.2016 
            id lastGenID = gpList[0].Genehmigung__c;
            
            for (Genehmigungsposition__c gp : gpList) {
                if(gen_id == null) gen_ID = gp.Genehmigung__c;
                if(! gpMap.containsKey(gp.Artikelgruppe__c)) gpMap.put(gp.Artikelgruppe__c, gp);
                if ((gp.genehmigt_bis__c != null) && (gp.Genehmigung__c == lastGenID))  {
                    if((boxGenehmigtBis == null) || (boxGenehmigtBis > gp.genehmigt_bis__c)) {                       
                            boxGenehmigtBis = gp.genehmigt_bis__c;
                    }
                }
            }
        }
    system.debug('############################alex603 gpMap.size()=' + gpMap.size());
        
        
        for(VPflegeboxArtikelgruppe__c vpa : pbAgList) {
            date Heute = date.today();
            pbAgGn zeilePbAgGn = new pbAgGn();
            zeilePbAgGn.genID = gen_ID;
            zeilePbAgGn.keine_genehmigungspflicht = vpa.Artikelgruppe__r.keine_Genehmigungspflicht__c;
            zeilePbAgGn.nach_paragraph = vpa.Artikelgruppe__r.Positionsnummer__c;
            zeilePbAgGn.agrp = vpa.Artikelgruppe__r.Name;
            zeilePbAgGn.bmenge = vpa.Standartanzahl__c;
            if(zeilePbAgGn.bmenge == null) zeilePbAgGn.bmenge = 0;
            
            zeilePbAgGn.agID = vpa.Artikelgruppe__c;
            zeilePbAgGn.genstyle = 'color:black;';
            zeilePbAgGn.editierbar = editierbar;
            if(vpa.Artikelgruppe__r.keine_Genehmigungspflicht__c) {
                zeilePbAgGn.editierbar = true;
            }
    
            if(gpMap.containsKey(vpa.Artikelgruppe__c)) {
                
                decimal genMg = gpMap.get(vpa.Artikelgruppe__c).Gen_Menge_Stk_Mon__c;
                zeilePbAgGn.genmenge = string.valueOf(genMg);
                zeilePbAgGn.genMg = genMg;
                system.debug('############################alex604 genMg=' + genMg);
            // gen ab
                if(gpMap.get(vpa.Artikelgruppe__c).genehmigt_ab__c !=  null) {
                    if((boxGenehmigtAb == null) || (boxGenehmigtAb < gpMap.get(vpa.Artikelgruppe__c).genehmigt_ab__c)) {
                        boxGenehmigtAb = gpMap.get(vpa.Artikelgruppe__c).genehmigt_ab__c;
                    }
                    boxGenehmigtAb = gpMap.get(vpa.Artikelgruppe__c).genehmigt_ab__c;
                    zeilePbAgGn.genab = gpMap.get(vpa.Artikelgruppe__c).genehmigt_ab__c.format();
                    system.debug('############################alex605 zeilePbAgGn.genab=' + zeilePbAgGn.genab);
                    zeilePbAgGn.genStatus = 'Bewilligung ab ' + zeilePbAgGn.genab + ' über ' + gpMap.get(vpa.Artikelgruppe__c).Gen_Menge_Stk_Mon__c ;                  
                } else zeilePbAgGn.keineGenehmigung = true;
                
                if (!zeilePbAgGn.keineGenehmigung) {
                  system.debug('############################alex606 zeilePbAgGn.keineGenehmigung=' + zeilePbAgGn.keineGenehmigung);
                // unbefristet
                    if(gpMap.get(vpa.Artikelgruppe__c).unbefristet_genehmigt__c) {
                        zeilePbAgGn.genStatus = zeilePbAgGn.genStatus + ' liegt unbefristet vor!';                         
                        boxGenehmigtUnbefristet = true;
                    }
                    else {
                        if(gpMap.get(vpa.Artikelgruppe__c).genehmigt_bis__c != null) {                          
                            
                        // gen bis 
                            if(gpMap.get(vpa.Artikelgruppe__c).genehmigt_bis__c >= Heute) {
                        // Menge mit andrucken!    und text rot, wenn ab > heute                            
                                zeilePbAgGn.genStatus =  'Bewilligung ab ' + zeilePbAgGn.genab +' bis ' + gpMap.get(vpa.Artikelgruppe__c).genehmigt_bis__c.format()+ ' über ' + gpMap.get(vpa.Artikelgruppe__c).Gen_Menge_Stk_Mon__c + ' liegt vor';
                                if(gpMap.get(vpa.Artikelgruppe__c).genehmigt_ab__c > Heute) {                       
                                  zeilePbAgGn.genstyle = 'color:#ff0000;';
                                }
                            } else zeilePbAgGn.keineGenehmigung = true;
                        }  else zeilePbAgGn.keineGenehmigung = true;
                    }
                }
                
                if((gpMap.get(vpa.Artikelgruppe__c).Gen_Menge_Stk_Mon__c == null) 
                    || (gpMap.get(vpa.Artikelgruppe__c).Gen_Menge_Stk_Mon__c == 0)) {
                        zeilePbAgGn.keineGenehmigung = true;
                    }
                if(zeilePbAgGn.genMg < zeilePbAgGn.bmenge) {
                    if(!zeilePbAgGn.editierbar) {
                        boxKeineGenehmigung = true;
                        zeilePbAgGn.genstyle = 'color:#ff0000;';  
                    }
                }
            }
            else {
                zeilePbAgGn.keineGenehmigung = true;
            }
            
            
            system.debug('############################alex607 zeilePbAgGn.keineGenehmigung=' + zeilePbAgGn.keineGenehmigung);
            if (zeilePbAgGn.keineGenehmigung && !zeilePbAgGn.keine_genehmigungspflicht) {
                if(boxKeineGenehmigung == false) boxKeineGenehmigung = true;
                zeilePbAgGn.genStatus = 'es liegt keine Genehmigung vor.';
                if((kandidat) && (zeilePbAgGn.nach_paragraph == '54'))  {
                    zeilePbAgGn.genStatus = 'Kandidat';
                    if(editierbar) { 
                        boxKeineGenehmigung = false;
                        zeilePbAgGn.keineGenehmigung = false;
                    }
                }
                if((kandidat51) && (zeilePbAgGn.nach_paragraph == '51'))  {
                    zeilePbAgGn.genStatus = 'Kandidat';
                    if(editierbar) { 
                        boxKeineGenehmigung = false;
                        zeilePbAgGn.keineGenehmigung = false;
                    }
                }               
                zeilePbAgGn.genstyle = 'color:#ff0000;';                
            }
            
            if (zeilePbAgGn.keineGenehmigung && zeilePbAgGn.keine_genehmigungspflicht) { 
                zeilePbAgGn.genStatus = 'keine Genehmigungspflicht';
            }
            // 
            


            zeilePbAgGn.arMap = getArtikelProGruppe(vpa.Artikelgruppe__c);
            // zeilePbAgGn.artikelSelect = selectArtikelProGruppe(vpa.Artikelgruppe__c, zeilePbAgGn);
            system.debug('############################alex001 selectedGr ' + selectedGr);
            fillArtikelProGruppe(vpa.Artikelgruppe__c, zeilePbAgGn);
            pbAgGnList.add(zeilePbAgGn);
        }
        
        return pbAgGnList;
    }
    
    public boolean checkGenMenge() {
        boolean mgOK = false;
        for(PbAgGn satz : PbAgGnList) {
            if(satz.agID == selectedGr) {
                system.debug ('##################################alex111 satz.bmenge=' + satz.bmenge);
                system.debug ('##################################alex111g satz.genMg=' + satz.genMg); 
                if(satz.genMg >= satz.bmenge) mgOK = true;
            }   
        }       
        return mgOK;
    }
    
    public void recreatePbAgGnList() {
        system.debug ('##################################alex112 ');
        decimal gesPreis = 0.00;
        for(PbAgGn satz : PbAgGnList) {
            if(satz.agID == selectedGr) {
                system.debug ('##################################alex111 satz.bmenge=' + satz.bmenge);
                system.debug ('##################################alex111g satz.genMg=' + satz.genMg);
                satz.preis = satz.arMap.get(satz.selectedArtikel).Anlage_4_Preis__c;
                satz.pospreis = satz.arMap.get(satz.selectedArtikel).Anlage_4_Preis__c * satz.bmenge;               
            }   
                gesPreis += satz.pospreis;
        }

        gesamtPreis = gesPreis;
    }
    
    public void recreatePbAgGnListEdit() {
        system.debug ('##################################alex112 ');
        decimal gesPreis = 0.00;
        for(PbAgGn satz : PbAgGnListEdit) {
            if(satz.agID == selectedGr) {
                system.debug ('##################################alex111 satz.bmenge=' + satz.bmenge);
                satz.preis = satz.arMap.get(satz.selectedArtikel).Anlage_4_Preis__c;
                satz.pospreis = satz.arMap.get(satz.selectedArtikel).Anlage_4_Preis__c * satz.bmenge;               
            }   
                gesPreis += satz.pospreis;
        }

        gesamtPreisEdit = gesPreis;
    }
    
    private list<pbAgGn> fillPbAgGnListEdit(Auftrag__c AU) {
        selectedBox = id.valueOf(AU.Auftrag_text__c);
        boolean editierbar = pbMap.get(selectedBox).editierbar__c;
        if(einmalig) {
            nur_einmalig_bestellbar = true;
        }
        else {
            nur_einmalig_bestellbar = pbMap.get(selectedBox).nur_einmalig_bestellbar__c;
        }
        list<pbAgGn> pbAgGnList = new list<pbAgGn>();
        set<id> agIDset = new set<id>();
        map<id, Auftragsposition__c> selArtMap = new map<id, Auftragsposition__c>();
        map<id, Genehmigungsposition__c> gpMap = new map<id, Genehmigungsposition__c>();
        
        pbAgList = lesenPbArtikelgruppen(selectedBox);
        for(VPflegeboxArtikelgruppe__c vpa : pbAgList) {
            agIDset.add(vpa.Artikelgruppe__c);
        }
        system.debug('############################alex501 agIDset ' + agIDset);
        arList = [SELECT id, Name, Artikelgruppe__c, Anlage_4_Preis__c, Standardartikel_f_r_Pflegeboxen__c
                            FROM Artikel__c 
                            WHERE Artikelgruppe__c IN : agIDset 
                            ORDER BY Sortierung__c ASC NULLS LAST];
                            
        list<Genehmigungsposition__c> gpList = [SELECT id, Artikelgruppe__c, genehmigt_ab__c, genehmigt_bis__c, unbefristet_genehmigt__c, 
                                                        Gen_Menge_Stk_Mon__c, Genehmigung__r.Genehmigungsstatus__c, Genehmigung__r.Status__c
                                                FROM Genehmigungsposition__c
                                                 WHERE Genehmigung__r.Kunde__c = :KdID
                                                AND Genehmigung__r.Status__c IN ('Bewilligung', 'Teilbewilligung')
                                                AND Artikelgruppe__c IN : agIDset
                                                ORDER BY Genehmigung__r.CreatedDate DESC];
                                                
        if((gpList != null) && ( gpList.size() > 0)) {
            for (Genehmigungsposition__c gp : gpList) {
                if(!gpMap.containsKey(gp.Artikelgruppe__c)) gpMap.put(gp.Artikelgruppe__c, gp);
            }
        }
        system.debug('############################alex502 gpMap.size() ' + gpMap.size());

        list<Auftragsposition__c> APlist = [SELECT  id, Name, Kunde__c, Artikel__c, Artikel__r.Artikelgruppe__c,
                                                    Gen_Menge_Stk_Mon__c, Auftrag__c,
                                                    genehmigt_ab__c, genehmigt_bis__c, Lieferzeitraum__c,
                                                    Positionsart__c, Preis__c
                                            FROM Auftragsposition__c 
                                            WHERE Auftrag__c = :AU.id];
        if((APlist != null) && (APlist.size() > 0)) {
            for(Auftragsposition__c AP : APlist) {
                selArtMap.put(AP.Artikel__r.Artikelgruppe__c, AP);
            }
        }
        
       for(VPflegeboxArtikelgruppe__c vpa : pbAgList) {
            pbAgGn zeilePbAgGn = new pbAgGn();
            zeilePbAgGn.agrp = vpa.Artikelgruppe__r.Name;
            zeilePbAgGn.bmenge = vpa.Standartanzahl__c;
            if(zeilePbAgGn.bmenge == null) zeilePbAgGn.bmenge = 0;
            
            zeilePbAgGn.agID = vpa.Artikelgruppe__c;
            zeilePbAgGn.genstyle = 'color:black;';
            zeilePbAgGn.editierbar = editierbar;
            zeilePbAgGn.nur_einmalig_bestellbar = nur_einmalig_bestellbar;
            
            if(gpMap.containsKey(vpa.Artikelgruppe__c)) {
                decimal genMg = gpMap.get(vpa.Artikelgruppe__c).Gen_Menge_Stk_Mon__c;
                zeilePbAgGn.genmenge = string.valueOf(genMg);
                zeilePbAgGn.genMg = genMg;
                if(gpMap.get(vpa.Artikelgruppe__c).unbefristet_genehmigt__c) {
                    zeilePbAgGn.genbis = 'unbefristet genehmigt. Genehmigungsstatus:' + gpMap.get(vpa.Artikelgruppe__c).Genehmigung__r.Status__c;
                }
                else {
                    date Heute = date.today();
                    if(gpMap.get(vpa.Artikelgruppe__c).genehmigt_ab__c > Heute) {
                        zeilePbAgGn.genbis = 'noch nicht genehmigt. Genehmigungsstatus:' + gpMap.get(vpa.Artikelgruppe__c).Genehmigung__r.Status__c;
                    } else {
                        if(gpMap.get(vpa.Artikelgruppe__c).genehmigt_bis__c < Heute) {
                            zeilePbAgGn.genbis = 'genehmigt bis: ' + string.valueOf(gpMap.get(vpa.Artikelgruppe__c).genehmigt_bis__c) + ' Genehmigungsstatus:' + gpMap.get(vpa.Artikelgruppe__c).Genehmigung__r.Status__c;
                            
                        }
                        else {
                            zeilePbAgGn.genbis = 'genehmigt bis: ' + string.valueOf(gpMap.get(vpa.Artikelgruppe__c).genehmigt_bis__c) + ' Genehmigungsstatus:' + gpMap.get(vpa.Artikelgruppe__c).Genehmigung__r.Status__c;
                        }
                    }
                    
                }
                
            }
            else { 
                zeilePbAgGn.genbis = 'es liegt keine Genehmigung vor.';
                zeilePbAgGn.genstyle = 'color:#ff0000;';
            }
            zeilePbAgGn.arMap = getArtikelProGruppe(vpa.Artikelgruppe__c);
            // zeilePbAgGn.artikelSelect = selectArtikelProGruppe(vpa.Artikelgruppe__c, zeilePbAgGn);
            system.debug('############################alex401 selArtMap.size() ' + selArtMap.size());
            if(selArtMap.containsKey(vpa.Artikelgruppe__c)) {
                zeilePbAgGn.selectedArtikel = selArtMap.get(vpa.Artikelgruppe__c).Artikel__c;
                zeilePbAgGn.apID = selArtMap.get(vpa.Artikelgruppe__c).id;
                zeilePbAgGn.apName = selArtMap.get(vpa.Artikelgruppe__c).Name;
                zeilePbAgGn.bmenge = selArtMap.get(vpa.Artikelgruppe__c).Gen_Menge_Stk_Mon__c;
                fillArtikelProGruppe(vpa.Artikelgruppe__c, zeilePbAgGn);
                pbAgGnList.add(zeilePbAgGn);
            }
        }
        
        return pbAgGnList;
                            
    }   
    
    private list<VPflegeboxArtikelgruppe__c> lesenPbArtikelgruppen(id PbID) {
        list<VPflegeboxArtikelgruppe__c> pbAgList = [SELECT id, Artikelgruppe__c, Artikelgruppe__r.Name, 
                                                            Standartanzahl__c, editable__c, splitable__c,
                                                            Artikelgruppe__r.Positionsnummer__c,
                                                            Artikelgruppe__r.keine_Genehmigungspflicht__c
                                                        FROM VPflegeboxArtikelgruppe__c 
                                                        WHERE Pflegebox__r.id = :PbID];
        return pbAgList;                                                    
    }
    

    
    private map<id, Artikel__c> getArtikelProGruppe(id grID) {
        map<id, Artikel__c> agarMap = new map<id, Artikel__c>();
        for(Artikel__c ar : arList) {
            if(ar.Artikelgruppe__c == grID) agarMap.put(ar.id, ar);
        }
        return agarMap;
    }
    
    private void fillArtikelProGruppe(id grID, pbAgGn zeilePbAgGn) {
        List<SelectOption> options = new List<SelectOption>();
        decimal gesPreis = 0.00;
        decimal tempPreis = 0.00;
        decimal tempPosPreis = 0.00;
        id tempSelectedArtikel = null;
        for(Artikel__c ar : arList) {
            if(ar.Artikelgruppe__c == grID) { 
                if(ar.Anlage_4_Preis__c == null) ar.Anlage_4_Preis__c = 0;
                if(zeilePbAgGn.bmenge == null) zeilePbAgGn.bmenge = 0;
                if(tempSelectedArtikel == null) {
                    tempPreis = ar.Anlage_4_Preis__c;
                    system.debug ('##################################alex311x ar.id=' + ar.id + ' ar.Anlage_4_Preis__c=' + ar.Anlage_4_Preis__c + ' zeilePbAgGn.bmenge=' + zeilePbAgGn.bmenge);
                    tempPosPreis = zeilePbAgGn.bmenge * ar.Anlage_4_Preis__c;
                    tempSelectedArtikel = ar.id;                    
                }
                options.add(new SelectOption(ar.id, ar.name));
                system.debug ('##################################alex301 zeilePbAgGn.apID=' + zeilePbAgGn.apID);
                system.debug ('##################################alex301a ar.Anlage_4_Preis__c=' + ar.Anlage_4_Preis__c);
                system.debug ('##################################alex301b ar.Anlage_4_Preis__c=' + ar.Anlage_4_Preis__c);
                if(zeilePbAgGn.apID != null) {
                    if(zeilePbAgGn.selectedArtikel == ar.id) {
                        zeilePbAgGn.preis = ar.Anlage_4_Preis__c;
                        system.debug ('##################################alex311a ar.Anlage_4_Preis__c=' + ar.Anlage_4_Preis__c + ' zeilePbAgGn.bmenge=' + zeilePbAgGn.bmenge);
                        zeilePbAgGn.pospreis = zeilePbAgGn.bmenge * ar.Anlage_4_Preis__c;                       
                    }                   
                }
                else {
                    if((KdHanschueId != null) && (ar.id == KdHanschueId))  {
                        zeilePbAgGn.preis = ar.Anlage_4_Preis__c;
                        system.debug ('##################################alex311b ar.Anlage_4_Preis__c=' + ar.Anlage_4_Preis__c + ' zeilePbAgGn.bmenge=' + zeilePbAgGn.bmenge);
                        zeilePbAgGn.pospreis = zeilePbAgGn.bmenge * ar.Anlage_4_Preis__c;
                        zeilePbAgGn.selectedArtikel = ar.id; 
                    }
                    
                    
                    else {
                        if((KdHanschueGr != null) && (ar.Name.contains(KdHanschueGr)) && (zeilePbAgGn.selectedArtikel == null)) {
                            zeilePbAgGn.preis = ar.Anlage_4_Preis__c;
                            system.debug ('##################################alex311c ar.Anlage_4_Preis__c=' + ar.Anlage_4_Preis__c + ' zeilePbAgGn.bmenge=' + zeilePbAgGn.bmenge);
                            zeilePbAgGn.pospreis = zeilePbAgGn.bmenge * ar.Anlage_4_Preis__c;
                            zeilePbAgGn.selectedArtikel = ar.id;                        
                        }
                        else {
                            if((ar.Standardartikel_f_r_Pflegeboxen__c != null) && (ar.Standardartikel_f_r_Pflegeboxen__c == true) && (zeilePbAgGn.selectedArtikel == null) ) {                 
                                zeilePbAgGn.preis = ar.Anlage_4_Preis__c;
                                system.debug ('##################################alex311d ar.Anlage_4_Preis__c=' + ar.Anlage_4_Preis__c + ' zeilePbAgGn.bmenge=' + zeilePbAgGn.bmenge);
                                zeilePbAgGn.pospreis = zeilePbAgGn.bmenge * ar.Anlage_4_Preis__c;
                                zeilePbAgGn.selectedArtikel = ar.id;                   
                            }                                       
                        }                                           
                    }
                    
                    if(zeilePbAgGn.selectedArtikel == null) {
                        system.debug ('##################################alex311e tempPreis=' + tempPreis );
                        zeilePbAgGn.preis = tempPreis;
                        zeilePbAgGn.pospreis = tempPosPreis;
                        zeilePbAgGn.selectedArtikel = tempSelectedArtikel;                      
                    }
                    
                }
            }
        }
        if(options.size() == 0) {
            id nop = '00A000000000000000';
            options.add(new SelectOption(nop, 'Kein Artikel in Artikelgruppe'));
        }
        zeilePbAgGn.artikelSelect = options;
        
    }
    
    private list<SelectOption> selectArtikelProGruppe(id grID) {
        List<SelectOption> options = new List<SelectOption>();
        for(Artikel__c ar : arList) {
            if(ar.Artikelgruppe__c == grID) options.add(new SelectOption(ar.id, ar.name));
        }
        return options;
    }
    
    public string checkAuftrag() {    
        if(nAU.genehmigt_bis__c == null) {
                Date d = Date.today();
                nAU.genehmigt_bis__c = d.addYears(100);
        } 
        string retMsg = 'OK';
        system.debug ('##################################alex421 nur_einmalig_bestellbar=' + nur_einmalig_bestellbar);
        if(nAU.genehmigt_ab__c == null) {
            retMsg = '"Bestellt von" ist leer';
            return retMsg;
        }
        /*
        if(nAU.genehmigt_bis__c == null) {
            retMsg = '"Bestellt bis" ist leer';
            return retMsg;
        }   
        */
        if(nAU.genehmigt_bis__c <  nAU.genehmigt_ab__c) {
            retMsg = '"Bestellt bis" ist kleiner als "Bestellt von"';
            return retMsg;
        }

        if(einmalig) {
            if(nAU.genehmigt_bis__c > date.Today()) {
                retMsg = '"Bestellt bis" ist größer als Heute';
                return retMsg;
            }
        }
        else {
            if( (!nur_einmalig_bestellbar) &&(nAU.Lieferzeitraum__c == null)) {
                retMsg = 'Lieferzeitraum nicht ausgewählt';
                return retMsg;
            }           
        }
        return retMsg;                              
    }
    
    public string checkEditAuftrag(Auftrag__c AU) {    
        string retMsg = 'OK';
        if(AU.genehmigt_ab__c == null) {
            retMsg = '"Bestellt von" ist leer';
            return retMsg;
        }
        /*
        if(AU.genehmigt_bis__c == null) {
            retMsg = '"Bestellt bis" ist leer';
            return retMsg;
        }   
        */
        if(AU.genehmigt_bis__c <  AU.genehmigt_ab__c) {
            retMsg = '"Bestellt bis" ist kleiner als "Bestellt von"';
            return retMsg;
        }
        if(AU.Lieferzeitraum__c == null) {
            retMsg = 'Lieferzeitraum nicht ausgewählt.';
            return retMsg;
        }       
        return retMsg;                              
    }
    
    public Auftrag__c makeAuftrag() {      
        date heute = date.Today();
        Auftrag__c AU = new Auftrag__c( Kunde__c = KdID, 
                                        genehmigt_ab__c = nAU.genehmigt_ab__c,
                                        genehmigt_bis__c = nAU.genehmigt_bis__c ,
                                        Genehmigungsstatus__c = 'genehmigt',
                                        Lieferzeitraum__c = nAU.Lieferzeitraum__c,
                                        Bezeichnung__c = this.selectedBoxName, 
                                        RecordTypeId = nAU.RecordTypeId,
                                        Auftrag_text__c = string.valueOf(this.selectedBox));
        if(einmalig || nur_einmalig_bestellbar) {
            AU.Lieferzeitraum__c = 'Einmalig';
            if(nAU.genehmigt_bis__c < heute) {
                AU.genehmigt_bis__c = heute.addMonths(1).toStartOfMonth().addDays(-1);
            }
        }
        system.debug ('##################################alex101 AU=' + AU);
        return AU;                              
    }
    
    public list<Auftragsposition__c> makeAP() { 
        list <Auftragsposition__c> APlist = new list<Auftragsposition__c>();
        Auftragsposition__c AP = new Auftragsposition__c();
        for(PbAgGn satz : PbAgGnList) {
            if(satz.bmenge > 0) {
                system.debug ('##################################alex1101 satz.genID=' + satz.genID + ' satz.nach_paragraph=' + satz.nach_paragraph );
                AP = new Auftragsposition__c(   Kunde__c = KdID,
                                                Artikel__c = satz.selectedArtikel,
                                                Gen_Menge_Stk_Mon__c = satz.bmenge * rlMultiplikator,
                                                genehmigt_ab__c = nAU.genehmigt_ab__c,
                                                genehmigt_bis__c = nAU.genehmigt_bis__c,
                                                Lieferzeitraum__c = nAU.Lieferzeitraum__c,
                                                Positionsart__c = 'Anl4',
                                                Preis__c = satz.pospreis * rlMultiplikator);
                APlist.add(AP); 
            }
            system.debug ('##################################alex102 AP=' + AP);
        }
        return APlist;                              
    }
    
    public string getNach_Paragraph() {
        string np = '54';
        for(PbAgGn satz : PbAgGnList) { 
            if(satz.nach_paragraph == '51') {
                np = '51';
                break;
            }           
        }       
        return np;
    }
    
    public id getGenID() {
        id gid = null;
        for(PbAgGn satz : PbAgGnList) { 
            if(satz.genID != null) {
                gid = satz.genID;
                break;
            }           
        }       
        return gid;
    }
    
    public map<id, Auftragsposition__c> makeMapAP(Auftrag__c AU) { 
        map<id, Auftragsposition__c> APmap = new map<id, Auftragsposition__c>();
        Auftragsposition__c AP = new Auftragsposition__c();
        for(PbAgGn satz : PbAgGnListEdit) {
            if(satz.bmenge > 0) {
                AP = new Auftragsposition__c(   Kunde__c = KdID,
                                                Artikel__c = satz.selectedArtikel,
                                                Gen_Menge_Stk_Mon__c = satz.bmenge,
                                                genehmigt_ab__c = AU.genehmigt_ab__c,
                                                genehmigt_bis__c = AU.genehmigt_bis__c,
                                                Lieferzeitraum__c = AU.Lieferzeitraum__c,                                               
                                                Preis__c = satz.pospreis);
                APmap.put(satz.apID, AP); 
            }
            system.debug ('##################################alex102 AP=' + AP);
        }
        return APmap;                              
    }
    
    public void auftragEditModeOn(Auftrag__c AU) {
        PbAgGnListEdit = fillPbAgGnListEdit(AU);
    }
    
    public list<SelectOption> getBoxSelect() {
        return BoxSelect;
    }
    

    
    public list<Pflegebox__c> getFestBoxList() {
        return festBoxList;
    }
    
    public list<VPflegeboxArtikelgruppe__c> getPbAgList() {
        return pbAgList;
    }
    
    public list<pbAgGn> getPbAgGnList() {
        return pbAgGnList;
    }
    
    public list<pbAgGn> getPbAgGnListEdit() {
        return pbAgGnListEdit;
    }
    
    public id getSelectedBox() {
        return selectedBox;
    }
    
    public void setSelectedBox(id selectedBox) {
        this.selectedBox = selectedBox;
    }
    
    public id getSelectedArtikel() {
        return selectedArtikel;
    }
    
    public void setSelectedArtikel(id selectedArtikel) {
        this.selectedArtikel = selectedArtikel;
    }
    
    public void setSelectedGr(id selectedGr) {
        this.selectedGr = selectedGr;
    }
    
    public string getSelectedBoxName() {
        return SelectedBoxName;
    }
    
    public void setSelectedBoxName(string SelectedBoxName) {
        this.SelectedBoxName = SelectedBoxName;
    }
    
    public decimal getGesamtPreis() {
        decimal gesamtPreis = 0.00;
        for(PbAgGn satz : PbAgGnList) {
            if(satz.pospreis != null) gesamtPreis += satz.pospreis;
        }
        
        return gesamtPreis*rlMultiplikator;
    }
    
    public decimal getGesamtPreisEdit() {
        decimal gesamtPreisEdit = 0.00;
        for(PbAgGn satz : PbAgGnListEdit) {
            if(satz.pospreis != null) gesamtPreisEdit += satz.pospreis;
        }
        
        return gesamtPreisEdit;
    }
    
    public string getGesamtPreisFarbe() {
        
        if(gesamtPreis > maxprice) {
            gesamtPreisFarbe='color:#990000;';
        }
        else {
         if(gesamtPreis < minprice) { 
            gesamtPreisFarbe='color:#000099;';
         }
         else gesamtPreisFarbe='color:#009900;';
        }
        return gesamtPreisFarbe;
    }
    
    public string getGesamtPreisFarbeEdit() {
        
        if(gesamtPreisEdit > maxprice) {
            gesamtPreisFarbe='color:#990000;';
        }
        else {
         if(gesamtPreisEdit < minprice) { 
            gesamtPreisFarbeEdit='color:#000099;';
         }
         else gesamtPreisFarbeEdit='color:#009900;';
        }
        return gesamtPreisFarbeEdit;
    }
    
    public Auftrag__c getNaU() {
        id auRecordTypeId = null;
        if(boxGenehmigtBis != null) {
            nAU.genehmigt_bis__c = boxGenehmigtBis;
        }
        if(einmalig) {
            nAU.genehmigt_ab__c = date.Today().addMonths(-1).toStartOfMonth(); 
            nAU.genehmigt_bis__c = date.Today().toStartOfMonth().addDays(-1);  
        }
        
        if(getNach_Paragraph() == '51') {
            auRecordTypeId = getauRTid('51');
            if(auRecordTypeId != null) nAU.RecordTypeId = id.valueOf(auRecordTypeId);
            nAU.genehmigt_bis__c = date.newinstance(2100, 12, 31);
        }
        else {          
            auRecordTypeId = getauRTid('54');
            if(auRecordTypeId != null) nAU.RecordTypeId = id.valueOf(auRecordTypeId);
        }
            

        return nAU;
    }
    
    public void setNaU(Auftrag__c nAU) {
        this.nAU = nAU;
    }
    
    public boolean getboxKeineGenehmigung() {
        return boxKeineGenehmigung;
    }
    
    public boolean getNur_einmalig_bestellbar() {
        return nur_einmalig_bestellbar;
    }
    
    public boolean getboxGenehmigtUnbefristet() {
        return boxGenehmigtUnbefristet;
    }
    
    public date getboxGenehmigtAb() {
        return boxGenehmigtAb;
    }
    
    public date getboxGenehmigtBis() {
        return boxGenehmigtBis;
    }
    
    public void auftragEinmalig(boolean an) {
        this.einmalig = an;
    }
    
    public void auftragRlieferung(boolean rl) {
        this.rLieferung = rl;
    }
    
    public boolean getRlieferung() {
        return rLieferung;
    }
    
    public void rechnenGesamtpreis() {
        integer monthDiff = nAU.genehmigt_ab__c.monthsBetween(nAU.genehmigt_bis__c.addMonths(1).toStartOfMonth());
        
        this.rlMultiplikator = monthDiff;
        if(this.rlMultiplikator > 1) {
            muTxt = 'x ' + string.valueOf(rlMultiplikator);
        }
        else muTxt = ' ';
        
    }
    public string getMuTxt() {
        return muTxt;
    }
    
    public boolean getEditierbar() {
        return editierbar;
    }

    public boolean isKandidat() {
        return kandidat;
    } 

    public boolean isKandidat51() {
        return kandidat51;
    }   
    
    public id getauRTid(string np) {
        id rtid = null;
        string nm = 'AU' + np;
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='Auftrag__c' AND Name=: nm];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        
        return rtid;
    }
    
}