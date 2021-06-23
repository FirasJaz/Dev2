public with sharing class bearbeitePBGenehmigungController {
//****************************************************************************************************************************
// Erstellt tt.mm.yyyy von YY
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
// Bearbeitung der genehmigungen für Anlage 4
//
//
//****************************************************************************************************************************
//Änderungen:
//
// 20.05.2014 von wds WSIG Bezug rausgenommen
//                        
//      
// 28.11.2014 von wds: Anzeige der Bettschutzunterlagen bei der Bearbeitung
//
// 01.12.2014 von wds: Fehlermeldung wenn kein Datum in Antrag_beantwortet_am__c
//
// 14.05.2015 von wds: #127 pflege.de KUWV integriert und gen_menge bei §51 auf 0 gestezt
//                            
//****************************************************************************************************************************
//
//  2014-05-20 wds WSIG Bezug rausgenommen
//
    //public variablen
    public ApexPages.standardController controller {get; set;}
    //private variablen
    private string retPage = ApexPages.currentPage().getParameters().get('retURL');
    private id GnID = ApexPages.currentPage().getParameters().get('id');
    private string gstatus = ApexPages.currentPage().getParameters().get('stat');
    private string attid = ApexPages.currentPage().getParameters().get('attid');
    private string currentStatus {get; set;}

    public Genehmigung__c Genehmigung { get; set; }
    public Genehmigungsposition__c BL { get; set; }
    public List<Genehmigungsposition__c> positionen { get; set; }
    public map<id, date> gpMap = new map<id, date>();
    public List<Genehmigungsposition__c> positionen54 { get; set; }

    public boolean show51 = false;
    public boolean show54 = true;


    
    public bearbeitePBGenehmigungController(ApexPages.StandardController stdController) {
        
        controller = stdController;
        system.debug ('####################### retPage ' + retPage);
        Genehmigung = [SELECT
                        Name,
                        Dokumentation__c,
                        genehmigt_ab__c,
                        genehmigt_bis__c,
                        Genehmigungsstatus__c,
                        Originalgenehmigung__c,
                        Genehmigungsnummer__c,
                        Rezept__c,
                        unbefristet_genehmigt__c,
                        Status__c,
                        Antrag_beantwortet_am__c,
                        Antrag_bewilligt_ab__c,
                        Antrag_eingegangen_am__c,
                        Antrag_versandt_am__c,
                        Nach_Paragraph__c,
                        attachmentID__c,
                        Kunde__c,
                        Kunde__r.Name
                        FROM Genehmigung__c WHERE Id = : GnId]; 
        if(gstatus != null) {
            Genehmigung.Status__c = gstatus;
        }
        currentStatus = Genehmigung.Status__c;
        if(Genehmigung.Nach_Paragraph__c == null){
            Genehmigung.Nach_Paragraph__c = '54';
        }
        if(Genehmigung.Nach_Paragraph__c == '54'){
            show54 = true;
        }
        if(Genehmigung.Nach_Paragraph__c == '51'){
            show51 = true;
            show54 = false;
        }
        if(attid != null) {
            Genehmigung.attachmentID__c = attid;
        }
        system.debug ('#######################alex200 Genehmigung.Nach_Paragraph__c=' + Genehmigung.Nach_Paragraph__c);
//        Genehmigung.AuthorizationWrapper gwrapper = new Genehmigung.AuthorizationWrapper((Genehmigung__c)stdController.getRecord());
//        this.Genehmigung = gwrapper.Genehmigung;
        this.positionen = new List<Genehmigungsposition__c>();
        positionen = [SELECT id,
            Name,
            Gen_Menge_Stk_Mon__c,
            genehmigt_ab__c,
            genehmigt_bis__c,
            Gen_Menge_Stk__c,
            Gen_Menge_Stk_Tag__c,
            GenAnzVerp__c,
            Artikelgruppe__c,
            unbefristet_genehmigt__c,
            Artikelgruppe__r.Name,
            Ant_Menge_Stk_Mon__c,
            Ant_Menge_Stk__c
            FROM Genehmigungsposition__c WHERE Genehmigung__c = :GnID and artikelgruppe__r.positionsnummer__c = '54'] ;
            
            for(Genehmigungsposition__c gp : positionen) {
                if(gp.Gen_Menge_Stk_Mon__c == null) gp.Gen_Menge_Stk_Mon__c = gp.Ant_Menge_Stk_Mon__c;
                gpMap.put(gp.id, gp.genehmigt_bis__c);
            }
            
            this.positionen54 = new List<Genehmigungsposition__c>();
            positionen54 = [SELECT id,
                Name,
                Gen_Menge_Stk_Mon__c,
                genehmigt_ab__c,
                genehmigt_bis__c,
                Gen_Menge_Stk__c,
                Gen_Menge_Stk_Tag__c,
                GenAnzVerp__c,
                Artikelgruppe__c,
                unbefristet_genehmigt__c,
                Artikelgruppe__r.Name,
                Ant_Menge_Stk_Mon__c,
                Ant_Menge_Stk__c
                FROM Genehmigungsposition__c WHERE Genehmigung__c = :GnID and artikelgruppe__r.positionsnummer__c = '51'] ;
            
            for(Genehmigungsposition__c gp : positionen54) {
                if(gp.Gen_Menge_Stk__c == null) gp.Gen_Menge_Stk__c = 0;
                gpMap.put(gp.id, gp.genehmigt_bis__c);
            }

        /*system.debug ('##Init OK');*/
    }
    
    public PageReference neueGenehmigungSichern() {
                
        system.debug ('####################### retPage ' + retPage);

        PageReference returnPage = null;
        boolean error = false; 
        if(!genehmigungOK(Genehmigung)) {
            for(Genehmigungsposition__c gp : positionen) {
//               if(gp.genehmigt_ab__c == null) gp.genehmigt_ab__c = Genehmigung.genehmigt_ab__c;
                
//               if((gp.genehmigt_bis__c == null) && (Genehmigung.genehmigt_bis__c != null)) gp.genehmigt_bis__c = Genehmigung.genehmigt_bis__c;
                if((gp.genehmigt_bis__c == null) && (Genehmigung.genehmigt_bis__c != null)) {
                    gp.genehmigt_bis__c = Genehmigung.genehmigt_bis__c;
                }
                
                if((gp.unbefristet_genehmigt__c != true) && (Genehmigung.unbefristet_genehmigt__c == true)) { 
                    gp.unbefristet_genehmigt__c = true;
                    gp.genehmigt_bis__c = null;
                    Genehmigung.genehmigt_bis__c = null;
                }
                if(gp.Gen_Menge_Stk_Mon__c == null) gp.Gen_Menge_Stk_Mon__c = gp.Ant_Menge_Stk_Mon__c;
            }
            try{
                update Genehmigung;
                update positionen;
            }
            catch (system.exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                      'Fehler beim dem Speichern 54' + e ));   
                system.debug ('#######################alex200 error=' + e);
                error = true; 
            }
 //
 // Eingefügt für KUWV §51 Artikel
 //      
            for(Genehmigungsposition__c gp : positionen54) {
                if((gp.genehmigt_bis__c == null) && (Genehmigung.genehmigt_bis__c != null)) {
                    gp.genehmigt_bis__c = Genehmigung.genehmigt_bis__c;
                }
                
                if((gp.unbefristet_genehmigt__c != true) && (Genehmigung.unbefristet_genehmigt__c == true)) { 
                    gp.unbefristet_genehmigt__c = true;
                    gp.genehmigt_bis__c = null;
                    Genehmigung.genehmigt_bis__c = null;
                }
                if(gp.Gen_Menge_Stk_Mon__c == null) gp.Gen_Menge_Stk_Mon__c = 0;
            }
            try{
                update Genehmigung;
                update positionen54;
            }
            catch (system.exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                      'Fehler beim dem Speichern 51' + e));   
                system.debug ('#######################alex200 error=' + e);
                error = true; 
            }
        
        
        system.debug ('#######################alex201 error=' + error);
        if(!error) {
            system.debug ('#######################alex202 currentStatus=' + currentStatus + ' Genehmigung.Status__c =' + Genehmigung.Status__c );
            if(gstatus == 'Bewilligung') {
                returnPage = new PageReference('/apex/Auftragsverwaltung?&id=' + Genehmigung.Kunde__c);
            }
            else {
                if ((currentStatus == 'Antragsversand') && (Genehmigung.Status__c == 'Bewilligung')) {
                    returnPage = new PageReference('/p/attach/NoteAttach?pid='+Genehmigung.Kunde__c + '&parentname=' + Genehmigung.Kunde__r.Name + '&retURL=' + retPage );  
                }
                else {
                    if(retPage != null){
                        returnPage = new PageReference(retPage);
                    } else {
                        returnPage = new PageReference('/'+Genehmigung.Id);
                    }               
                }
            }
        }
            
        }
        
