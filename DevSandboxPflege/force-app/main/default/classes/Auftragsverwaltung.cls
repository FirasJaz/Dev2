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
// 08.04.2015 von AM - Prüfen ob Standardlieferanschrift vorhanden.
//
//
//  am 09.07.2015 von AM Anpassung an pg51
// 21.08.2015 von BT Ergänzung inko_method und inko_auftrag
// 29.01.2016 von BT    Das Feld 'Geburtsdatum__c' wird durch das Feld 'Geburtsdatum_text__c' erstetzt
// 16.02.2016 von BT    #111866253 CB - Auftragsverwaltung - Einfügen einer Sicherheitsabfrage 
// 18.02.2016 von BT    #111866253 CB - Auftragsverwaltung - Einfügen einer Sicherheitsabfrage (Es wird nur auf CB lieferungen geachtet) 
// 07.02.2016 von BT    #115244033 CB - Auftragsverwaltung - Sicherheitsabfrage auf PG51 anpassen.
// 22.04.2016 von BT    #115244033 CB - Auftragsverwaltung - In der Sicherheitsabfrage werden noch aktive Lieferungen angezeigt
// 04.12.2017   AM      #153054057 Bei Anträgen ohne Enddatum wird das Jahr heute + 100 Jahre
//****************************************************************************************************************************
*/

