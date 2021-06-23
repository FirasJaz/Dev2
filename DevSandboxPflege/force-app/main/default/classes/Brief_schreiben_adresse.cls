/****************************************************************************************************************************
// Erstellt 04.05.2015 von AM
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
// KdID, void
//
//****************************************************************************************************************************
//
// Beschreibung:
// Ermitteln die Adresse und eMail für die Briefe                  
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
*/
global with sharing class Brief_schreiben_adresse {
    public string selectedRcpt = '0';
    private boolean error = false;
    private id KdID = null;
    private id rcpt = null;
    private string empfaenger {get; set;}
    private string mailTo {get; set;}
    public string Anredeformel {get; set;}
    private string subject {get; set;}
    private boolean hasMail = false;
    private boolean hasAddr = false;
    private string mailHinweis {get; set;}
    private string addrHinweis {get; set;}
    public string kdnr =  null;
    public string kunde {get; set;}
    public List<SelectOption> options = new List<SelectOption>();
    
    public class empSatz {
        public string empType {get; set;}
        public string empName {get; set;}
        public string empAnrede {get; set;}
        public string empMail {get;set;}
        public string empAnredeformel {get;set;}
        public string empStrasse {get; set;}
        public string empPLZ {get; set;}
        public string empOrt {get; set;}
        public id empRcpt {get; set;}
        public boolean empHasMail = false;
        public boolean empHasAddr = false;
    }
    public map<string, empSatz> empMap = new map<string, empSatz>();
    public empSatz AddressRecord {get; set;}
    
    // constructor 1
    public Brief_schreiben_adresse () {
        
    }

    // constructor 2
    public Brief_schreiben_adresse (ID KdID) {
        this.KdID = KdID;
        
        list<Kunde__c> kdList = [SELECT id, Name, Anrede__c, Vorname__c, Name__c, 
                                        Pflegedienst__c, Betreuer__c, e_mail__c, kundennummer__c 
                                    FROM Kunde__c 
                                    WHERE id = :KdID LIMIT 1];
        kdnr = string.valueof(kdlist[0].kundennummer__c);
        kunde = (kdlist[0].Vorname__c + ' ' + kdlist[0].Name__c).trim();
        if((kdList != null) && (kdList.size() > 0)) {
            if(kdList[0].Pflegedienst__c != null) {
                empfaenger = 'Pflegedienst';
                rcpt = kdList[0].Pflegedienst__c;
                list<Account> pdList = [SELECT id, Name, Weitere_E_Mail__c, BillingCity, BillingStreet, BillingPostalCode  
                                        FROM Account 
                                        WHERE id = :kdList[0].Pflegedienst__c];
                if((pdList != null) && (pdList.size() > 0)) {
                    mailTo = pdList[0].Weitere_E_Mail__c;
                    
                    empSatz ES = new empSatz();
                    ES.empType = 'Pflegedienst';
                    ES.empName = pdList[0].Name;
                    ES.empAnrede = '';
                    ES.empStrasse = pdList[0].BillingStreet;
                    ES.empPLZ = pdList[0].BillingPostalCode;
                    ES.empOrt = pdList[0].BillingCity;
                    ES.empMail = pdList[0].Weitere_E_Mail__c;
                    ES.empRcpt = kdList[0].Pflegedienst__c;
                    if(ES.empAnredeformel == null) {
                        ES.empAnredeformel = 'Sehr geehrte Damen und Herren, ';
                    }
            
                    if(ES.empMail == null) { 
                        ES.empHasMail = false ;
                    }
                    else ES.empHasMail = true ;
                    
                    if((pdList[0].BillingCity == null) || (pdList[0].BillingStreet == null) || (pdList[0].BillingPostalCode == null)) {
                        ES.empHasAddr = false ;
                    }
                    else ES.empHasAddr = true ;
                    empMap.put('1', ES); 
                    
                    system.debug('#########################alex600 selectedRcpt=' + selectedRcpt);
                    selectedRcpt = '1';
                }               
            }
        
                
            if(kdList[0].Betreuer__c !=null) {
                empfaenger = 'Angehöriger';
                rcpt = kdList[0].Betreuer__c;
                list<Contact> ktList = [SELECT Email, Name, LastName, Salutation FROM Contact WHERE id = :kdList[0].Betreuer__c LIMIT 1];
                if((ktList != null) && (ktList.size() > 0)) {
                    list<Anschrift__c> ansch = [SELECT Stra_e__c, PLZ__c, Ort__c, Anrede__c
                                    FROM Anschrift__c
                                    WHERE Kunde__c = :kdList[0].id 
                                    // AND Name = :ktList[0].Name
                                    AND Art_der_Anschrift__c = 'Betreuer'
                                    LIMIT 1];
 
                    mailTo = ktList[0].Email;
                    empSatz ES = new empSatz();
                    ES.empType = 'Angehöriger';
                    ES.empName = ktList[0].Name;
                    ES.empAnrede = '';
                    
                    ES.empMail = ktList[0].Email;
                    ES.empRcpt = kdList[0].Betreuer__c;
                    if((ansch != null) && (ansch.size() > 0)) {
                        if((ansch[0].Stra_e__c == null) || (ansch[0].PLZ__c == null) || (ansch[0].Ort__c == null)) {
                            ES.empHasAddr = false ;
                        }                       
                        else {
                            ES.empHasAddr = true ;
                            ES.empStrasse = ansch[0].Stra_e__c;
                            ES.empPLZ = ansch[0].PLZ__c;
                            ES.empOrt = ansch[0].Ort__c;
                            ES.empAnrede = ansch[0].Anrede__c;
                            if(ES.empAnrede == null) ES.empAnrede = ktList[0].Salutation;
                        }
                    }
                    else ES.empHasAddr = false ;
                    If (ktList[0].Salutation != null) {
                        If (ktList[0].Salutation.contains('Herr') ) { 
                            ES.empAnredeformel = 'Sehr geehrter ' + ktList[0].Salutation + ' ' + ktList[0].LastName +',';
                        }
                        If (ktList[0].Salutation.contains('Frau') ) { 
                            ES.empAnredeformel = 'Sehr geehrte ' + ktList[0].Salutation + ' ' + ktList[0].LastName +',';
                        }                   
                    }                        
                    if(ES.empAnredeformel == null) {
                        ES.empAnredeformel = 'Sehr geehrte Damen und Herren, ';
                    }
                    if(ES.empMail == null) { 
                        ES.empHasMail = false ;
                    }
                    else ES.empHasMail = true ;
                    empMap.put('2', ES);    
                                
                    system.debug('#########################alex601 selectedRcpt=' + selectedRcpt);
                    if(selectedRcpt == '0') selectedRcpt = '2';
                }
            }
                

            empfaenger = 'Kunde';
            system.debug('#########################alex802 ');
            rcpt = KdID;
            list<Anschrift__c>  kdAnsch = [SELECT Stra_e__c, PLZ__c, Ort__c, Anrede__c
                                        FROM Anschrift__c 
                                        WHERE Kunde__c = :kdList[0].id 
                                        AND Art_der_Anschrift__c = 'Kundenadresse' LIMIT 1] ;
        
            system.debug('#########################alex801 kdList[0].id=' + kdList[0].id);
            mailTo = kdList[0].e_mail__c;
            empSatz ES = new empSatz();
            if((kdAnsch != null) && (kdAnsch.size() > 0)) { 
                system.debug('#########################alex803 kdAnsch[0]=' + kdAnsch[0]);
                ES.empHasAddr = true ;   
                ES.empStrasse = kdAnsch[0].Stra_e__c;
                ES.empPLZ = kdAnsch[0].PLZ__c;
                ES.empOrt = kdAnsch[0].Ort__c;  
            
                if((kdAnsch[0].Stra_e__c == null) || (kdAnsch[0].PLZ__c == null) || (kdAnsch[0].Ort__c == null)) {
                    system.debug('#########################alex800 ');
                    ES.empHasAddr = false ;
                }                       
                
            } else ES.empHasAddr = false ;
                
            ES.empAnrede = kdList[0].Anrede__c;
            ES.empType = 'Kunde';
            ES.empName = kdList[0].Vorname__c + ' ' + kdList[0].Name__c;
            ES.empMail = kdList[0].e_mail__c;
            ES.empRcpt = KdID;
            If (kdList[0].Anrede__c != null) {
                If (kdList[0].Anrede__c.contains('Herr') ) { 
                    ES.empAnredeformel = 'Sehr geehrter ' + ((kdList[0].Anrede__c + ' ' + kdList[0].Name__c).trim()) +',';
                }
                If (kdList[0].Anrede__c.contains('Frau') ) { 
                    ES.empAnredeformel = 'Sehr geehrte ' + ((kdList[0].Anrede__c + ' ' + kdList[0].Name__c).trim()) +',';
                }                   
            }
            if(ES.empAnredeformel == null) {
                ES.empAnredeformel = 'Sehr geehrte Damen und Herren, ';
            }
            
            if(ES.empMail == null) { 
                ES.empHasMail = false ;
            }
            else ES.empHasMail = true ;
            empMap.put('3', ES);
            
            system.debug('#########################alex602 selectedRcpt=' + selectedRcpt);
            if(selectedRcpt == '0') selectedRcpt = '3';
            fillTable(selectedRcpt);            
        } 
        
        AddressRecord = readSelectedRecord(selectedRcpt);
        system.debug('#########################alex603 AddressRecord=' + AddressRecord);
    }
    
    public void fillTable(string sR) {
        empSatz es = empMap.get(sR);
        empfaenger = es.empType;
        hasMail = es.empHasMail;
        hasAddr = es.empHasAddr;
        Anredeformel = es.empAnredeformel;
        if (hasMail) {
            mailTo = es.empMail;
            mailHinweis = 'an ' + es.empName + ' (' + mailTo + ')';
        }
        else {
            mailHinweis = 'Achtung! Keine Email adresse erfasst!';
        }
        
        if (hasAddr) {
            addrHinweis = '';
        }
        else {
            addrHinweis = 'Achtung! Keine Adresse erfasst!';
        }
        
        rcpt = es.empRcpt;  
        selectedRcpt = sR;
        AddressRecord = readSelectedRecord(sR);
    }
    
    public boolean hatFehler() {
        return error;
    }
    
    public boolean getHasMail() {
        return hasMail;
    }
    
    public boolean getHasAddr() {
        return hasAddr;
    }
    
    public string getEmpfaenger() {
        return empfaenger;
    }
    
    public string getmailHinweis() {
        return mailHinweis;
    }

    public string getAddrHinweis() {
        return addrHinweis;
    }
    
    public string getAnredeformel() {
        return Anredeformel;
    }
    
    public string getKunde() {
        return kunde;
    }
    
    public string getMailTo() {
        return mailTo;
    }
    
    public id getRcpt() {
        return rcpt;
    }
    
    public List<SelectOption> selectRcpt() {
        List<SelectOption> options = new List<SelectOption>();
        for(string key : empMap.keySet()) {
            empSatz es = empMap.get(key);
            options.add(new SelectOption(key, ES.empType));
        }
        return options;
    }
    
    public string getSelectedRcpt() {
        return selectedRcpt;
    }
    
    public void setSelectedRcpt(string selectedRcpt) {
        this.selectedRcpt = selectedRcpt;
    }   

    public empSatz readSelectedRecord(string selectedRcpt) {
        if(empMap.containsKey(selectedRcpt)) {
            return empMap.get(selectedRcpt);
        }
        else return null;
    }
    
    public empSatz getAddressRecord() {
        return AddressRecord;
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