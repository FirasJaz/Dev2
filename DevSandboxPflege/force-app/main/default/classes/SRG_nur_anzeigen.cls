/*/****************************************************************************************************************************
// Erstellt 13.10.2015 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.:  04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: rg.id
//
//****************************************************************************************************************************
//
// Beschreibung: create invoice as pdf
//
//****************************************************************************************************************************
//Änderungen:
//         
// 17.11.2015 AM Preis-Brutto und "Enthaltene Mwst"    
// 24.11.2015 AM Magento_kundennummer statt Kundennummer__c , Enth.Mwst in 2 Zeilen        
// 30.11.2015 BT #108844054 Es wird geprüft, ob die magento_kundennummer__c null ist.          
//****************************************************************************************************************************
*/
public with sharing class SRG_nur_anzeigen {

        public boolean isInox = false;
        public CompanyInfo__c FirmenInfo {get; set;}
        public List<Zeile> Zeilen = new List<Zeile>();
        public Integer zcount = 0;
        public Integer rcount = 0;
        public integer maxLines = 0;
        public integer maxLinesFirstPage = 11;
        public integer maxLinesNextPage = 22;
        
        public boolean MaKdNr = false;

        private  string magento_increment_id;
        private  string magento_payment_method;
                
        private  Kunde__c Kunde;
        private  Account KK;
        private  Account VP;
        private  Rechnung__c RG;
        private  Anschrift__c Anschrift;
        private  Rechnungsposition__c[] RG_Positionen ;
        private  Rechnungsposition__c[] RG_Versandkosten ;
        
        private string vorname = null;
        private string nachname = null;

        
        public class Zeile {              
                        public String Pos {get;set;}
                        public String Beschreibung {get;set;}
                        public String Menge{get;set;}
                        public String Einzelpreis {get;set;}
                        public String Gesamtpreis {get;set;}
                        public string th {get; set;}
                        public string seitenw {get;set;}
                        public string trs {get; set;}
                        public string last_th {get; set;}
        }       
        
      private string retPage = ApexPages.currentPage().getParameters().get('retURL');
         
   public SRG_nur_anzeigen() {
                this(ApexPages.currentPage().getParameters().get('id'));
            system.debug ('################################################# mansi::: SRG_nur_anzeigen' );
    }

        public SRG_nur_anzeigen(String RG_id) {
                system.debug ('################################################# mansi::: SRG_nur_anzeigen(String RG_id) ' + RG_id);
                FirmenInfo = CompanyInfo__c.getValues('Default');
                if (FirmenInfo != null) {
                        if(FirmenInfo.GF__c.contains(', ')) {
                                String[] GF = FirmenInfo.GF__c.split(', ',2);
                                FirmenInfo.GF__c = GF[0] + '<br />'+GF[1];
                        }       
                }      
        
        try {
                RG = [SELECT r.SystemModstamp, r.Name, r.MWSt2__c,
                             r.MWSt1__c, r.LastModifiedDate, r.LastModifiedById,
                             r.Kunde__c, r.IsDeleted, 
                             r.Id, r.Gesamtpreis__c, r.Gesamtpreis_Netto__c,
                             r.CreatedDate, r.CreatedById,r.createdby.name,
                             r.PDF_generiert__c, r.Rechnungsnummer_shop__c
                          FROM Rechnung__c r
                          WHERE ID = :RG_id];   
            system.debug ('################################################# mansi::: RG gefunden!' + RG);

                RG_Positionen = [SELECT SystemModstamp, Rechnung__c, Name, Einzelpreis__c,Gesamtpreis_Brutto__c, Gesamtpreis_Netto__c, MWSt1__c,
                                MWSt_Prozentsatz__c,                            
                                Id, Positionstext__c,
                                Lieferscheinposition__c, 
                                Lieferscheinposition__r.Lieferdatum__c,
                                Lieferscheinposition__r.Name,
                                Lieferscheinposition__r.Lieferschein__r.Name,                                 
                                Lieferscheinposition__r.Artikel__c,
                                Lieferscheinposition__r.Artikel__r.Name,
                                Lieferscheinposition__r.Menge__c,
                                Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_increment_id__c,
                                Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_payment_method_c__c,                           
                                Lieferscheinposition__r.Auftragsposition__r.Positionsart__c                             
                          FROM Rechnungsposition__c
                          WHERE Rechnung__c = :RG.Id and Versandkosten__c = false];

                try{
                RG_Versandkosten = [SELECT SystemModstamp, 
                                    Rechnung__c, 
                                    Name, Einzelpreis__c, Gesamtpreis_Brutto__c, Gesamtpreis_Netto__c, MWSt1__c,
                                    MWSt_Prozentsatz__c,                            
                                    Id, Positionstext__c,
                                    Lieferscheinposition__c, 
                                    Lieferscheinposition__r.Lieferdatum__c,
                                    Lieferscheinposition__r.Name,
                                    Lieferscheinposition__r.Lieferschein__r.Name,                                 
                                    Lieferscheinposition__r.Artikel__c,
                                    Lieferscheinposition__r.Artikel__r.Name,
                                    Lieferscheinposition__r.Menge__c,
                                    Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_increment_id__c,
                                    Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_payment_method_c__c,                           
                                    Lieferscheinposition__r.Auftragsposition__r.Positionsart__c                                                  
                          FROM Rechnungsposition__c
                          WHERE Rechnung__c = :RG.Id 
                          and Versandkosten__c = true limit 2];                          
                }catch(Exception e){
                system.debug ('################################################# no Versandkosten found' + e );
                }       

                Kunde = [SELECT id, Stra_e__c, Hausnummer__c, PLZ__c, Ort__c, Kundennummer__c, Name__c, Vorname__c, Magento_Kundennummer__c
                     FROM Kunde__c 
                     WHERE ID = :RG.Kunde__c];
                   
        try{  
            list<Anschrift__c> anList = [SELECT Name, Stra_e__c, komb_Adresse__c, Hausnummer__c, 
                                                PLZ__c, Ort__c, Kundenadresse__c, Art_der_Anschrift__c,
                                                Standardrechnungsanschrift__c, Shoplieferanschrift__c, Shoprechnungsanschrift__c
                                        FROM Anschrift__c 
                                          WHERE Kunde__c = :Kunde.id 
                                            ];
            Anschrift = null;
            for(Anschrift__c AN : anList) {
                if(AN.Shoprechnungsanschrift__c == true) {
                    Anschrift = AN;
                        string[] kombNamen = Anschrift.name.split(',',2);
                        nachname = kombNamen[0];
                        if(kombNamen[1] != null) {
                        vorname = kombNamen[1];
                        }
                        else vorname = ' ';             
                }
            }
            if( Anschrift == null) {
                for(Anschrift__c AN : anList) {
                    if(AN.Standardrechnungsanschrift__c == true) {
                        Anschrift = AN;
                        string[] kombNamen = Anschrift.name.split(',',2);
                        nachname = kombNamen[0];
                        if(kombNamen[1] != null) {
                        vorname = kombNamen[1];
                        }
                        else vorname = ' ';
                    }
                }
            }           
            if( Anschrift == null) {
                for(Anschrift__c AN : anList) {
                    if(AN.Art_der_Anschrift__c == 'Kundenadresse') {
                        Anschrift = AN;
                        Anschrift = AN;
                        string[] kombNamen = Anschrift.name.split(',',2);
                        nachname = kombNamen[0];
                        if(kombNamen[1] != null) {
                        vorname = kombNamen[1];
                        }
                        else vorname = ' ';                     
                    }
                }
            }
            if( Anschrift == null) {
                Anschrift = new Anschrift__c(Stra_e__c = Kunde.Stra_e__c, Hausnummer__c = Kunde.Hausnummer__c, PLZ__c = string.ValueOf(Kunde.PLZ__c), Ort__c = Kunde.Ort__c);
                vorname = Kunde.Vorname__c;
                nachname = Kunde.Name__c;
            }
        }

        catch (System.listexception lexc){
            Anschrift = new Anschrift__c(Stra_e__c = Kunde.Stra_e__c, Hausnummer__c = Kunde.Hausnummer__c, PLZ__c = string.ValueOf(Kunde.PLZ__c), Ort__c = Kunde.Ort__c);
                vorname = Kunde.Vorname__c;
                nachname = Kunde.Name__c;
 }
        if (Anschrift.Art_der_Anschrift__c == 'Kundenadresse'){
                Anschrift.Kundenadresse__c = true;
        }

                  


        maxLines = maxLinesFirstPage; 
        
// Column heade Zeile                           
        Zeile hZeile = new Zeile();               
        hZeile.Pos = 'Pos';
        hZeile.Beschreibung = 'Beschreibung';
        hZeile.Menge = 'Menge';
        hZeile.Einzelpreis= 'Einzelpreis €';
        hZeile.Gesamtpreis= 'Gesamtpreis €';
        hZeile.th = 'font-weight:bold; font-size:14px;border:0px;padding-top:5px;padding-bottom:5px;border-bottom:2px solid #000000;';  
        hZeile.last_th = 'font-weight:bold; font-size:14px;border:0px;padding-top:5px;padding-bottom:5px;border-bottom:2px solid #000000;';  
        
// leere Zeile        
        Zeile lZeile = new Zeile();
        lZeile.Pos = '';
        lZeile.Beschreibung = '';
        lZeile.th = 'color:white;border:0px;';
          
        for (Rechnungsposition__c RPS : RG_Positionen) {
                try{
                if(magento_increment_id == null){
                    magento_increment_id = RPS.Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_increment_id__c;
                    magento_payment_method = RPS.Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_payment_method_c__c;
                    }
                }
                catch (exception e){                    
                }
                Zeile tmpZeile = new Zeile();
                tmpZeile.Beschreibung = RPS.Lieferscheinposition__r.Artikel__r.Name;
                tmpZeile.Menge = string.valueOf(RPS.Lieferscheinposition__r.Menge__c);
                tmpZeile.Einzelpreis = formatCur(RPS.Einzelpreis__c);
                tmpZeile.Gesamtpreis=formatCur(RPS.Gesamtpreis_Brutto__c);
                /*if (RPS.MWSt_Prozentsatz__c != null && RPS.MWSt_Prozentsatz__c == '7.0 %') {
                    tmpZeile.stern = '*';
                } else tmpZeile.stern = '';
                */
                tmpZeile.th = 'padding-top:5px;padding-bottom:5px;border-bottom:1px solid #000000;font-size:12px;'; 
                tmpZeile.last_th = 'padding-top:5px;padding-bottom:5px;border-bottom:1px solid #000000;font-size:12px;'; 
                
  // leere Zeilen ab Seite 2
            if (zcount == 0) {                                      
                if (maxLines == maxLinesNextPage) {
                        Zeilen.add(lZeile);
                }
                Zeilen.add(hZeile);                                     
                }
            zcount++;
            
  // Seitenwechsel    
            if(zcount == maxLines ) {
                        maxLines = maxLinesNextPage;
                        tmpZeile.seitenw = 'page-break-after:always;';
                        zcount = 0;
                }
            rcount++;                           
            tmpZeile.Pos = string.valueOf(rcount);
            Zeilen.add(tmpZeile);               
        }
        // Versandkosten/Rabatt line 
        if(RG_Versandkosten != null) {
            for (Rechnungsposition__c RPSV : RG_Versandkosten) {
                Zeile tmpZeile = new Zeile();
                tmpZeile.Beschreibung = RPSV.Positionstext__c;
                tmpZeile.Menge = '';
                tmpZeile.Einzelpreis = '';
                tmpZeile.Gesamtpreis=formatCur(RPSV.Gesamtpreis_Brutto__c);
                tmpZeile.th = 'padding-top:5px;padding-bottom:5px;border-bottom:1px solid #000000;font-size:12px;'; 
                tmpZeile.last_th = 'padding-top:5px;padding-bottom:5px;border-bottom:1px solid #000000;font-size:12px;'; 
                Zeilen.add(tmpZeile); 
            }
        }
        
        // last three lines (two - AM)
                Decimal Betrag = 0;
                decimal enthMwst = RG.Gesamtpreis__c - (RG.Gesamtpreis__c / 1.19);
                
                // Zeile summeZeile = new Zeile();
                // summeZeile.Pos = '';
                // summeZeile.Beschreibung = '';
                // summeZeile.Menge = '';
                // summeZeile.Einzelpreis = 'Gesamtsumme (netto)';
                // summeZeile.Gesamtpreis= formatCur(RG.Gesamtpreis_Netto__c);
                // summeZeile.th = 'border:0px;font-weight:bold;padding-top:5px;padding-bottom:3px;'; 
                // summeZeile.last_th = 'border:0px;padding-top:5px;padding-bottom:3px;'; 
                
                // Zeilen.add(summeZeile); 
                // Betrag += RG.Gesamtpreis_Netto__c;
                
                // Zeile steuerZeile = new Zeile();
                // steuerZeile.Pos = '';
                // steuerZeile.Beschreibung = '';
                // steuerZeile.Menge = 'Enthaltene ';
                // steuerZeile.Einzelpreis = 'Mehrwertsteuer (19%)';
                // steuerZeile.Gesamtpreis= formatCur(enthMwst);
                // steuerZeile.th = 'border:0px;font-weight:normal;border-bottom:1px solid #000000;padding-bottom:5px;padding-top:5px;font-size:12px;'; 
                // steuerZeile.last_th = 'border:0px;border-bottom:1px solid #000000;padding-bottom:5px;padding-top:5px;font-size:12px;'; 
                // Zeilen.add(steuerZeile); 
                // Betrag += RG.MWSt1__c;

                Zeile betragZeile = new Zeile();
                betragZeile.Pos = '';
                betragZeile.Beschreibung = '';
                betragZeile.Menge = '';
                betragZeile.Einzelpreis = 'Betrag (brutto)';
                betragZeile.Gesamtpreis= formatCur(RG.Gesamtpreis__c); 
                betragZeile.th = 'border:0px;font-weight:bold;padding-bottom:5px;padding-top:10px;';
                betragZeile.last_th = 'border:0px;font-weight:bold;padding-bottom:5px;padding-top:10px;border-bottom:4px double#000000;'; 
                Zeilen.add(betragZeile); 

                Zeile steuerZeile = new Zeile();
                steuerZeile.Pos = '';
                steuerZeile.Beschreibung = '';
                steuerZeile.Menge = '.';
                steuerZeile.Einzelpreis = '.';
                steuerZeile.Gesamtpreis= '.';
                steuerZeile.th = 'color:#ffffff;border:0px;font-weight:normal;border-bottom:0px solid #000000;padding-bottom:5px;padding-top:5px;font-size:12px;'; 
                steuerZeile.last_th = 'color:#ffffff;border:0px;border-bottom:0px solid #000000;padding-bottom:5px;padding-top:5px;font-size:12px;'; 
                Zeilen.add(steuerZeile); 

                
                steuerZeile = new Zeile();
                steuerZeile.Pos = '';
                steuerZeile.Beschreibung = '';
                steuerZeile.Menge = '';
                steuerZeile.Einzelpreis = 'Enthaltene Mehrwertsteuer (19%)';
                steuerZeile.Gesamtpreis= formatCur(enthMwst);
                steuerZeile.th = 'border:0px;font-weight:normal;border-bottom:0px solid #000000;padding-bottom:5px;padding-top:5px;font-size:12px;padding-top:10px; text-align:left;'; 
                steuerZeile.last_th = 'border:0px;border-bottom:0px solid #000000;padding-bottom:5px;padding-top:5px;font-size:12px;padding-top:10px;'; 
                Zeilen.add(steuerZeile); 
                Betrag += RG.MWSt1__c;
                                                         
        }
        catch (System.Queryexception q) {
                system.debug ('#################################################kein RG gefunden!');
        }       
        }
        
        public string getMagento_increment_id(){
            return magento_increment_id;
        } 
        
        public string getMagento_payment_method(){
            if(magento_payment_method == 'payone_online_bank_transfer'){
                return 'Sofortüberweisung';
            }else if(magento_payment_method == 'Invoice'){
                return 'Auf Rechnung';
            }else if(magento_payment_method == 'payone_wallet'){
                return 'Paypal';
            }else if(magento_payment_method == 'payone_creditcard'){
                return 'Kreditkarte';
            }else{
                return magento_payment_method;
            }
        }

        public List<Zeile> getZeilen(){
                return Zeilen;
        }
                
        public Rechnungsposition__c[] getRG_Positionen()
        {
                        return RG_Positionen;
        }

        public Rechnung__c getRG()
        {
            if(ApexPages.currentPage().getParameters().get('inox') == '1'){
                RG.PDF_generiert__c = false;
            }
                        return RG;
        }
 
                
        public Anschrift__c getAnschrift() 
        {
            return Anschrift;
        }
     
        public string getRetPage(){
             return retPage;
        }

        public string getVorname(){
             return vorname;
        }

        public string getNachname(){
             return nachname;
        }
        
        public Kunde__c getKunde() 
        {
            return Kunde;
        }
        
        public boolean getMaKdNr()
        {  
          if(Kunde != null) {     
                if(Kunde.magento_kundennummer__c != null) {
                    MaKdNr = true;
                }
                else {
                    MaKdNr = false;
                }
          }
          else {
                  MaKdNr = false;
          }
            
            return MaKdNr;
        }
        
        public string formatCur(decimal d){
                        string s;
                        if(d != null){
                        s = d.setScale(2).format();
                        integer i =  s.lastIndexOf(',');
                        if (i < 0) {
                                s = s + ',00';
                        }
                        else if (i == s.length() - 2) {
                                s = s + '0';
                        }  
                        }
                        
                return s;
        }
        
/*                public boolean IsSandBox {
               get {
                    try {                        
                        boolean isSandbox = string.valueOf(UserInfo.getOrganizationId()).contains('00Dm000000025pE');
                        return isSandbox;                        
                         }
                     catch(system.exception e) {
                         system.debug ('############################### es war ein test');
                         return true; 
                     }                                        
                    
                    }                    
        set;               
       }        
  */ 

}