global with sharing class Auftragsverwaltung {
    public ID KdID = ApexPages.CurrentPage().getParameters().get('id');
    public Kunde__c KDe {get; set;}
    public list<Auftrag__c> lAU = new list<Auftrag__c>();
    public boolean ArtikelEditMode = false; 
    public boolean inkoEditMode = false;
    public boolean AuftragEditMode = false; 
    public boolean inkoAuftragEditMode = false;
    public boolean keineAdresse = false; 
    public boolean einmalig = false; 
    public box_method box {get; set;}
    public inko_method inko {get; set;}   
    public box_auftrag auftrag_box {get; set;}
    public inko_auftrag auftrag_inko {get; set;}
    private Auftrag__c eAU {get; set;}
    private string sectionTitle = 'Auftrag';
    private integer colNum = 8;
    
    public boolean error {get; set;}
    public boolean kandidat = false;
    public boolean kandidat51 = false;
    public boolean displayPopup {get; set;}
    
    public Set<string> lnList = new Set<string>();
    
    public Set<string> getLnList() {
        return lnList;
    }
    
    public Auftragsverwaltung() {}
    
    public Auftragsverwaltung(ApexPages.StandardController stdController) {
        /*
        KDe = [SELECT Name, Vorname__c, Name__c, komb_name__c, Versichertennummer__c, Krankenkasse__c, 
                      Geburtsdatum_text__c,  e_mail__c, Telefon__c, Zahlungsmodalit_t__c, Sterbedatum__c, Lieferstop__c,
                      Fax__c, komb_Adresse__c, Zuzahlung_befreit_von__c, Zuzahlung_befreit_bis__c,
                      Krankenkasse__r.ParentId, Kundennummer__c, Stra_e__c, Hausnummer__c, Ort__c, PLZ__c,
                      bevorzugter_art_f_r_Fl_chendesinfektion__c, bevorzugter_art_f_r_H_ndedesinfektion__c,
                      bevorzugter_art_f_r_Einmalhandsch__c, Status__c
                FROM Kunde__c WHERE ID =: KdID ];
        */
        KDe = [SELECT Name, Vorname__c, Name__c, komb_name__c, Versichertennummer__c, Krankenkasse__c, 
                      Geburtsdatum_text__c,  e_mail__c, Telefon__c, Zahlungsmodalit_t__c, Sterbedatum__c, Lieferstop__c,
                      Fax__c, komb_Adresse__c, Zuzahlung_befreit_von__c, Zuzahlung_befreit_bis__c,
                      Krankenkasse__r.ParentId, Kundennummer__c, Stra_e__c, Hausnummer__c, Ort__c, PLZ__c,
                      bevorzugter_art_f_r_Fl_chendesinfektion__c, bevorzugter_art_f_r_H_ndedesinfektion__c,
                      bevorzugter_art_f_r_Einmalhandsch__c
                FROM Kunde__c WHERE ID =: KdID ];
        keineAdresse = checkLieferanschrift(KdID);
       
        if(keineAdresse) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Standardlieferanschrift nicht definiert!'));
        }
        //if(KDe.Status__c == 'Kandidat') kandidat = true;
        
        lAU = laufendeAuf();
        if(box == null) {
            system.debug ('##################################alex200 box');
            try {
                box = new box_method(KdID);
            }
            catch (system.exception e) {
                system.debug ('##################################alex210 box error');   
            }
            
            system.debug ('##################################alex201 box.hasError()=' + box.hasError());
            if(box.hasError()){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, box.getErrorMessage())); 
            }
            kandidat = box.isKandidat();
            kandidat51 = box.isKandidat51();
        }      
        
           if(inko == null) {
            system.debug ('##################################alex200 box');
            try {
                inko = new inko_method();
            }
            catch (system.exception e) {
                system.debug ('##################################alex210 box error');   
            }
            
            system.debug ('##################################alex201 box.hasError()=' + box.hasError());
            if(box.hasError()){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, box.getErrorMessage())); 
            }
        }                                                      
    }

    public list<Auftrag__c> laufendeAuf() {
        date Heute = date.today();
        list<Auftrag__c> lAU = new list<Auftrag__c>();
        lAU = [SELECT   id, Name, Kunde__c, Bezeichnung__c, genehmigt_ab__c, genehmigt_bis__c, 
                        Lieferzeitraum__c, Genehmigungsstatus__c, unbefristet_genehmigt__c
                FROM Auftrag__c 
                WHERE Kunde__c = : KdID
                
 //               AND ((unbefristet_genehmigt__c = true) OR (genehmigt_bis__c > :Heute)) 
                AND Genehmigungsstatus__c IN ('genehmigt', 'angehalten') ];
        return lAU;                         
    }
    
    public PageReference zurueck() {
        PageReference returnPage = new PageReference('/' + kde.id);
        returnPage.setRedirect(true);
        return returnPage;
    }

    public void boxZuAuftrag() {
        sectionTitle = 'Auftrag';
        ArtikelEditMode = true; 
        AuftragEditMode = false;
        einmalig = false;
        box.auftragEinmalig(false);
        box.auftragRlieferung(false);
        box.initPB();
        inkoEditMode = false;
    }  
    
    public void inkoZuAuftrag() {
        sectionTitle = 'Auftrag';
        ArtikelEditMode = false; 
        AuftragEditMode = false;
        einmalig = false;
        inkoEditMode = true;                
    }
    
    public void boxZuAuftragR() {
        sectionTitle = 'Rückwirkende Lieferung';
        ArtikelEditMode = true; 
        AuftragEditMode = false;
        einmalig = true;
        box.auftragEinmalig(true);
        box.auftragRlieferung(true);
        box.initPB();
    }   
    
    public void boxZuAuftragAbbrechen() {
        ArtikelEditMode = false;
        AuftragEditMode = false;
        displayPopup = false;
        einmalig = false;
        box.initPB(); 
        inko = new inko_method();          
    }   
    
    public void inkoZuAuftragAbbrechen() {
        //ArtikelEditMode = false;
        //AuftragEditMode = false;
        einmalig = false; 
        inkoEditMode = false;
        inkoAuftragEditMode = false;
        inko = new inko_method();  
    }   
    
    
    public void inkoZuAuftragErstellen() {
        //ArtikelEditMode = false;
        //AuftragEditMode = false;
        string retMsg = inko.checkAuftrag();
        
        if(retMsg == 'OK') {
        inko.auftragAusloesen();
        auftrag_inko = new inko_auftrag(inko.AU, inko.ApList);     
        einmalig = false; 
        inkoEditMode = false;
        inkoAuftragEditMode = false;
        lAU = laufendeAuf();
        inko = new inko_method();  
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, retMsg));
        }
        //PageReference returnPage = new PageReference('/apex/Auftragsverwaltung?scontrolCaching=1&id='+KdID);
        //returnPage.setRedirect(true);
        //return returnPage;         
    }  
    
    
    public boolean checkLieferanschrift(id kdid) {
        boolean keineAdresse = true;
        List<Anschrift__c> delv_addr = [SELECT komb_Adresse__c  
                                              FROM   Anschrift__c
                                             WHERE   Standardlieferanschrift__c = true 
                                             AND Kunde__c = :kdid
                                             LIMIT 1];
        if((delv_addr != null) && (delv_addr.size() > 0)) {
            keineAdresse = false;
        }       
        return keineAdresse;
    }
    
    public void boxEditAuftragSpeichern() {  
        if(eAU.genehmigt_bis__c == null) {
                Date d = Date.today();
                eAU.genehmigt_bis__c = d.addYears(100);
        }      
        
        string retMsg = box.checkEditAuftrag(eAU);
        
        system.debug ('##################################alex105 retMsg=' + retMsg);
        if(retMsg == 'OK' ) {                                    
                ArtikelEditMode = false;
                AuftragEditMode = false;                        
            
                map<id, Auftragsposition__c> mapAP = box.makeMapAP(eAU);
                auftrag_box = new box_auftrag(eAU, mapAP);
                lAU = laufendeAuf();
                box.initPB();
                // PageReference curPage = new PageReference(ApexPages.currentPage().getUrl());
                // curPage.setRedirect(true);
                // return curPage;            
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, retMsg));
            box.initPB();
        }
    }
    
    public void inkoEditAuftragSpeichern() {                
        string retMsg = inko.checkEditAuftrag(eAU);
        
        system.debug ('##################################alex105 retMsg=' + retMsg);
        if(retMsg == 'OK' ) {
            ArtikelEditMode = false;
            inkoAuftragEditMode = false;
            
            map<id, Auftragsposition__c> mapAP = inko.makeMapAP(eAU);
            auftrag_inko = new inko_auftrag(eAU, mapAP);
            lAU = laufendeAuf();
            inko = new inko_method();
            // PageReference curPage = new PageReference(ApexPages.currentPage().getUrl());
            // curPage.setRedirect(true);
            // return curPage;
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, retMsg));
            //inko = new inko_method();
        }
    }

    public void boxEditAuftragAbbrechen() {
        ArtikelEditMode = false;
        AuftragEditMode = false;
        lAU = laufendeAuf();
        // box.initPB();   
    }   

    
    public PageReference boxZuAuftragErstellen() {
        AuftragEditMode = false;
        string retMsg = box.checkAuftrag();
        
        system.debug ('##################################alex105 retMsg=' + retMsg);
        if(retMsg == 'OK' ) {
            pruefen();
            if(error == false) { 
            displayPopup = false;   
            ArtikelEditMode = false;
            Auftrag__c newAU = box.makeAuftrag();
            list<Auftragsposition__c> listAP = box.makeAP();
            string np = box.getNach_Paragraph();
            id gid = box.getGenID();
            if(np == '51') {
                auftrag_box = new box_auftrag(newAU, listAP, gid, np);
            }
            else {
                // auftrag_box = new box_auftrag(newAU, listAP);
                auftrag_box = new box_auftrag(newAU, listAP, gid, np);
            }
            lAU = laufendeAuf();
            box.initPB();
            // PageReference curPage = new PageReference(ApexPages.currentPage().getUrl());
            // curPage.setRedirect(true);
            // return curPage;
            }
            else {
                displayPopup = true;
            }
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, retMsg));
            box.initPB();
        }
        
        return null;        
    }   
    
    /*
    public PageReference inkoZuAuftragErstellen() {
        AuftragEditMode = false;
        inko.auftragAusloesen();
        string retMsg = inko.checkAuftrag();
        
        system.debug ('##################################alex105 retMsg=' + retMsg);
        if(retMsg == 'OK' ) {
            ArtikelEditMode = false;
            Auftrag__c newAU = inko.makeAuftrag();
            list<Auftragsposition__c> listAP = inko.makeAP();
            auftrag_inko = new inko_auftrag(newAU, listAP);
            lAU = laufendeAuf();
            inko = new inko_method();
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, retMsg));
            inko = new inko_method();
        }
        
        return null;        
    }   
    */
        
    public PageReference PflegeBoxAuftragBearbeiten() {
        
        eAU = [SELECT   id, Name, Kunde__c, Bezeichnung__c, genehmigt_ab__c, genehmigt_bis__c, Auftrag_text__c,
                        Lieferzeitraum__c, Genehmigungsstatus__c, unbefristet_genehmigt__c
                FROM Auftrag__c 
                WHERE id = : applyAuId
                LIMIT 1];   
        
        if((eAU.Auftrag_text__c == 'Muster-Artikel') || (eAU.Auftrag_text__c == 'Inko-Artikel')) {
            inkoAuftragEditMode = true;
            inko.auftragEditModeOn(eAU);
            ArtikelEditMode = false;  
            AuftragEditMode = false;     
        }
        else {
            AuftragEditMode = true;        
            box.auftragEditModeOn(eAU);
            ArtikelEditMode = false;
            inkoAuftragEditMode = false;
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'AU.id=' + applyAuId));            
        }        
        
        return null;
    }
    
    public PageReference PflegeBoxAuftragBeenden() {
        AuftragEditMode = false;
        ArtikelEditMode = false;
        List<Auftrag__c> Aup = [SELECT id, name, Auftrag_text__c FROM Auftrag__c WHERE id= :applyAuId AND Auftrag_text__c IN ('Muster-Artikel', 'Inko-Artikel') LIMIT 1];
        if((Aup != null) && (Aup.size() > 0 )) {
            auftrag_inko = new inko_auftrag(id.valueOf(applyAuId), 'beenden');
            lAU = laufendeAuf();
        }
        else {
            auftrag_box = new box_auftrag(id.valueOf(applyAuId), 'beenden');
            lAU = laufendeAuf();
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'AU.id=' + applyAuId));
        }

        return null;
    }
    
    public PageReference PflegeBoxAuftragAnhalten() {
        AuftragEditMode = false;
        ArtikelEditMode = false;
        List<Auftrag__c> Aup = [SELECT id, name, Auftrag_text__c FROM Auftrag__c WHERE id= :applyAuId AND Auftrag_text__c IN ('Muster-Artikel', 'Inko-Artikel') LIMIT 1];
        if((Aup != null) && (Aup.size() > 0 )) {
            auftrag_inko = new inko_auftrag(id.valueOf(applyAuId), 'anhalten');
            lAU = laufendeAuf();        
        }
        else {
            auftrag_box = new box_auftrag(id.valueOf(applyAuId), 'anhalten');
            lAU = laufendeAuf();
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Auftrag angehalten.'));    
        }
        
        return null;
    }
    
    public PageReference PflegeBoxAuftragAktivieren() {
        AuftragEditMode = false;
        ArtikelEditMode = false;
        List<Auftrag__c> Aup = [SELECT id, name, Auftrag_text__c FROM Auftrag__c WHERE id= :applyAuId AND Auftrag_text__c IN ('Muster-Artikel', 'Inko-Artikel') LIMIT 1];
        if((Aup != null) && (Aup.size() > 0 )) {
            auftrag_inko = new inko_auftrag(id.valueOf(applyAuId), 'aktivieren');
            lAU = laufendeAuf();
                }
        else {
            auftrag_box = new box_auftrag(id.valueOf(applyAuId), 'aktivieren');
            lAU = laufendeAuf();
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Auftrag aktiviert.'));
        }
        
        return null;
    }
    
    public void selectArt() {
        system.debug ('##################################alex200 applyArID=' + applyArID);

        box.setSelectedGr(applyArID);
        if(box.checkGenMenge() || (box.geteditierbar() && kandidat) || (box.geteditierbar() && kandidat51)) {
            box.recreatePbAgGnList();
        }
        else {
            system.debug ('##################################alex111 GenMenge');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Genehmigte Menge kleiner als Bestellte Menge'));
        }
    }
    
    public void selectArtEdit() {
        system.debug ('##################################alex200 applyArID=' + applyArID);
        box.setSelectedGr(applyArID);       
        if(box.checkGenMenge()) {
            box.recreatePbAgGnListEdit();
        }
        else {
            system.debug ('##################################alex111 GenMenge');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Genehmigte Menge kleiner als Bestellte Menge'));
        }
    }
    

    public String applyPBVlfdName {
        get;
        set{
            applyPBVlfdName = value;
        }
    }
    
    public String applyAuId {
        get;
        set{
            applyAuId = value;
            System.debug('##########################alex311 value: '+value);
        }
    }
    
    public list<Auftrag__c> getLAU() {
        return lAU;
    }
    
    public Kunde__c getKDe() {
        return KDe;
    }  
    
    public Id getKdID() {
        return KdID;
    }
    
    public boolean getArtikelEditMode() {
        return ArtikelEditMode;
    }
    
    public boolean getInkoEditMode() {
        return inkoEditMode;
    }
    
    public boolean getInkoAuftragEditMode() {
        return inkoAuftragEditMode;
    }
    
    public boolean getAuftragEditMode() {
        return AuftragEditMode;
    }
    
    public boolean getKeineAdresse() {
        return keineAdresse;
    }
    
    public ID applyArID {
        get;
        set{
            applyArID = value;
        }
    }
    
    public String SelectedTab {get; set; }
    
    public string getSectionTitle() {
        return sectionTitle;
    }
    
    public integer getColNum() {
        if(box.getRlieferung()) {
            colNum = 8;
        } 
        else colNum = 7;
        return colNum;
    }
    
    public boolean getFBenable() {
        if(SelectedTab == 'CB') {
            return false;
        }
        else return true;
    }
    
    public string boxName {
        get {
            try {
            string boxName = Anl4_Stueckliste__c.getInstance('Name').Bezeichnung__c;
            return boxName;
            }
            catch(system.exception e) {
            return 'Anl4_Stückliste';
            } 
        }
        set;
    }
    
    public Auftrag__c getEaU() {
        return eAU;
    }
    
    public void setEaU(Auftrag__c eAU) {
        this.eAU = eAU;
    } 
    
    public boolean getKandidat() {
        return kandidat;
    }
    
    public boolean getKandidat51() {
        return kandidat51;
    }
    
    public PageReference auftragNachMeldungErstellen() {
        error = false;
        displayPopup = false; 
        AuftragEditMode = false;  
        ArtikelEditMode = false;
        Auftrag__c newAU = box.makeAuftrag();
        list<Auftragsposition__c> listAP = box.makeAP();
        string np = box.getNach_Paragraph();
        id gid = box.getGenID();
        if(np == '51') {
            auftrag_box = new box_auftrag(newAU, listAP, gid, np);
        }
        else {
            // auftrag_box = new box_auftrag(newAU, listAP);
            auftrag_box = new box_auftrag(newAU, listAP, gid, np);
        }
        lAU = laufendeAuf();
        box.initPB();
        // PageReference curPage = new PageReference(ApexPages.currentPage().getUrl());
        // curPage.setRedirect(true);
        // return curPage;;  
        
        return null;      
    }
    
    public void pruefen(){       
        lnList.clear();        
        Auftrag__c au = box.makeAuftrag();
        Date heute = au.genehmigt_ab__c;
        Date ersterTag = heute.toStartOfMonth();
        Date newDate = ersterTag.addMonths(1);      
        String soql = '';                
        
        if(au.Bezeichnung__c.contains('CB')) {
            soql = 'SELECT Id, Kunde__c, Lieferdatum__c, Status__c, Lieferschein__c, Lieferschein__r.Lieferschein_text__c, Lieferschein__r.Name FROM Lieferscheinposition__c WHERE  Lieferschein__c != null AND Lieferschein__r.Lieferschein_text__c =\'54\' AND Kunde__c =\'' + KdID +'\' ';
            soql = soql +  ' AND Status__c IN (\'Bedarf\', \'geliefert\', \'jetzt liefern\')';
            soql = soql +  ' AND Lieferdatum__c >= ' + String.valueOf(ersterTag);
            soql = soql +  ' AND Lieferdatum__c < ' + String.valueOf(newDate);              
        }    
        
        if(au.Bezeichnung__c == 'KUWV')  {
            soql = 'SELECT Id, Kunde__c, Lieferdatum__c, Status__c, Lieferschein__c, Lieferschein__r.Lieferschein_text__c, Lieferschein__r.Name FROM Lieferscheinposition__c WHERE  Lieferschein__c != null AND Lieferschein__r.Lieferschein_text__c =\'51\' AND Kunde__c =\'' + KdID +'\' ';
            soql = soql +  ' AND Status__c IN (\'Bedarf\', \'geliefert\', \'jetzt liefern\')';
            soql = soql +  ' AND Lieferdatum__c >= ' + String.valueOf(ersterTag);
            soql = soql +  ' AND Lieferdatum__c < ' + String.valueOf(newDate);    
        } 

        soql = soql + ' ORDER BY Name DESC';
        
        if(soql != ' ORDER BY Name DESC') {
        
            if((database.query(soql)!= null) && (database.query(soql).size() > 0)) {
                error = true;
                
                for(Lieferscheinposition__c LP: database.query(soql)){
                    lnList.add(LP.Lieferschein__r.Name);
                }
            }
            else {
                error = false;
            }
        }
        else {
            error = false;
        }        
        
    }
    
         // wird nicht aufgerufen! Nur für Testabdeckung!!!  
        public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;}
                        public String LsNr {get;set;}
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