/*
        Genehmigung__c Genehmigung = this.Genehmigung;
        Boolean error = neuenGenehmigungSichern(Genehmigung);
        PageReference returnPage = null;
        // nur wenn eine retUrl übergeben wird, wird mit dieser eine PageReference initialisiert
        // sonst mit der kundenummer, d.h. nach erstellen eines kunden wird man auf die detail-seite umgeleitet
        system.debug('########## '+Genehmigung.Id + ' Genehmigung: '+ Genehmigung);
        if(retPage != null){
            returnPage = new PageReference(retPage);
        } else {
            returnPage = new PageReference('/'+Genehmigung.Id);
        }
        if ( error ){
               returnPage = null;
        } else {
            returnPage.setRedirect(true);
        }
*/
        return returnPage;
    }

    public PageReference neueGenehmigungZurueck() {
        PageReference returnPage = new PageReference('/'+Genehmigung.Kunde__c);
        returnPage.setRedirect(true);
        return returnPage;
    }

    public string getRetPage(){
            return retPage;
    }    
    
    public boolean genehmigungOK(Genehmigung__c Gn) {
        boolean error = false; 
        if ( Gn.Antrag_beantwortet_am__c == null ) {    
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                      '"Antrag beantwortet am" nicht gefüllt. Bitte füllen! ' ));
            return true;
        }   
        if ((Gn.Status__c == 'Bewilligung') || (Gn.Status__c == 'Teilbewilligung')) {
            if((Gn.genehmigt_bis__c == null) && (Gn.unbefristet_genehmigt__c != true)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
                      '"genehmigt bis" oder "unbefristet genehmigt" nicht gefüllt. Bitte füllen! ' ));
                return true;                
            }           
        }
        return error;
    }

    public Boolean neuenGenehmigungSichern (Genehmigung__c Genehmigung){
        Boolean error = False;                                       
        set<string> BewilligtStatus = new set<string>{'Bewilligung', 'Teilbewilligung'};
        Set<string> geschlosseneStatus = new set<string>{'Bewilligung', 'Teilbewilligung', 'Ablehnung'};
        List<Genehmigungsposition__c> gpToUpdate = new List<Genehmigungsposition__c>{};
        system.debug('############## HK neu Gen sichern genstatus ' + Genehmigung.status__c);
        if (geschlosseneStatus.contains(Genehmigung.status__c)){
            system.debug('############## HK neu Gen sichern versandt ' + Genehmigung.Antrag_versandt_am__c);
            system.debug('############## HK neu Gen sichern eingegangen ' + Genehmigung.Antrag_beantwortet_am__c);
            if (genehmigung.Antrag_versandt_am__c == null ||
                genehmigung.Antrag_beantwortet_am__c == null){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                        'Entweder "Antrag versandt" oder "Antrag beantwortet am" nicht gefüllt. Bitte füllen! ' );
                        ApexPages.addMessage(myMsg);                                                    
                        error = True;
            }
        }
        if (!error){
    
            for (Genehmigungsposition__c g : this.positionen){
                system.debug(logginglevel.error, '######## Bearb Gen Status ' + Genehmigung.Genehmigungsstatus__c);
                system.debug(logginglevel.error, '######## Bearb Gen AntMg  ' + g.Ant_Menge_Stk_Mon__c);
                system.debug(logginglevel.error, '######## Bearb Gen GenMg  ' + g.Gen_Menge_Stk_Mon__c);
                
                if (BewilligtStatus.contains(Genehmigung.status__c)){
                    system.debug(logginglevel.error, '######## Bearb Gen (Teil-)Bewilligt ' );
                    if (g.Gen_Menge_Stk_Mon__c == null){
                        system.debug(logginglevel.error, '######## Bearb Gen GenMg noch null  ' + g.Gen_Menge_Stk_Mon__c);
                        g.Gen_Menge_Stk_Mon__c = g.Ant_Menge_Stk_Mon__c;
                        system.debug(logginglevel.error, '######## Bearb Gen GenMg jetzt  ' + g.Gen_Menge_Stk_Mon__c);
                    }
                }
                system.debug(logginglevel.error, '######## Bearb Gen GenMg vor add to Update list ' + g.Gen_Menge_Stk_Mon__c);
                gpToUpdate.add(g);
            }
            for (Genehmigungsposition__c g : this.positionen54){
                system.debug(logginglevel.error, '######## Bearb Gen Status ' + Genehmigung.Genehmigungsstatus__c);
                system.debug(logginglevel.error, '######## Bearb Gen AntMg  ' + g.Ant_Menge_Stk_Mon__c);
                system.debug(logginglevel.error, '######## Bearb Gen Status ' + g.Gen_Menge_Stk_Mon__c);

                if (BewilligtStatus.contains(Genehmigung.status__c)){
                    if (g.Gen_Menge_Stk_Mon__c == null){
                        g.Gen_Menge_Stk_Mon__c = g.Ant_Menge_Stk_Mon__c;
                    }
                }
                gpToUpdate.add(g);
            }
            for (Genehmigungsposition__c g : this.positionen){
                system.debug(logginglevel.error, '######## Bearb Gen Posi Grp ' + g.Artikelgruppe__c + '  GenMg ' + g.Gen_Menge_Stk_Mon__c );
            }
            for (Genehmigungsposition__c g : this.positionen54){
                system.debug(logginglevel.error, '######## Bearb Gen Posi Grp ' + g.Artikelgruppe__c + '  GenMg ' + g.Gen_Menge_Stk_Mon__c );
            }
            update gpToUpdate;
            update Genehmigung;
            system.debug('############# Genehmigung Controller ' + Genehmigung.Status__c);
            if (geschlosseneStatus.contains(Genehmigung.Status__c)){
                system.debug('############# Genehmigung Controller call CloseRelatedTasks ');
                error = CloseRelatedTasks(Genehmigung);
            }
        }
        
        return error;
    }
    
    public string getCurrentStatus() {
        return currentStatus;
    }
    
    public boolean CloseRelatedTasks(Genehmigung__c Genehmigung){
        system.debug('############# Genehmigung Controller: CloseRelatedTasks started');
        boolean error = false;
        string AutomaticDescription = 'Nachfassen bei PK wg. offener KÜ';
        list<task> RelatedOpenTasks;
        RelatedOpenTasks = [select status, subject, description from task 
                            where (isclosed = false 
                                    and WhatId =: Genehmigung.Kunde__c
                                    and Subject =: AutomaticDescription)];

        if (RelatedOpenTasks != null && RelatedOpenTasks.size() != 0){
            for (task t : RelatedOpenTasks){
                system.debug('############# Genehmigung Controller task: ' + t.status + ' / ' + t.subject + ' / ' + t.id);
                t.status = 'Abgeschlossen';
            }
            try{
                update RelatedOpenTasks;
            }
            catch (System.Dmlexception exc){
                error = true;
            }       
        }
        return error;
    }
    
    public boolean getShow51(){
            return show51;
    }   
    
    public boolean getShow54(){
            return show54;
    }   
    
    // wird nicht aufgerufen! Nur für Testabdeckung!!!  
        public class Zeile {
                
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
            List<Zeile> pZeilen = new List<Zeile>();
            Zeile dZeile = new Zeile();
            
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
               
        }   

}