/****************************************************************************************************************************
// Created 28.06.2019 von  AD
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Description:       
//
//****************************************************************************************************************************
// Changes: 
//    10.10.2019    BT    Auf Basis des Kundenstamms wird zwischen gesetzlich und nicht gesetzlich entschieden
//    04.11.2019    BT    print salutation when letter receiver is the lead record
//    01.07.2020    BT    set customer number
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Anschreiben_Blanko_Per_Post {
    private Id Kunde_id;
    private final Contact Kunde;
    private final contact_address__c Anschrift;
    private final Lead leadKunde;
    private final Account KK;
    public Id KdID = null;
    private static set<String> ids = new set<String>{};
    public string Anredeformel {get; set;}
    public string Anrede = ' ';
    public string PLZ_Ort = '';
    public CompanyInfo__c FirmenInfo {get; set;}
    public string kdNummer {get;set;}
    
    public string AGB {get; set;}

    private string retPage = ApexPages.currentPage().getParameters().get('retURL');
    private ID rcpt = ApexPages.currentPage().getParameters().get('rcpt');
    private id recordId = ApexPages.currentPage().getParameters().get('recordId');

    public string subject {get; set;}
    public string empfaenger {get; set;}   
    
    // ms 27.10.18
    public boolean gesetzlich {get; set;}
 
    public ksgFunctions.addr kdAddr = new ksgFunctions.addr();

    public ksgFunctions.addr kdAddrD = new ksgFunctions.addr();
    
    public Anschreiben_Blanko_Per_Post(integer dummy) {
    }

    public Anschreiben_Blanko_Per_Post() {
            this(ApexPages.currentPage().getParameters().get('id'));
    }
        
    public Anschreiben_Blanko_Per_Post(String Kunde_id) { 
        gesetzlich = false;
        
        try {
            Antragstext__c at = [SELECT RichText__c FROM Antragstext__c WHERE Textkey__c = 'AGB'];
            AGB = at.RichText__c;
        } catch (Exception e) {
            AGB = 'Text "AGB" in Antragstext__c missing';
        }

        Schema.DescribeSObjectResult sObjSH = Account.sObjectType.getDescribe();
        string accKeyPrefix = sObjSH.getKeyPrefix();
        sObjSH = Contact.sObjectType.getDescribe();
        string conKeyPrefix = sObjSH.getKeyPrefix();
        sObjSH = Lead.sObjectType.getDescribe();
        String leadKeyPrefix = sObjSH.getKeyPrefix(); 
        
        String strurl = ApexPages.currentPage().getUrl();
        KdID = id.valueOf(Kunde_id);        
            
        if(strurl.contains('Anschreiben_Formular_Neu')) 
            subject = 'Formular';
        if(strurl.contains('RA_nur_anzeigen_ent') || strurl.contains('Curabox_Empfangsschreiben')) //ms 27.10.18, RA_nur_anzeigen_ent-part actually obsolet (?)
            subject = 'Eingangsbestätigung';

        try {
            Contact c = [SELECT Account.Familien_ID__c 
                         FROM Contact 
                         WHERE ID = :KdID];
            kdNummer = c.Account.Familien_ID__c;
        }
        catch(System.Exception e) {
            kdNummer = '';
        }
        
        // Lead Daten
        if(string.valueOf(rcpt).substring(0, 3) == leadKeyPrefix) {
            Lead lead = [SELECT Name, firstname, lastname, salutation, Street, City, PostalCode FROM Lead WHERE ID = :rcpt LIMIT 1];
            kdAddr.vorname_name = lead.Name;
            kdAddr.strasse = lead.Street;
            kdAddr.plz_ort = lead.PostalCode + ' ' + lead.City;
            empfaenger = 'Pflegebedürftiger';
            Anrede = lead.salutation; 
            
            // 04.11.2019    BT    print salutation when letter receiver is the lead record
            kdAddr.anrede = lead.salutation;  
            kdAddr.nachname = lead.lastname;                                 
        }
            
        if(string.valueOf(rcpt).substring(0, 3) == accKeyPrefix) {
            KK = [SELECT Name, BillingCity, BillingStreet, BillingPostalCode 
                    FROM Account 
                    WHERE ID = :rcpt 
                    LIMIT 1];
            
            kdAddr.vorname_name = KK.Name;
            kdAddr.strasse = KK.BillingStreet;
            kdAddr.plz_ort = KK.BillingPostalCode + ' ' + KK.BillingCity;
            empfaenger = 'Pflegedienst';
            Anrede = ' ';
        }

        if(string.valueOf(rcpt).substring(0, 3) == conKeyPrefix) {
            Contact con = [SELECT Name, lastname, firstname, Salutation, Versichertenstatus_bei_KK__c FROM Contact WHERE ID = :rcpt LIMIT 1];
            if(con != null) {
                system.debug('####alex5600 ' + con.lastname);
                kdAddr.vorname_name = con.Name;
                kdAddr.vorname_name = (con.firstname + ' ' + con.lastname).trim();
                kdAddr.nachname = con.lastname;
                list <contact_address__c> ansch = [SELECT Street__c, Postal_code__c, City__c, Contact__r.Salutation
                                        FROM contact_address__c
                                        WHERE Contact__c = :Kunde_id 
                                    //    AND Name = :con.Name
                                        AND (Type_of_Address__c ='family member' Or Type_of_Address__c ='customer address')
                                        LIMIT 1];
                if((ansch != null) && (ansch.size() > 0)){
                    kdAddr.strasse = ansch[0].Street__c;
                    kdAddr.plz_ort = ansch[0].Postal_code__c + ' ' + Ansch[0].City__c;
                    kdaddr.anrede = ansch[0].Contact__r.Salutation;
                }
                if(kdaddr.anrede == null){
                    kdaddr.anrede = con.Salutation;
                }
                
                try {
                    Contact c = [SELECT Versichertenstatus_bei_KK__c FROM Contact WHERE ID = :recordId LIMIT 1];
                    
                    if(c != null) {
                        if(c.Versichertenstatus_bei_KK__c == 'gesetzlich') {
                            gesetzlich = true;
                        }
                    }
                }
                catch(System.Exception e) {}
            }
            system.debug('####alex5600 ' + kdAddr.nachname);
            empfaenger = 'AnsprechpartnerIn';
        }

        /*
        if(string.valueOf(rcpt).substring(0, 3) == kunKeyPrefix) {
            kdAddr.anrede = Kunde.Salutation;
            kdAddr.vorname_name = (Kunde.firstname + ' ' + Kunde.lastname).trim();
            kdAddr.strasse = Kunde.mailingstreet;
            kdAddr.plz_ort = ksgFunctions.formatPLZ(Decimal.valueOf(Kunde.mailingpostalcode)) + ' ' + Kunde.mailingcity;
            kdAddr.nachname = Kunde.Name;
            empfaenger = 'Pflegebedürftiger';
        }*/
        // Anredeformel = kdAddr.Anredeformelsetzen(); 
        
        kdAddrD.anrede = kdAddr.anrede;
        kdAddrD.vorname_name = kdAddr.vorname_name;
        kdAddrD.strasse = kdAddr.strasse;
        kdAddrD.plz_ort = kdAddr.plz_ort;
        kdAddrD.nachname = kdAddr.nachname;
        kdAddrD.kdnachname = kdAddr.kdnachname;
        kdAddrD.kdvorname = kdAddr.kdvorname;       
        kdAddr.anrede = kdAddrD.anrede;
        kdAddr.vorname_name = kdAddrD.vorname_name;
        kdAddr.strasse = kdAddrD.strasse;
        kdAddr.plz_ort = kdAddrD.plz_ort;
        kdAddr.nachname = kdAddrD.nachname;  
        kdAddr.kdnachname = kdAddrD.kdnachname;  
        kdAddr.kdvorname = kdAddrD.kdvorname;        
        //
        Anredeformel = kdAddr.Anredeformelsetzen();
        
        list<contact_address__c>  kdAnsch = [SELECT Street__c
                                        FROM contact_address__c 
                                        WHERE Contact__c = :Kunde_id 
                                        AND Standard_shipping_address__c=:true LIMIT 1] ;     
        if((kdAnsch != null) && (kdAnsch.size() > 0)) {     
            Anschrift = kdAnsch[0];
        }
        else {
            Anschrift = new contact_address__c(Street__c = kdAddr.strasse); 
        }
        
        FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            if(FirmenInfo.GF__c.contains(', ')){
                String[] GF = FirmenInfo.GF__c.split(', ',2);
                FirmenInfo.GF__c = GF[0] + '<br />'+GF[1];
            }
        }
    }
        
    public Contact getKunde(){
        return Kunde;
    }
    public contact_address__c getAnschrift(){       
        return Anschrift;
    } 
    
    public Account getKK() {
        return KK;
    }

    public Lead getLead(){
        return leadKunde;
    } 
    
    public String getAnredeformel(){
        return Anredeformel;
    }
    public string getRetPage(){
        return retPage;
    }
        
    public CompanyInfo__c getFirmenInfo(){
        return FirmenInfo;
    }
    
    public ksgFunctions.addr getKdAddr(){
        return kdAddr;
    } 
    
    public ksgFunctions.addr getKdAddrD(){
        return kdAddrD;
    }

    public void addFollowUpTask() {
        Follow_Up_Task_Helper.insertFollowUpTask(rcpt, 
                                                subject + ' gedruckt.', 
                                                subject + ' gedruckt. Empfänger ' + empfaenger, 
                                                date.today(), 
                                                'Geschlossen');
    }
}