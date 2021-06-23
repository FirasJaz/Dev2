/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//      Abrechnung normaler genehmigungen - CSV nachträglich erzeugen
// 
//
// Änderungen:
// 05.10.2016    BT    Bei Zuzahlung wird der Privatanteil herausgenommen. Der Kostenanteil PK entspricht der Gesamtsumme.   
//      geändert am 17.11.2017  durch AM        Pivotal Tracker:   #152753550                      
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global with sharing class AB_CSV {
    public Integer noOfRecords{get; set;}
    public Integer size{get;set;}
    public integer counter=0;  //keeps track of the offset
    public integer list_size=20; //sets the page size or number of rows
    public integer total_size; //used to show user the total size of the list  
    public string kkName = '';  
    public string kkstr = '';
    public boolean Aufruf = true;
    public boolean ButtonVersenden = false;
    public asMail__c asMail {get; set;}
    public string toAddrCSV = 'alex.mischenko@freenet.de';
    public string toCCCSV = 'alex.mischenko@freenet.de';
    public transient list<Lieferbest_tigung__c> lbList = new list<Lieferbest_tigung__c>();
    
    public transient List<Lieferscheinposition__c> LPall = new List<Lieferscheinposition__c>();
    public boolean hasNormal = false;
    public boolean hasBeihilfe = false;
    public boolean hasPrivat = false;
    
    public map<id, id> abbMap = new map<id, id>();
    public map<id, id> genMap = new map<id, id>();
    public map<id, Genehmigung__c> kdGenMap = new map<id, Genehmigung__c>();
    public map<string, Rechnung__c> rgMap = new map<string, Rechnung__c>();
    public map<id, Anschrift__c> raMap = new map<id, Anschrift__c>();
    
    public map<id, string> lsrgMap = new map<id, string>();
    
    public string errorMsg = null; 
    
    private boolean csvError = false;
    
    public string maNummer = '1618';
    
    public AB_CSV() {
        kkName = ApexPages.CurrentPage().getParameters().get('kk');
        String los = ApexPages.CurrentPage().getParameters().get('call');
        if (los == 'los') {
            Aufruf = false;
            kkstr = ApexPages.CurrentPage().getParameters().get('kk').trim();
        }
        else {
            if(errorMsg == null)
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Geben Sie die Rechnungsnummern ein.<br>Durch Komma getrennt<br>Die CSV-Dateien werd per E-Mail gesendet.  '));    
        }       
    }
    
    public ApexPages.StandardSetController setCon {
        get{
            string[] rgNamen = new list<string>();
            set<string> tSet = new set<string>();
            system.debug('#########################alex401 kkstr='  + kkstr);
            if(setCon == null){
                if((kkstr == null) || (kkstr == '')) kkstr = 'dummy';
                if(kkstr.contains(',')) {
                    rgNamen = kkstr.split(',');
                }
                else rgNamen.add(kkstr);
                size = list_size;
                
                for(string kk : rgNamen) {
                    system.debug('#########################alex407 kk='  + kk);
                    tSet.add(kk.trim());
                }
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [
                    SELECT Name,
                          Lieferschein__c,
                          Lieferschein__r.Name,
                          Kunde__c,
                          Kunde__r.Name,


                          Kunde__r.Beihilfeberechtigt__c,
                          Kunde__r.Abrechnung_direkt_mit_PPK__c,
                          Kunde__r.Medifox_2__c,
                          Lieferschein__r.Kunde_Zuzahlung_befreit__c,
                          Auftragsposition__c,

                          Auftragsposition__r.GenAnzVerp__c,
                          Auftragsposition__r.Auftrag__c,


                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Name,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c,
                          Artikel__c,
                          Artikel__r.Name,

                          Artikel__r.Anlage_4_Preis__c,

                          Menge__c,
                          AZ_von__c,
                          AZ_bis__c,
                          VZ_von__c,
                          VZ_bis__c,
                          Lieferdatum__c
                     FROM Lieferscheinposition__c                                                           
                    WHERE Lieferschein__c IN (
                        SELECT Lieferschein__c FROM Lieferbest_tigung__c WHERE Rechnungsname__c IN :tSet)
                        AND Abrechnungsstatus_Krankenkasse__c IN ('abgerechnet', 'Abgerechnet über AS-B')
                        ORDER BY Lieferschein__r.Name]));
                setCon.setPageSize(size);
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
        }set;
    }

    public List<Lieferscheinposition__c> zumAbrechnen  
    {  
        get  
        {  
            if(setcon != null)  
                return (List<Lieferscheinposition__c>)setcon.getRecords();  
            else  
                return null ;  
        }  
        set;
    }

    public boolean getAufruf(){
            return Aufruf;
    }
    
    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }
  
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }
    
    public void first() {        
        setCon.first();
    }
  
    public void last() {       
        setCon.last();
    }
  
    public void previous() {        
        setCon.previous();
    }
  
    public void next() {        
        setCon.next();
    }

    public boolean getButtonVersenden() {
        if((!Aufruf) && ((setCon != null && noOfRecords != 0)) ){
            return true;
        } else return false;
   }
   
    public string getKkName () {         
            return kkName;
   }
  
    public void setKkName (string kkName) {          
            this.kkName = kkName;
   }
   
   public PageReference createAndSend() {  
        createNormal(kkstr, false);
        createPrivate(kkstr, false);
   
        // return null;
        PageReference pr = new PageReference('/apex/AB_CSV');
        pr.setRedirect(true);
        return pr;      
   }
   
   public static void createOnly(string rgName) {  
        createNormal(rgName, true);
        createPrivate(rgName, true); 
   }


