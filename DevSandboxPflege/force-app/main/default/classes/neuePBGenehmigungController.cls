//****************************************************************************************************************************
// Erstellt tt.mm.yyyy von Feldeisen
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
// möglichst konkrete Beschreibung der Funktion der Klasse!
//
//
//****************************************************************************************************************************
//Änderungen:
//
// 13.05.2015 von wds     KUWV wieder eingebaut #127
//                           
//****************************************************************************************************************************


public with sharing class neuePBGenehmigungController {
//
//  2014-05-20 wds WSIG Bezug rausgenommen
//
    //public variablen
    public ApexPages.standardController controller {get; set;}
    //private variablen
    private string retPage = ApexPages.currentPage().getParameters().get('retURL');
    private string nextPage = ApexPages.currentPage().getParameters().get('nextURL');
//  ************************************
    public Genehmigung__c Genehmigung { get; set; }
    public Genehmigungsposition__c EH { get; set; }
    //public id KdID = null;
    public ID KdID = ApexPages.CurrentPage().getParameters().get('kdid');
    public id zurZuKd = null;
    public boolean show51 = false;
    public boolean show54 = true;
    public List<Genehmigungsposition__c> positionen { get; set; }
    public List<Genehmigungsposition__c> positionen54 { get; set; }
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
    
     public neuePBGenehmigungController() {}
    //der constructor
    public neuePBGenehmigungController(ApexPages.StandardController stdController) {
        // constructor
        controller = stdController;
        date Heute = date.today();
        this.Genehmigung = (Genehmigung__c)stdController.getRecord();
        if(KdID == null) {
            KdID = Genehmigung.Kunde__c;
        }
        else {
            zurZuKd = KdID;
            if(Genehmigung.Kunde__c == null) Genehmigung.Kunde__c = KdID;
        }
        this.Genehmigung.Antrag_eingegangen_am__c = Heute;
        this.positionen = new List<Genehmigungsposition__c>();  
        this.positionen54 = new List<Genehmigungsposition__c>();
        
        Pflegebox__c pb = [SELECT id FROM Pflegebox__c WHERE editierbar__c = true LIMIT 1];
        list<Artikelgruppe__c> agList = [SELECT id, Name, Positionsnummer__c    
                                                        FROM Artikelgruppe__c 
                                                        WHERE Artikelgruppe_Logik__c != true]; 
        
        if((agList!= null) && (agList.size() > 0)) {
            for (Artikelgruppe__c vpag : agList) {
                this.EH = new Genehmigungsposition__c();
                EH.Artikelgruppe__c = vpag.id;
                EH.Artikelgruppe__r = vpag;
                EH.Ant_Menge_Stk_Mon__c = 10;
                EH.Ant_Menge_Stk__c = 10;
                
                if(vpag.Positionsnummer__c != null) {
                    system.debug('############# wds Positionsnr und Substring ' + vpag.Positionsnummer__c + ' / ' + vpag.Positionsnummer__c.substring(0, 2));
                    
                    if ( vpag.Positionsnummer__c.substring(0, 2)== '54')
                    {
                        this.positionen.add(EH);
                    }
                    else
                    {
                        this.positionen54.add(EH);
                    } 
                }
                
            }
        }


        

    }
    
    
    
    public PageReference neueGenehmigungSichern() {
                
        system.debug ('####################### retPage ' + retPage);
        Genehmigung__c Genehmigung = this.Genehmigung;
        Boolean error = neuenGenehmigungSichern(Genehmigung);
        PageReference returnPage = null;
        // nur wenn eine retUrl übergeben wird, wird mit dieser eine PageReference initialisiert
        // sonst mit der kundenummer, d.h. nach erstellen eines kunden wird man auf die detail-seite umgeleitet
        system.debug('########## '+Genehmigung.Id + ' Genehmigung: '+ Genehmigung);
        if(nextPage != null) {
            returnPage = new PageReference(nextPage);
            returnPage.getParameters().put('fmType', 'eingangsbest');
            returnPage.getParameters().put('id', Genehmigung.Kunde__c);
        }
        else {
            if(retPage != null){
                returnPage = new PageReference(retPage);
            } else {
                if(zurZuKd == null) {
                    returnPage = new PageReference('/'+Genehmigung.Id);
                }
                else returnPage = new PageReference('/'+ zurZuKd);
            }
        }
        if ( error ){
               returnPage = null;
        } else {
            returnPage.setRedirect(true);
        }
        return returnPage;
    }

    public PageReference neueGenehmigungZurueck() {
        PageReference returnPage = null;    
        if(zurZuKd == null) {
            returnPage = new PageReference('/'+Genehmigung.Id);
        }
        else returnPage = new PageReference('/'+ zurZuKd);
        
        returnPage.setRedirect(true);
        return returnPage;
    }

    public string getRetPage(){
            return retPage;
    }    

    public Boolean neuenGenehmigungSichern (Genehmigung__c Genehmigung){
        Boolean error = False;
        Boolean pos51hasitem = false;
        Boolean pos54hasitem = false;
        set<string> BewilligtStatus = new set<string>{'Bewilligung', 'Teilbewilligung'};
        Set<string> geschlosseneStatus = new set<string>{'Bewilligung', 'Teilbewilligung', 'Ablehnung'};
        for (Genehmigungsposition__c g : this.positionen){
            if(g.Ant_Menge_Stk_Mon__c!=null&&g.Ant_Menge_Stk_Mon__c != 0){
                pos54hasitem = true;
                  system.debug('############# wds pos54hasitem' + pos54hasitem );
                break;
            }
        }
        for (Genehmigungsposition__c g : this.positionen54){
            if(g.Ant_Menge_Stk__c!=null&&g.Ant_Menge_Stk__c != 0){
                pos51hasitem = true;
                system.debug('############# wds pos51hasitem' + pos51hasitem );
                break;
            }
        }
        
        //Lege Genehmigung an:

        if(show51){
            Genehmigung__c g51 = new Genehmigung__c(Kunde__c = Genehmigung.Kunde__c, Name__c = 'PG51', 
                                                    genehmigt_ab__c = Genehmigung.genehmigt_ab__c, genehmigt_bis__c = Genehmigung.genehmigt_bis__c,
                                                    unbefristet_genehmigt__c = Genehmigung.unbefristet_genehmigt__c,
                                                    Nach_Paragraph__c = '51', Status__c = Genehmigung.Status__c, 
                                                    Antrag_eingegangen_am__c = Genehmigung.Antrag_eingegangen_am__c,
                                                    Antrag_versandt_am__c = Genehmigung.Antrag_versandt_am__c,
                                                    Antrag_beantwortet_am__c = Genehmigung.Antrag_beantwortet_am__c);
                                                    
            insert g51;
            system.debug('#############alex001 wds positionen54.size()' + positionen54.size() );
            for (Genehmigungsposition__c g : this.positionen54){
                if(g.Ant_Menge_Stk__c != null && g.Ant_Menge_Stk__c != 0){
                    if (g.genehmigung__c == null){
                    g.Genehmigung__c = g51.Id;}
                    if(g.genehmigt_ab__c == null){
                        g.genehmigt_ab__c = Genehmigung.genehmigt_ab__c;
                    }
                    if(g.genehmigt_bis__c == null){
                        g.genehmigt_bis__c = Genehmigung.genehmigt_bis__c;
                    }
                    if (BewilligtStatus.contains(Genehmigung.status__c)){
                        if (g.Gen_Menge_Stk_Mon__c == null){
                            g.Gen_Menge_Stk_Mon__c = g.Ant_Menge_Stk_Mon__c;
                        }
                    }
                    insert g;
                    system.debug('############# wds insert 54'  );
                }
            }       
            
        }
        
        //Lege Positionen an
        if(show54) {
            Genehmigung__c g54 = new Genehmigung__c(Kunde__c = Genehmigung.Kunde__c, Name__c = 'PG54', 
                                                    genehmigt_ab__c = Genehmigung.genehmigt_ab__c, genehmigt_bis__c = Genehmigung.genehmigt_bis__c,
                                                    unbefristet_genehmigt__c = Genehmigung.unbefristet_genehmigt__c,
                                                    Nach_Paragraph__c = '54', Status__c = Genehmigung.Status__c, 
                                                    Antrag_eingegangen_am__c = Genehmigung.Antrag_eingegangen_am__c,
                                                    Antrag_versandt_am__c = Genehmigung.Antrag_versandt_am__c,
                                                    Antrag_beantwortet_am__c = Genehmigung.Antrag_beantwortet_am__c);
                                                    
            insert g54;
            
            system.debug('#############alex002 wds positionen.size()' + positionen.size() );
            for (Genehmigungsposition__c g : this.positionen){
                if(g.Ant_Menge_Stk_Mon__c != null && g.Ant_Menge_Stk_Mon__c != 0){
                    g.Genehmigung__c = g54.Id;
                    if(g.genehmigt_ab__c == null){
                        g.genehmigt_ab__c = Genehmigung.genehmigt_ab__c;
                    }
                    if(g.genehmigt_bis__c == null){
                        g.genehmigt_bis__c = Genehmigung.genehmigt_bis__c;
                    }
                    if (BewilligtStatus.contains(Genehmigung.status__c)){
                        if (g.Gen_Menge_Stk_Mon__c == null){
                            g.Gen_Menge_Stk_Mon__c = g.Ant_Menge_Stk_Mon__c;
                        }
                    }

                    insert g;
                    system.debug('############# wds insert 51'  );
                    
                }
            }
        }

        if (geschlosseneStatus.contains(Genehmigung.Genehmigungsstatus__c)){
            system.debug('############# Genehmigung Controller call CloseRelatedTasks ');
            error = CloseRelatedTasks(Genehmigung);
        }
        return error;
    }
    
    public string getKdID(){
            return KdID;
    }   
    
    public boolean getShow51(){
            return show51;
    }   
    
    public boolean getShow54(){
            return show54;
    }   
    
    public PageReference selectPG(){
     show54 = false;
     show51 = false;
     system.debug('#############alex001 Genehmigung.Nach_Paragraph__c='+Genehmigung.Nach_Paragraph__c  );
     if(Genehmigung.Nach_Paragraph__c == '54'){
          show54 = true;
     }
     if(Genehmigung.Nach_Paragraph__c == '51'){
          show51 = true;
     }
     if(Genehmigung.Nach_Paragraph__c == '5X'){
          show54 = true;
          show51 = true;
     }
     return null;
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