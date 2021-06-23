//****************************************************************************************************************************
// Erstellt 11.08.2015 von BT
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
// kdID
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//
//
//****************************************************************************************************************************
//
//****************************************************************************************************************************


public with sharing class inko_method {
    public List<Ausloeser> AusloeserList= new  List<Ausloeser>();    
    private list<SelectOption> InkoSelect;
    public Id KdID = ApexPages.CurrentPage().getParameters().get('id');
    private String selected; 
    private List<Artikel__c> ArtList;
    public Map<Id, Id> selArtMap = new Map<Id, Id>();
    private Decimal gesamtpreis;
    public Ausloeser del;
    public Ausloeser losch;
    public Integer rowIndex {get;set;}
    public Integer Index {get;set;}
    public List<Ausloeser> delattendeeList = new List<Ausloeser>(); 
    public List<Ausloeser> meineliste = new List<Ausloeser>(); 
    public boolean auswaehlbar ; 
    public Auftrag__c AU {get; set;}
    public List<Auftragsposition__c> ApList {get; set;}
    
    public inko_method(string dummy) {
    }
    
    public inko_method() {
    }
    
    public list<SelectOption> getInkoselect(){
        List<SelectOption> options = new List<SelectOption>();
        //options.add(new SelectOption('Inko-Artikel', 'Inko-Artikel'));
        options.add(new SelectOption('Muster-Artikel', 'Muster-Artikel'));
    
        return options;
    }
    
    public String getSelected() {
        return selected;
    }
    
    public void setSelected(String s) {
        selected = s;
    }           
     
    public List<Ausloeser> getAusloeserList()
    {    
        
        AusloeserList.clear();
        ArtList = [SELECT Menge_ABDA__c, Anlage_4_Preis__c, Artikelgruppe__c, Artikelgruppe__r.Name, name, id FROM Artikel__c WHERE Artikelgruppe__r.Name = :selected];
        for(Artikel__c art: ArtList) {
            Ausloeser Aus = new Ausloeser(art, selected);
            AusloeserList.add(Aus);
        }   
        return AusloeserList;
    }
    
    public void auftragAusloesen() {
    ApList = new List<Auftragsposition__c>();
    if((delattendeeList.size() > 0) && (delattendeeList != null)) {
        Auftrag__c auftrag = new Auftrag__c();
        auftrag.Kunde__c = KdID;
        auftrag.Auftrag_text__c = delattendeeList.get(0).inkoArt;
        auftrag.Bezeichnung__c = delattendeeList.get(0).inkoArt;
        auftrag.genehmigt_ab__c = Date.today();
        auftrag.Genehmigungsstatus__c = 'genehmigt';
        auftrag.Lieferzeitraum__c = 'Einmalig';
        AU = auftrag;
    
        for(Ausloeser aus: delattendeeList) {
            Auftragsposition__c Aufpos = new Auftragsposition__c();
            Aufpos.Kunde__c = KdID;
            Aufpos.Artikel__c = aus.A.id;
            Aufpos.Preis__c = aus.einzelpreis;  
            Aufpos.GenAnzVerp__c = Decimal.valueOf(aus.menge);
            Aufpos.Gen_Menge_Stk_Mon__c = Decimal.valueOf(aus.menge);  
            Aufpos.genehmigt_ab__c = Date.today();
            ApList.add(Aufpos);   
                          
            }
       delattendeeList.clear(); 
        }
    }
    
    public string checkAuftrag() {    
        string retMsg = 'OK';
        
        for(Ausloeser aus: delattendeeList) {
            if(aus.menge == '0') {            
            retMsg = 'Eine Menge ist gleich 0';
            return retMsg;
            }
        }
 
        return retMsg;                              
    }
    
    public void auftragEditModeOn(Auftrag__c eAU) {
        //delattendeeList.clear();        
        selected = eAU.Auftrag_text__c;
        List<Id> ArtId = new List<Id>();
        Map<Id, Decimal> ArtMap = new Map<Id, Decimal>();
        List<Auftragsposition__c> APlist = new List<Auftragsposition__c>();
        APlist = [SELECT Kunde__c, Auftrag__c, Artikel__c, Preis__c, GenAnzVerp__c, Gen_Menge_Stk_Mon__c, Genehmigungsstatus__c, name, id FROM Auftragsposition__c WHERE  Auftrag__c = :eAU.id];
        
        for(Auftragsposition__c Auf: APlist) {
            ArtId.add(Auf.Artikel__c);
            ArtMap.put(Auf.Artikel__c, Auf.Gen_Menge_Stk_Mon__c);
            selArtMap.put(Auf.Artikel__c, Auf.id);
        }
        
        ArtList = [SELECT Menge_ABDA__c, Anlage_4_Preis__c, Artikelgruppe__c, Artikelgruppe__r.Name, name, id FROM Artikel__c WHERE Artikelgruppe__r.Name = :selected AND id IN :ArtId];
        
        for(Artikel__c Art: ArtList){
                Ausloeser aus = new Ausloeser(Art, selected);
                aus.menge = string.valueOf(ArtMap.get(Art.id));
                delattendeeList.add(aus);
        }
    }
    
       public string checkEditAuftrag(Auftrag__c AU) {    
        string retMsg = 'OK';
        
        for(Ausloeser aus: delattendeeList) {
            if(aus.menge == '0')
            {
                retMsg = 'Eine Menge ist gleich 0';
                return retMsg;
            }
        }
       
        return retMsg;                              
      }
    
       public map<id, Auftragsposition__c> makeMapAP(Auftrag__c AU) { 
        map<id, Auftragsposition__c> APmap = new map<id, Auftragsposition__c>();
        Auftragsposition__c AP = new Auftragsposition__c();                

        for(Ausloeser aus: delattendeeList) {                                
                AP = new Auftragsposition__c(   Kunde__c = KdID,
                                                Auftrag__c = AU.id,
                                                Artikel__c = aus.A.id,
                                                GenAnzVerp__c = Decimal.valueOf(aus.menge),
                                                Gen_Menge_Stk_Mon__c = Decimal.valueOf(aus.menge),
                                                Genehmigungsstatus__c = 'genehmigt',                                             
                                                Preis__c = aus.einzelpreis);
                                                
            APmap.put(selArtMap.get(aus.A.id), AP); 
            system.debug ('##################################alex102 Id=' + selArtMap.get(aus.A.id));
            system.debug ('##################################alex102 AP=' + AP);
        }  
        //delattendeeList.clear();
        return APmap;                              
    }   

    public boolean getAuswaehlbar(){
        if(delattendeeList.size() < 6)
        {
            auswaehlbar = true;
        }
        else {
            auswaehlbar = false;
        }
        return auswaehlbar;
    }    
    
    public void auswaehlen(){    
        try {
         rowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('rowIndex'));
         System.debug('rowbe deleted ' + rowIndex );
         // System.debug('rowm to be deleted '+AusloeserList[rowIndex]);         
         del= AusloeserList.get(rowIndex);         
         delattendeeList.add(del);    
         }
         catch(System.Exception e) {}      
     }
     
    public void loeschen() {  
      try {    
         Index = Integer.valueOf(ApexPages.currentPage().getParameters().get('Index'));
         System.debug('rowbe deleted ' + Index );
         // System.debug('rowm to be deleted '+ delattendeeList[Index]);
         losch= delattendeeList.remove(Index);  
         }
         catch(System.Exception e) {}             
    }
    
    public List<Ausloeser> getdelattendeeList() {
         return delattendeeList; 
    }  
    
    public Decimal getGesamtpreis() {
        gesamtpreis = 0.00;
        for(Ausloeser Aus: AusloeserList) {
            gesamtpreis += Aus.preis;
            }
            
        return gesamtpreis;
    }
    

    
     public class Ausloeser 
     {
         public Artikel__c A;
         public Id id;
         public String name;
         public Decimal einzelpreis;
         public Decimal preis;
         public String menge;
         public String inkoArt;
         
         public Ausloeser(Artikel__c art, String selected)
         {
             this.A = art;
             name = A.name;
             if(A.Anlage_4_Preis__c != null) {
             einzelpreis = A.Anlage_4_Preis__c;
             }
             else {
             einzelpreis = 0.00;
             }

             inkoArt = selected;
             
             if(selected == 'Muster-Artikel') {
             einzelpreis = 0.00;
             }
             
             if(selected == 'Muster-Artikel') {
             menge = '1';
             }
             else {
             menge = '0';
             }
            
             preis = Decimal.valueOf(menge)*einzelpreis;
         }
         
         public String getName() {
             return name;
         }
                  
         public Id getId() {
             return A.id;
         }
         
         public String getInkoArt() {
             return inkoArt;
         }
         
         public Decimal getEinzelpreis() {             
             return einzelpreis; 
         }
         
         public String getMenge() {                          
             return menge; 
         }
         
         public void setMenge(String s) {
            try { 
             if((s == ' ') || (s == null) ) {
                 menge = '0';
             }
             else if(Decimal.valueOf(s)!= null){
             menge = s;
             }
             }
             catch (system.exception e){
                menge = '0';              
             }        
         }
         
         public Decimal getPreis() { 
             preis = Decimal.valueOf(menge)*einzelpreis;        
             return preis; 
         }
     
     }   
     
        public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;}
                        public string th {get; set;}
                        public string thu {get; set;}
                        public string lDatum {get; set;}
                        public string stern {get; set;}
        }

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

       }
}