@future(callout=true)
public static void createPrivate(string rechnungen, boolean perEmail) {
        system.debug('#########################alex34001 getHeapSize='  + Limits.getHeapSize());
        asMail__c asMail = asMail__c.getValues('asb');
        String subject, toAddr, toCC, PlainTextBody;
        try {
            subject = asMail.subject__c;
            toAddr = asMail.toAddr__c;
            toCC = asMail.toCC__c;
            PlainTextBody = asMail.body__c;
        }
        catch (System.Exception e) {
            subject = 'Abrechnung';
            toAddr = 'kontakt@klosesrockepartner.de';
            toCC = null;
            PlainTextBody =  ' ';
        }

        set<id> LsSet = new set<id>();
        set<id> KdSet = new set<id>();
        set<id> KdOhneGenSet = new set<id>();
        set<id> genIdSet = new set<id>();
        boolean medifox54 = false;
        boolean nonmedifox54 = false;
        boolean medifox51 = false;
        boolean nonmedifox51 = false;
        string[] rgNamen = new list<string>();
        set<string> tSet = new set<string>();
        
        list<Lieferbest_tigung__c> lbList = new list<Lieferbest_tigung__c>();
        boolean hasNormal = false;
        boolean hasBeihilfe = false;
        boolean hasPrivat = false;      
        map<id, id> abbMap = new map<id, id>();
        map<id, id> genMap = new map<id, id>();
        map<id, Genehmigung__c> kdGenMap = new map<id, Genehmigung__c>();
        map<string, Rechnung__c> rgMap = new map<string, Rechnung__c>();
        map<id, Anschrift__c> raMap = new map<id, Anschrift__c>();    
        map<id, string> lsrgMap = new map<id, string>();    
        string errorMsg = null;     
        boolean csvError = false;   
        string maNummer = '1618';       
        
        system.debug('#########################alex401 rechnungen='  + rechnungen);
            if(rechnungen.contains(',')) {
                rgNamen = rechnungen.split(',');
            }
            else rgNamen.add(rechnungen);    
                for(string kk : rgNamen) {
                    system.debug('#########################alex407 kk='  + kk);
                    tSet.add(kk.trim());
                }
            
        List<Lieferscheinposition__c> LPall = [
                    SELECT Name,
                          Lieferschein__c,
                          Lieferschein__r.Name,
                          Lieferschein__r.Lieferadresse__c,
                          Lieferschein__r.Genehmigung__c,
                          Lieferschein__r.Genehmigung__r.Genehmigungsnummer__c,
                          Lieferschein__r.Genehmigung__r.genehmigt_ab__c,
                          Lieferschein__r.Kunde_Zuzahlung_befreit__c,
                          Kunde__c,
                          Kunde__r.Name,
                          Kunde__r.Versichertennummer__c,
                          Kunde__r.Name__c,
                          Kunde__r.Vorname__c,
                          Kunde__r.Anrede__c,
                          Kunde__r.Geburtsdatum_text__c,
                          Kunde__r.Beihilfeberechtigt__c,
                          Kunde__r.Abrechnung_direkt_mit_PPK__c,
                          Kunde__r.Medifox_2__c,
                          Kunde__r.Kundennummer_abena__c,
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
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.TK__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.AC__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.PG51_Abrechnungs_Methode__c,  
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c,                       
                          Artikel__c,
                          Artikel__r.Name,
                          Artikel__r.a_pac_apo_Mwst__c,
                          Artikel__r.Artikelgruppe__c,
                          Artikel__r.Anlage_4_Preis__c,
                          Artikel__r.Pflege_Hilfsmittelnr__c,
                          Artikel__r.v_pos_1_Name__c,
                          Menge__c,
                          AZ_von__c,
                          AZ_bis__c,
                          VZ_von__c,
                          VZ_bis__c,
                          Lieferdatum__c
                          
                     FROM Lieferscheinposition__c                                                           
                    WHERE Lieferschein__c IN (
                        SELECT Lieferschein__c FROM Lieferbest_tigung__c WHERE Rechnungsname__c IN :tSet) 
                        AND ((  Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c = 'privat') OR (Kunde__r.Abrechnung_direkt_mit_PPK__c = true))
                        AND Abrechnungsstatus_Krankenkasse__c IN ('abgerechnet', 'Abgerechnet über AS-B')
                        ORDER BY Lieferschein__r.Name];  
            
        if((LPall != null) && (LPall.size() >0)) {
            system.debug('#########################alex34002 getHeapSize='  + Limits.getHeapSize());
            for(Lieferscheinposition__c LP : LPall) {
                LsSet.add(LP.Lieferschein__c);
                KdSet.add(LP.Kunde__c);
                if(LP.Lieferschein__r.Genehmigung__c == null) KdOhneGenSet.add(LP.Kunde__c);
                if(LP.Artikel__r.v_pos_1_Name__c != '51') {                 
                    if(LP.Kunde__r.Medifox_2__c) {
                        medifox54 = true;
                    }
                    else nonmedifox54 = true;
                }
                else {
                    if(LP.Kunde__r.Medifox_2__c) {
                        medifox51 = true;
                    }
                    else nonmedifox51 = true;                   
                }
                if(LP.Kunde__r.Beihilfeberechtigt__c) hasBeihilfe = true;

                if((LP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c == 'privat') 
                    && (LP.Kunde__r.Abrechnung_direkt_mit_PPK__c != true)) hasPrivat = true;
                
                if(!(LP.Kunde__r.Beihilfeberechtigt__c) 
                    && !((LP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c == 'privat') 
                    && (LP.Kunde__r.Abrechnung_direkt_mit_PPK__c != true))) hasNormal = true;
            }
            
            
            
            
            List<Anschrift__c> RaList = [SELECT Id, Kunde__c, komb_Adresse__c, Standardrechnungsanschrift__c,
                                                e_mail__c, Fax__c, Ort__c, PLZ__c, Stra_e__c, Telefon__c
                                                             FROM Anschrift__c 
                                                             WHERE Kunde__c IN: KdSet 
                                                             AND Art_der_Anschrift__c = 'Kundenadresse'
                                                             AND komb_Adresse__c != null];
                          
            if((RaList != null) && (RaList.size() > 0)) {
                for(Anschrift__c RA: RaList) {
                    raMap.put(RA.Kunde__c, RA);
                }                                                             
            }
            
            lbList = [SELECT id, an_asb_versendet__c, Lieferschein__c, Kunde__c, Kunde__r.Medifox_2__c, Lieferschein__r.Lieferschein_text__c, Rechnung__r.name 
                                FROM Lieferbest_tigung__c 
                                WHERE Lieferschein__c IN : LSset];
            
            for(Lieferbest_tigung__c LB : lbList) {
                lsrgMap.put(LB.Lieferschein__c, LB.Rechnung__r.name);
            }           
                                
            list<attachment> attlistAb = [SELECT    parentid, id
                                            FROM attachment 
                                            WHERE parentid in :LSset 
                                            AND name LIKE 'Ablieferbeleg_%'];
            if((attListAb != null) && (attListAb.size() >0)) {
                for(attachment at : attListAb) abbMap.put(at.parentid, at.id);
            }   
            
            list<attachment> attlistGn = [SELECT    parentid, id
                                            FROM attachment 
                                            WHERE parentid in :KdSet 
                                            AND name LIKE 'Genehmigung_%'];
            if((attListGn != null) && (attListGn.size() >0)) {
                for(attachment at : attListGn) genMap.put(at.parentid, at.id);
            } 
            // Normaleweise steht die Genehmigung in LS. Wenn aber eine Lieferung an Kandidat und dann müssen wir diese suchen
            if(!KdOhneGenSet.isEmpty()) {
                list<Genehmigung__c> gnList = [SELECT Genehmigungsnummer__c, genehmigt_ab__c, Kunde__c
                                            FROM Genehmigung__c 
                                            WHERE Kunde__c IN :KdOhneGenSet
                                            AND Status__c IN ('Bewilligung', 'Teilbewilligung')
                                            ORDER BY genehmigt_ab__c DESC];
                    if((gnList != null) && (gnList.size() > 0)) {
                        for(Genehmigung__c gn : gnList) {
                            if((!kdGenMap.containsKey(gn.Kunde__c)) && (gn.genehmigt_ab__c <= date.Today())) kdGenMap.put(gn.Kunde__c, gn);
                        }
                    }
            }
            
            list<Kunde__c> asbKd = [SELECT id
                   FROM Kunde__c
                   WHERE Name = :AB_KK__c.getInstance('AB_KK_Einstellungen').Abrechnungsfirma__c LIMIT 1];
            
            
            string maNummerMedifox = '2183';
            string maNummerWebcare = '2182';
            
            try {
                maNummerMedifox = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerMedifox__c;
                maNummerWebcare = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerWebcare__c;
            }
            catch (System.Exception e) {}
            
            if(medifox54 || medifox51) {
                maNummer = maNummerMedifox;
            }
            else {
                maNummer = maNummerWebcare;
            }           
            
            
            Savepoint sp = Database.setSavepoint();         
            AB_normale_genehmigung abng = new AB_normale_genehmigung('AB_KK');
            abng.raMap = raMap;
            abng.kdGenMap = kdGenMap;
            abng.lsrgMap = lsrgMap;
            abng.genMap = genMap;
            abng.abbMap = abbMap;
     
            List<attachment> attList = new List<attachment>(); 
            List<Messaging.Emailfileattachment> attmList = new List<Messaging.Emailfileattachment>(); 
            boolean err = false;
            
            system.debug('#########################alex34003 getHeapSize='  + Limits.getHeapSize());

                if(hasPrivat) {
                    if(!err) {
                    String rgnamenstr = '';
                    String attachmentName = '';
                    for(string s : tSet) rgnamenstr += '_' + s;   
                    Blob csvAttP51 = abng.csvCreate(3, '51', LPall);
                    system.debug('#########################alex202 csvError=' + csvError);
                    if(csvAttP51 != null) { 
                        if((medifox51) || (medifox54)) {                     
                            attachmentName = 'Abrechnung' + rgnamenstr + '_' + date.today().format() + '_M_Privat.csv';
                        }
                        else {
                            attachmentName = 'Abrechnung' + rgnamenstr + '_' + date.today().format() + '_W_Privat.csv';                  
                        }                        
                        if(perEmail) {
                            subject += ' ' + rgnamenstr;
                            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                            csvAttc.setFileName(attachmentName);
                            csvAttc.setBody(csvAttP51);
                            attmList.add(csvAttc);
                        }
                        else {
                            Attachment attachP = new Attachment();
                            attachP.Body = csvAttP51;
                            attachP.Name = attachmentName;
                            attachP.IsPrivate = false;
                            attachP.ParentId = asbKd[0].id;
                            attList.add(attachP);
                        }
                    }
                    else {
                        err = abng.csvError;
                        if(err) attList.clear();
                        system.debug('#########################alex1402 err=' + err + ' errorMsg=' + errorMsg);
                        system.debug('#########################alex422a csvError=' + abng.csvError);
                        errorMsg = abng.errorMsg;
                    }
                    }
                    
                    if(!err) {
              
                    }
                }

            
            system.debug('#########################alex1443 attList.isEmpty()=' + attList.isEmpty());
            if(!err) {
                if(perEmail) {
                    Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                    String[] toAddress =  toAddr.split(',');                   
                    if(toCC != null) {                  
                        String[] toCcAddress =  toCC.split(',');  
                        mail.setCcAddresses(toCcAddress);
                    }
                    mail.setToAddresses(toAddress);
                    mail.setSubject(subject);
                    
                    mail.setFileAttachments(attmList);
                    mail.setPlainTextBody(PlainTextBody);
                    if(!attmList.isEmpty()) {
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
                    }
                }
                else {
                    if((!attList.isEmpty() && !err)) {
                        system.debug('#########################alex1444 insert');
                        try {
                            insert attList;
                        }
                        catch (System.Exception e) {
                            system.debug('#########################alex444 insert csvError=' + e);
                        }               
                    } 
                }
            }
            else {
                errorMsg = abng.errorMsg;
                Database.rollback(sp);  
            }
            
            
        }
}

@future(callout=true)
public static void createNormal(string rechnungen, boolean perEmail) {
        system.debug('#########################alex34001 getHeapSize='  + Limits.getHeapSize());
        asMail__c asMail = asMail__c.getValues('asb');
        String subject, toAddr, toCC, PlainTextBody;
        try {
            subject = asMail.subject__c;
            toAddr = asMail.toAddr__c;
            toCC = asMail.toCC__c;
            PlainTextBody = asMail.body__c;
        }
        catch (System.Exception e) {
            subject = 'Abrechnung';
            toAddr = 'kontakt@klosesrockepartner.de';
            toCC = null;
            PlainTextBody =  ' ';
        }
        set<id> LsSet = new set<id>();
        set<id> KdSet = new set<id>();
        set<id> KdOhneGenSet = new set<id>();
        set<id> genIdSet = new set<id>();
        boolean medifox54 = false;
        boolean nonmedifox54 = false;
        boolean medifox51 = false;
        boolean nonmedifox51 = false;
        string[] rgNamen = new list<string>();
        set<string> tSet = new set<string>();
        
        list<Lieferbest_tigung__c> lbList = new list<Lieferbest_tigung__c>();
        boolean hasNormal = false;
        boolean hasBeihilfe = false;
        boolean hasPrivat = false;      
        map<id, id> abbMap = new map<id, id>();
        map<id, id> genMap = new map<id, id>();
        map<id, Genehmigung__c> kdGenMap = new map<id, Genehmigung__c>();
        map<string, Rechnung__c> rgMap = new map<string, Rechnung__c>();
        map<id, Anschrift__c> raMap = new map<id, Anschrift__c>();    
        map<id, string> lsrgMap = new map<id, string>();    
        string errorMsg = null;     
        boolean csvError = false;   
        string maNummer = '1618';       
        
        system.debug('#########################alex401 rechnungen='  + rechnungen);
            if(rechnungen.contains(',')) {
                rgNamen = rechnungen.split(',');
            }
            else rgNamen.add(rechnungen);    
                for(string kk : rgNamen) {
                    system.debug('#########################alex407 kk='  + kk);
                    tSet.add(kk.trim());
                }
            
        List<Lieferscheinposition__c> LPall = [
                    SELECT Name,
                          Lieferschein__c,
                          Lieferschein__r.Name,
                          Lieferschein__r.Lieferadresse__c,
                          Lieferschein__r.Genehmigung__c,
                          Lieferschein__r.Genehmigung__r.Genehmigungsnummer__c,
                          Lieferschein__r.Genehmigung__r.genehmigt_ab__c,
                          Lieferschein__r.Kunde_Zuzahlung_befreit__c,
                          Kunde__c,
                          Kunde__r.Name,
                          Kunde__r.Versichertennummer__c,
                          Kunde__r.Name__c,
                          Kunde__r.Vorname__c,
                          Kunde__r.Anrede__c,
                          Kunde__r.Geburtsdatum_text__c,
                          Kunde__r.Beihilfeberechtigt__c,
                          Kunde__r.Abrechnung_direkt_mit_PPK__c,
                          Kunde__r.Medifox_2__c,
                          Kunde__r.Kundennummer_abena__c,
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
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.TK__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.AC__c,
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.PG51_Abrechnungs_Methode__c,      
                          Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c,                   
                          Artikel__c,
                          Artikel__r.Name,
                          Artikel__r.a_pac_apo_Mwst__c,
                          Artikel__r.Artikelgruppe__c,
                          Artikel__r.Anlage_4_Preis__c,
                          Artikel__r.Pflege_Hilfsmittelnr__c,
                          Artikel__r.v_pos_1_Name__c,
                          Menge__c,
                          AZ_von__c,
                          AZ_bis__c,
                          VZ_von__c,
                          VZ_bis__c,
                          Lieferdatum__c
                          
                     FROM Lieferscheinposition__c                                                           
                    WHERE Lieferschein__c IN (
                        SELECT Lieferschein__c FROM Lieferbest_tigung__c WHERE Rechnungsname__c IN :tSet) 
                        AND (
                            (Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c != 'privat') AND (Kunde__r.Abrechnung_direkt_mit_PPK__c != true)
                            )

                            AND Abrechnungsstatus_Krankenkasse__c IN ('abgerechnet', 'Abgerechnet über AS-B')
                        ORDER BY Lieferschein__r.Name];  
            
        if((LPall != null) && (LPall.size() >0)) {
            system.debug('#########################alex34002 getHeapSize='  + Limits.getHeapSize());
            for(Lieferscheinposition__c LP : LPall) {
                LsSet.add(LP.Lieferschein__c);
                KdSet.add(LP.Kunde__c);
                if(LP.Lieferschein__r.Genehmigung__c == null) KdOhneGenSet.add(LP.Kunde__c);
                if(LP.Artikel__r.v_pos_1_Name__c != '51') {                 
                    if(LP.Kunde__r.Medifox_2__c) {
                        medifox54 = true;
                    }
                    else nonmedifox54 = true;
                }
                else {
                    if(LP.Kunde__r.Medifox_2__c) {
                        medifox51 = true;
                    }
                    else nonmedifox51 = true;                   
                }
                if(LP.Kunde__r.Beihilfeberechtigt__c) hasBeihilfe = true;
                if((LP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c == 'privat') 
                    && (LP.Kunde__r.Abrechnung_direkt_mit_PPK__c != true)) hasPrivat = true;
                
                if(!(LP.Kunde__r.Beihilfeberechtigt__c) 
                    && !((LP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c == 'privat') 
                    && (LP.Kunde__r.Abrechnung_direkt_mit_PPK__c != true))) hasNormal = true;
            }
            
            
            
            
            List<Anschrift__c> RaList = [SELECT Id, Kunde__c, komb_Adresse__c, Standardrechnungsanschrift__c,
                                                e_mail__c, Fax__c, Ort__c, PLZ__c, Stra_e__c, Telefon__c
                                                             FROM Anschrift__c 
                                                             WHERE Kunde__c IN: KdSet 
                                                             AND Art_der_Anschrift__c = 'Kundenadresse'
                                                             AND komb_Adresse__c != null];
                          
            if((RaList != null) && (RaList.size() > 0)) {
                for(Anschrift__c RA: RaList) {
                    raMap.put(RA.Kunde__c, RA);
                }                                                             
            }
            
            lbList = [SELECT id, an_asb_versendet__c, Lieferschein__c, Kunde__c, Kunde__r.Medifox_2__c, Lieferschein__r.Lieferschein_text__c, Rechnung__r.name 
                                FROM Lieferbest_tigung__c 
                                WHERE Lieferschein__c IN : LSset];
            
            for(Lieferbest_tigung__c LB : lbList) {
                lsrgMap.put(LB.Lieferschein__c, LB.Rechnung__r.name);
            }           
                                
            list<attachment> attlistAb = [SELECT    parentid, id
                                            FROM attachment 
                                            WHERE parentid in :LSset 
                                            AND name LIKE 'Ablieferbeleg_%'];
            if((attListAb != null) && (attListAb.size() >0)) {
                for(attachment at : attListAb) abbMap.put(at.parentid, at.id);
            }   
            
            list<attachment> attlistGn = [SELECT    parentid, id
                                            FROM attachment 
                                            WHERE parentid in :KdSet 
                                            AND name LIKE 'Genehmigung_%'];
            if((attListGn != null) && (attListGn.size() >0)) {
                for(attachment at : attListGn) genMap.put(at.parentid, at.id);
            } 
            // Normaleweise steht die Genehmigung in LS. Wenn aber eine Lieferung an Kandidat und dann müssen wir diese suchen
            if(!KdOhneGenSet.isEmpty()) {
                list<Genehmigung__c> gnList = [SELECT Genehmigungsnummer__c, genehmigt_ab__c, Kunde__c
                                            FROM Genehmigung__c 
                                            WHERE Kunde__c IN :KdOhneGenSet
                                            AND Status__c IN ('Bewilligung', 'Teilbewilligung')
                                            ORDER BY genehmigt_ab__c DESC];
                    if((gnList != null) && (gnList.size() > 0)) {
                        for(Genehmigung__c gn : gnList) {
                            if((!kdGenMap.containsKey(gn.Kunde__c)) && (gn.genehmigt_ab__c <= date.Today())) kdGenMap.put(gn.Kunde__c, gn);
                        }
                    }
            }
            system.debug('########alex26000 Abrechnungsfirma__c=' + AB_KK__c.getInstance('AB_KK_Einstellungen').Abrechnungsfirma__c);
            list<Kunde__c> asbKd = [SELECT id
                   FROM Kunde__c
                   WHERE Name = :AB_KK__c.getInstance('AB_KK_Einstellungen').Abrechnungsfirma__c LIMIT 1];
            system.debug('########alex26001 AbrechnungsfirmaID=' + asbKd.size());
            
            string maNummerMedifox = '2183';
            string maNummerWebcare = '2182';
            
            try {
                maNummerMedifox = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerMedifox__c;
                maNummerWebcare = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerWebcare__c;
            }
            catch (System.Exception e) {}
            
            if(medifox54 || medifox51) {
                maNummer = maNummerMedifox;
            }
            else {
                maNummer = maNummerWebcare;
            }           
            
            
            Savepoint sp = Database.setSavepoint();         
            AB_normale_genehmigung abng = new AB_normale_genehmigung('AB_KK');
            abng.raMap = raMap;
            abng.kdGenMap = kdGenMap;
            abng.lsrgMap = lsrgMap;
            abng.genMap = genMap;
            abng.abbMap = abbMap;
     
            List<attachment> attList = new List<attachment>(); 
            List<Messaging.Emailfileattachment> attmList = new List<Messaging.Emailfileattachment>(); 
            boolean err = false;
            
            system.debug('#########################alex34003 getHeapSize='  + Limits.getHeapSize());
            if(hasNormal) {
                String rgnamenstr = '';
                String attachmentName = '';
                for(string s : tSet) rgnamenstr += '_' + s;   
                Blob csvAtt51 = abng.csvCreate(1, '51', LPall);
                system.debug('#########################alex201 csvError=' + abng.csvError);
                if(csvAtt51 != null) { 
                    if((medifox51) || (medifox54)) {                     
                        attachmentName = 'Abrechnung' + rgnamenstr + '_' + date.today().format() + '_M_Gesetzlich.csv';
                    }
                    else {
                        attachmentName = 'Abrechnung' + rgnamenstr + '_' + date.today().format() + '_W_Gesetzlich.csv';                  
                    }    

                    if(perEmail) {
                        subject += ' ' + rgnamenstr;
                        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                        csvAttc.setFileName(attachmentName);
                        csvAttc.setBody(csvAtt51);
                        attmList.add(csvAttc);
                    }
                    else {
                        Attachment attachP = new Attachment();
                        attachP.Body = csvAtt51;
                        attachP.Name = attachmentName;
                        attachP.IsPrivate = false;
                        attachP.ParentId = asbKd[0].id;
                        attList.add(attachP);
                    }  
                    
                }
                else {
                    err = abng.csvError;  
                    if(err) attList.clear();
                    errorMsg = abng.errorMsg;
                    system.debug('#########################alex421a errorMsg=' + errorMsg);
                    system.debug('#########################alex421b csvError=' + abng.csvError);

                }               
            }
            
            if(!err) {
                if(perEmail) {
                    Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                    String[] toAddress =  toAddr.split(','); 
                    if(toCC != null) {                  
                        String[] toCcAddress =  toCC.split(',');  
                        mail.setCcAddresses(toCcAddress);
                    }
                    mail.setToAddresses(toAddress);
                    mail.setSubject(subject);
                    
                    mail.setFileAttachments(attmList);
                    mail.setPlainTextBody(PlainTextBody);
                    if(!attmList.isEmpty()) {
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
                    }
                }
                else {
                    if((!attList.isEmpty() && !err)) {
                        system.debug('#########################alex1444 insert');
                        try {
                            insert attList;
                        }
                        catch (System.Exception e) {
                            system.debug('#########################alex444 insert csvError=' + e);
                        }               
                    } 
                }
            }
            else {
                errorMsg = abng.errorMsg;
                Database.rollback(sp);  
            }
            
            
        }
}
   
    public PageReference goBack(){
        Aufruf = true;
        kkstr = '';
        kkName = null;
       return null;  
    }
   
    public PageReference startBatch(){
        Aufruf = false;
        PageReference curPage = ApexPages.currentPage();
        curPage.getParameters().put('call','los');
        curPage.getParameters().put('kk', kkName);
        curPage.setRedirect(true);
        return curPage;  
    }


    public PageReference goSend() {
        if((kkName != null) && (!String.isBlank(kkName))) {
            callASB_CSV(kkName);
            Aufruf = true;
            kkstr = '';
            kkName = null;
        }
        return null;  
    }

    @future(callout=true)
    public static void callASB_CSV(String rgnamen) {
        ASB_CSV.createAndSendBoth(rgnamen);
    }
   
 }