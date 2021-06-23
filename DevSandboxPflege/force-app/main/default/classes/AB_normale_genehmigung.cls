/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//      Abrechnung normaler genehmigungen
//                            
//      geändert am 25.07.2014 durch WDS    ACR 261: private Verkäufe ausgegrenzt durch zusätzliche Abfrage auf Positionsart <> privat
//      geändert am 31.07.2014 durch WDS    ACR 264: Unterschrift muss bei der Auswahl berücksichtigt werden!
//      geändert am 19.08.2014 durch AM     ACR 265: Preislisteneitrag__r.abrechenbar__c == "nach Abrechnungszeitraum" muss berücksichtigt werden!
//      geändert am 19.08.2014 durch WDS    ACR 266: Preis für Anlage 4 Artikel aus Artikelstamm holen!
//      geändert am 24.05.2015 durch WDS             Einzelpreis des Artikels soll in "PO" Zeile ausgegeben werden!!
//      geändert am 08.06.2015 durch AM              Ablieferbele und Genehmigung attachments werden in Lieferbestätigung geschrieben.
//                                                   Ohne BEIDE Felder wird keine Abrechnung für LS durchgeführt.
//      geändert am 09.06.2015 durch WDS             nochmals Summe korrigiert, die jetzt nur noch die einzelpreise aufsummiert
//      geändert am 10.06.2015 durch AM             Sortierung nach LS-Name in csv, Erstellene Rechnungskopf, Genehmigung in Zeile VO
//                                                  Rechnungsnummer in Zeile D BA
//      geändert am 16.06.2015 durch AM             Prüfen auf gn und AB attachment bevor update LB
//      geändert am 24.06.2015 durch AM             zu viele Tabs in VO. Geb. Datum wird 01.01.2000 wenn nicht gefüllt
//      geändert am 16.07.2015  durch AM        anpassung an 51
//      geändert am 27.08.2015 durch BT         Anpassung toCC, toAddr
//      geändert am 20.10.2015  durch AM        PLZ immer 5-Stellig
//      geändert am 23.11.2015  durch BT        Die Standardrechnungsanschrift wird bei der CSV Erstellung eingesetzt. Liegt keine
//                                              Standardrechnungsanschrift vor, wird die Standardlieferanschrift eingesetzt.
//      geändert am 15.12.2015  durch AM        #109711442 Es wird immer Kundenadresse an ASB versendet.
//      geändert am 29.01.2016  durch BT        Das Feld 'Geburtsdatum__c' wird durch das Feld 'Geburtsdatum_text__c' erstetzt
//      geändert am 15.12.2015  durch AM        case 00001039. Ges. Zuzahlung war falsch errechnet.
//      geändert am 27.06.2016  durch AM        CURABOX - Aufteilung des Abrechnungsprozess in „Standard“ und „Medifox"
//      geändert am 05.10.2016  durch BT        Bei Zuzahlung wird der Privatanteil herausgenommen. Der Kostenanteil PK entspricht der Gesamtsumme.
//      geändert am 21.12.2016  durch BT        #128395565 Umsortierung und Umbenennung von CSV-Dateien
//      geändert am 22.05.2017  durch AM        SELECT attachment für Genehmigung mit ORDER BY
//      geändert am 22.05.2017  durch AM        Genehmigung und attID steht immer in LS.
//      geändert am 09.06.2017  durch AM        Genehmigung_tt_id in LB wird nicht mehr geändert.
//      geändert am 23.06.2017  durch AM        Apex heap size too large - es wird der Satz aus der LPall-List nach der Bearbeitung removed.
//      geändert am 15.08.2017  durch AM        Die SU-Zeile wird wie folgt aufgebaut: Summe    Zuzahlung   Summe-Zuzahlung
//      geändert am 17.11.2017  durch AM        Pivotal Tracker:   #152753550
//      geändert am 03.01.2018  durch AM        Pivotal Tracker:   #153991510 - Die Summe für 51 wurde falsch errechnet (für 51 ist immer nur 1 Lpos)
//      geändert am 10.12.2018  durch AM        Pivotal Tracker:   #162344051 - Es werden nich alle Felder bei PG51 angedruckt (analog zu PG54)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global with sharing class AB_normale_genehmigung {
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

public boolean csvError = false;

public string mfKunden = '';
public string mfKundenTitel {get; set;}
public string maNummer = '1618';

public boolean lpclearen = false;

public AB_normale_genehmigung() {
    kkName = ApexPages.CurrentPage().getParameters().get('kk');
    String los = ApexPages.CurrentPage().getParameters().get('call');
    mfKunden = ApexPages.CurrentPage().getParameters().get('mf');
    if(mfKunden != null) {
        mfKundenTitel = ' - ' + mfKunden;
    }
    else {
        mfKundenTitel = '';
    }
    if (los == 'los') {
        Aufruf = false;
        kkstr = ApexPages.CurrentPage().getParameters().get('kk').trim();
    }
    else {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Geben Sie einen Namen oder ein Teil des Namens ein.<br>So z.B. \"AOK\" werden alle AOKs abgerechnet.<br>Beim Eingabe \"AOK HESSEN\" wird nur eine bestimmte Kasse abgerechnet.  '));    
    }       
}

public AB_normale_genehmigung(string nachtrag) {}

public ApexPages.StandardSetController setCon {
get{
if(setCon == null){
    size = list_size;
    setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
        [
        SELECT Name,
              Lieferschein__c,
              Lieferschein__r.Name,
              Lieferschein__r.Lieferadresse__c,
              Lieferschein__r.Genehmigung__c,
              Lieferschein__r.Genehmigung__r.Genehmigungsnummer__c,
              Lieferschein__r.Genehmigung__r.genehmigt_ab__c,
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
              Lieferschein__r.Kunde_Zuzahlung_befreit__c,
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
        WHERE Abrechnungsstatus_Krankenkasse__c = 'abrechenbar'  
          AND Status__c != 'storniert' 
          AND Unterschrift__c != false                                                            
          AND Lieferschein__c != null
          AND Auftragsposition__r.Auftrag__r.Fallpauschale__c = null
          
          AND Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.type != 'Sonstige'
          AND Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Name LIKE: '%' + kkstr + '%'
          AND Lieferschein__c IN (SELECT Lieferschein__c FROM Lieferbest_tigung__c WHERE an_abena_versendet__c = true AND Rechnung__c = null) 
          AND Kunde__r.Medifox_2__c = :medifox 
            ORDER BY Lieferschein__r.Name]));
    setCon.setPageSize(size);
    noOfRecords = setCon.getResultSize();
}
return setCon;
}set;
}

public boolean medifox {
    set;
    get {
        if(mfKunden == 'Medifox') {
            return true;
        } else return false;
    }
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

public PageReference createAndSend(){  
    set<id> LsSet = new set<id>();
    set<id> KdSet = new set<id>();
    set<id> KdOhneGenSet = new set<id>();
    set<id> genIdSet = new set<id>();
    boolean medifox54 = false;
    boolean nonmedifox54 = false;
    boolean medifox51 = false;
    boolean nonmedifox51 = false;
    
    string maNummerMedifox = '2183';
    string maNummerWebcare = '2182';
    
    try {
        maNummerMedifox = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerMedifox__c;
        maNummerWebcare = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerWebcare__c;
    }
    catch (System.Exception e) {}
    
    if(medifox) {
        maNummer = maNummerMedifox;
    }
    else {
        maNummer = maNummerWebcare;
    }
    
    LPall = [
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
            WHERE Abrechnungsstatus_Krankenkasse__c = 'abrechenbar'  
              AND Status__c != 'storniert' 
              AND Unterschrift__c != false                                                            
              AND Lieferschein__c != null
              AND Auftragsposition__r.Auftrag__r.Fallpauschale__c = null
              
              AND Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.type != 'Sonstige'
              AND Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Name LIKE: '%' + kkstr + '%'
              AND Lieferschein__c IN (SELECT Lieferschein__c FROM Lieferbest_tigung__c WHERE an_abena_versendet__c = true AND Rechnung__c = null) 
              AND Kunde__r.Medifox_2__c = :medifox 
                ORDER BY Lieferschein__r.Name];  

if((LPall != null) && (LPall.size() >0)) {

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

    lbList = [SELECT id, an_asb_versendet__c, Lieferschein__c, Kunde__c, Kunde__r.Medifox_2__c, Lieferschein__r.Lieferschein_text__c 
                        FROM Lieferbest_tigung__c 
                        WHERE Lieferschein__c IN : LSset];

                        
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
// AM 26.05.2017 deprecated - steht immer da über trigger gefüllt
    if(!KdOhneGenSet.isEmpty()) {
        list<Genehmigung__c> gnList = [SELECT Genehmigungsnummer__c, genehmigt_ab__c, Kunde__c, Name__c
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

    Savepoint sp = Database.setSavepoint();

    Rechnung__c mf54 = new Rechnung__c(Kunde__c = asbKd[0].id, BUCHUNGSTEXT__C = 'KK-Abrechnungsbeleg');
    Rechnung__c nmf54 = new Rechnung__c(Kunde__c = asbKd[0].id, BUCHUNGSTEXT__C = 'KK-Abrechnungsbeleg');
    Rechnung__c mf51 = new Rechnung__c(Kunde__c = asbKd[0].id, BUCHUNGSTEXT__C = 'KK-Abrechnungsbeleg', Rechnung_text__c='KUWV');
    Rechnung__c nmf51 = new Rechnung__c(Kunde__c = asbKd[0].id, BUCHUNGSTEXT__C = 'KK-Abrechnungsbeleg', Rechnung_text__c='KUWV');   

    if(medifox54) { 
        try {
            insert mf54;
            Rechnung__c rgm54 = [SELECT id, Name FROM Rechnung__c WHERE id = :mf54.id LIMIT 1];
            rgMap.put('medifox54', rgm54);
        }
        catch(System.Exception e) {
            
        }
    }
    if(nonmedifox54) {
        try {
            insert nmf54;
            Rechnung__c rgnm54 = [SELECT id, Name FROM Rechnung__c WHERE id = :nmf54.id LIMIT 1];
            rgMap.put('nonmedifox54', rgnm54);
        }
        catch(System.Exception e) {
            
        }               
    }
    if(medifox51) { 
        try {
            insert mf51;
            Rechnung__c rgm51 = [SELECT id, Name FROM Rechnung__c WHERE id = :mf51.id LIMIT 1];
            rgMap.put('medifox51', rgm51);
        }
        catch(System.Exception e) {
            
        }
    }
    if(nonmedifox51) {
        try {
            insert nmf51;
            Rechnung__c rgnm51 = [SELECT id, Name FROM Rechnung__c WHERE id = :nmf51.id LIMIT 1];
            rgMap.put('nonmedifox51', rgnm51);
        }
        catch(System.Exception e) {
            
        }               
    }            

    String Addr = '';                    
    asMail = asMail__c.getValues('asb');
    String subject = asMail.subject__c;
    //toAddrCSV = asMail.toAddr__c;
    //toCCCSV = asMail.toCC__c;
    string PlainTextBody = asMail.body__c;

    List<Messaging.Emailfileattachment> attList = new List<Messaging.Emailfileattachment>(); 
    boolean err = false;
    if(hasNormal) {
        Blob csvAtt51 = csvCreate(1, '51');
        system.debug('#########################alex201 csvError=' + csvError);
        if(csvAtt51 != null) { 
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            //string csvname= asMail.fileName__c + '_Standard.csv';
            if(medifox) {
                string csvname = 'Abrechnung_' + rgmap.get('medifox51').Name + '_' + date.today().format() + '_M_Gesetzlich.csv';
                csvAttc.setFileName(csvname);
            }
            else {
                string csvname = 'Abrechnung_' + rgmap.get('nonmedifox51').Name + '_' + date.today().format() + '_W_Gesetzlich.csv';
                csvAttc.setFileName(csvname);
            }            
            csvAttc.setBody(csvAtt51);
            attList.add(csvAttc);
        }
        else {
            err = true;
            system.debug('#########################alex401 err=' + err + ' errorMsg=' + errorMsg);
            system.debug('#########################alex421 csvError=' + csvError);
        }
        
      if(!csvError){
        Blob csvAtt54 = csvCreate(1, '54');
        system.debug('#########################alex201 pName=' + '54');
        system.debug('#########################alex201 csvError=' + csvError);
        if(csvAtt54 != null) { 
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            if(medifox) {
                string csvname = 'Abrechnung_' + rgmap.get('medifox54').Name + '_' + date.today().format() + '_M_Gesetzlich.csv'; 
                csvAttc.setFileName(csvname);              
            }
            else{ 
                string csvname = 'Abrechnung_' + rgmap.get('nonmedifox54').Name + '_' + date.today().format() + '_W_Gesetzlich.csv';
                csvAttc.setFileName(csvname);
            }
            csvAttc.setBody(csvAtt54);
            attList.add(csvAttc);
            err = false;
        }
        else {
            err = true;
            system.debug('#########################alex401 err=' + err + ' errorMsg=' + errorMsg);
            system.debug('#########################alex421 csvError=' + csvError);
        }
      }
    }
if(!csvError) {
    if(hasPrivat) {
        Blob csvAttP51 = csvCreate(3, '51');
        system.debug('#########################alex202 csvError=' + csvError);
        if(csvAttP51 != null) { 
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            if(medifox) {
                string csvname = 'Abrechnung_' + rgmap.get('medifox51').Name + '_' + date.today().format() + '_M_Privat.csv';
                csvAttc.setFileName(csvname);
            }
            else { 
                string csvname = 'Abrechnung_' + rgmap.get('nonmedifox51').Name + '_' + date.today().format() + '_W_Privat.csv';
                csvAttc.setFileName(csvname);
            }
            csvAttc.setBody(csvAttP51);
            attList.add(csvAttc);
            err = false;
        }
        else {
            err = true;
            system.debug('#########################alex402 err=' + err + ' errorMsg=' + errorMsg);
            system.debug('#########################alex422 csvError=' + csvError);
        }
       
      if(!csvError){ 
        Blob csvAttP54 = csvCreate(3, '54');
        system.debug('#########################alex202 csvError=' + csvError);
        if(csvAttP54 != null) { 
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            if(medifox) {
                string csvname = 'Abrechnung_' + rgmap.get('medifox54').Name + '_' + date.today().format() + '_M_Privat.csv';
                csvAttc.setFileName(csvname);
            }
            else {
                string csvname = 'Abrechnung_' + rgmap.get('nonmedifox54').Name + '_' + date.today().format() + '_W_Privat.csv';
                csvAttc.setFileName(csvname);
            }
            csvAttc.setBody(csvAttP54);
            attList.add(csvAttc);
            err = false;
        }
        else {
            err = true;
            system.debug('#########################alex402 err=' + err + ' errorMsg=' + errorMsg);
            system.debug('#########################alex422 csvError=' + csvError);
        } 
      }       
    }
}
if(!err) {
    Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
    String[] toAddress =  asMail.toAddr__c.split(',');                   
    String[] toCcAddress =  asMail.toCC__c.split(',');   
    //String[] toAddress = new String[] {toAddrCSV};
    //String[] toCcAddress = new String[] {toCCCSV};
    mail.setCcAddresses(toCcAddress);
    mail.setToAddresses(toAddress);
    mail.setSubject(subject);
    
    mail.setFileAttachments(attList);
    mail.setPlainTextBody('Abrechnung AS.');
    try {
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        for(String str: toAddress)
        {
             str = str + ' ';
             Addr = Addr + str;
        }
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Mail gesendet an ' + Addr + ' LB :' + lbList.size()));  
        //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Mail gesendet an ' + toAddrCSV + ' LB :' + lbList.size()));  
        
        if((lbList != null) && (lbList.size() > 0)) {
            
            
            system.debug('#########################alex101 '  + lbList.size());
            for(Lieferbest_tigung__c lb : lbList) {
                if((abbMap.containsKey(lb.Lieferschein__c)) ) {
                    if(abbMap.containsKey(lb.Lieferschein__c)) lb.ablieferbeleg_att_ID__c = string.valueOf(abbMap.get(lb.Lieferschein__c));
                    // AM 22.05.2017 if(genMap.containsKey(lb.Kunde__c)) lb.genehmigung_att_id__c = string.valueOf(genMap.get(lb.Kunde__c)); 
                    // AM 09.06.2017
                    // if(genMap.containsKey(lb.Kunde__c)) {
                        // if(lb.genehmigung_att_id__c == null) lb.genehmigung_att_id__c = string.valueOf(genMap.get(lb.Kunde__c)); 
                    // }
                    
                    lb.an_asb_versendet__c = true;
                    if(lb.Lieferschein__r.Lieferschein_text__c != '51') {
                        if(lb.Kunde__r.Medifox_2__c) {
                            if(rgMap.containsKey('medifox54')) { 
                                lb.Rechnung__c = rgMap.get('medifox54').id;
                                lb.Rechnungsname__c = rgMap.get('medifox54').Name;
                            }
                        }
                        else { 
                        system.debug('#########################alex102 '  + lbList.size());
                            if(rgMap.containsKey('nonmedifox54')) { 
                            system.debug('#########################alex103 '  + lbList.size());
                                lb.Rechnung__c = rgMap.get('nonmedifox54').id;
                                lb.Rechnungsname__c = rgMap.get('nonmedifox54').Name;
                            }
                            system.debug('#########################alex104 '  + lb);
                        }
                    }
                    else {
                        if(lb.Kunde__r.Medifox_2__c) {
                            if(rgMap.containsKey('medifox51')) { 
                                lb.Rechnung__c = rgMap.get('medifox51').id;
                                lb.Rechnungsname__c = rgMap.get('medifox51').Name;
                            }
                        }
                        else { 
                        system.debug('#########################alex102a '  + lbList.size());
                            if(rgMap.containsKey('nonmedifox51')) { 
                            system.debug('#########################alex103a '  + lbList.size());
                                lb.Rechnung__c = rgMap.get('nonmedifox51').id;
                                lb.Rechnungsname__c = rgMap.get('nonmedifox51').Name;
                            }
                            system.debug('#########################alex104 '  + lb);
                        }                               
                    }
                }
            }
            try {
                update lbList;
                system.debug('#########################alex105 update OK');
            }
            catch(System.Exception e) {
                system.debug('#########################alex105 update lbList Error' + e);
            }
        }
    }
    catch (System.Exception e)
    {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Fehler beim Senden Mail'));    
        system.debug('#########################email####### error '  + e);
    }
    }
    else {
      if(csvError) {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Fehler bei dem Kunde ' + errorMsg));  
        Database.rollback(sp);  
        return null;
      }
    }


}
    // return null;
    PageReference pr = new PageReference('/apex/AB_normale_genehmigung');
    pr.setRedirect(true);
    return pr;
}

public PageReference goBack(){
    Aufruf = true;
    kkstr = '';
    kkName = null;
    return null;  
}

public PageReference startBatch() {
    Aufruf = false;
    PageReference curPage = ApexPages.currentPage();
    curPage.getParameters().put('call','los');
    curPage.getParameters().put('kk', kkName);
    curPage.getParameters().put('mf', mfKunden);
    curPage.setRedirect(true);
    return curPage;  
}

public blob csvCreate(integer art, string pName, List<Lieferscheinposition__c > lpl) {
    this.LPall = lpl;
    this.lpclearen = true;
    return csvCreate(art, pName);
}

public blob csvCreate(integer art, string pName) {
    // 1 = normale
    // 2 = Beihilfe
    // 3 = privat
    csvError = false;
    blob csvBlob = null;
    integer lfnr = 0;
    integer cnt = 0;
    integer count = 0;
    string csvString = 'VERSION\t1.2\r\nMA' + '\t' + maNummer + '\r\n';
    string tLS = '';
    Lieferscheinposition__c tLP;
    decimal posSumme = 0.00;
    //errorMsg = 'Anfang ';
    decimal zzMenge = 0.00;
    decimal zzMengeLast = 0.00;
    String zzMethod = null;
    String zzMethodTemp = null;
    String zzMethodLast = null;
    boolean zzberechnen = false;
    boolean zzberechnenLast = false;
    List<Lieferscheinposition__c> LPlist = new List<Lieferscheinposition__c >();
    integer cntlp = 0;
    set<integer> toRemoveSet = new set<integer>();
    
    for(Lieferscheinposition__c lps: LPall){
        if(pName == '51'){
            if(lps.Artikel__r.v_pos_1_Name__c == '51') {
                LPlist.add(lps);
                toRemoveSet.add(cntlp);
            }
        } 
        else {
            if(lps.Artikel__r.v_pos_1_Name__c != '51') {
                LPlist.add(lps);
                toRemoveSet.add(cntlp);
            }
        }
        cntlp++;
    }
    // AM 03.08.2017 
    map<id, string> sonderAbrechnungAcc54 = new map<id, string>(); 
    transient list<account> acList = [select id, name, Abrechnung_gen_daten_54__c 
                                        from account 
                                        where industry = 'Krankenkassen' 
                                        and Abrechnung_gen_daten_54__c != null];
    if((acList != null) && (acList.size() > 0)) {
        for(account AC: acList) {
            sonderAbrechnungAcc54.put(ac.id, ac.Abrechnung_gen_daten_54__c);
        }                                                             
    }   
    // AM 10.12.2018 
    map<id, string> sonderAbrechnungAcc51 = new map<id, string>(); 
    transient list<account> ac51List = [select id, name, Abrechnung_gen_daten_51__c 
                                        from account 
                                        where industry = 'Krankenkassen' 
                                        and Abrechnung_gen_daten_51__c != null];
    if((ac51List != null) && (ac51List.size() > 0)) {
        for(account AC: ac51List) {
            sonderAbrechnungAcc51.put(ac.id, ac.Abrechnung_gen_daten_51__c);
        }                                                             
    }   

    // AM 03.08.2017     
    system.debug('#########AM33001  LPall.size = ' + LPall.size());
    if(!toRemoveSet.isEmpty()) {
        for(integer ri : toRemoveSet) {
            try {
                if(lpclearen) LPall.remove(ri);
                system.debug('#########AM33002 ri=' + ri);
            }
            catch(System.Exception e) {
                system.debug('#########AM33003 ri=' + ri);
            }
        }
        cntlp = 0;
        toRemoveSet.Clear();
    }
    system.debug('#########AM33004  LPall.size = ' + LPall.size());
    
    // try {
        
        //errorMsg += ' kdGenMap.size()=' + string.valueOf(kdGenMap.size()) + ' raMap.size()=' + string.valueOf(raMap.size()) + ' lsrgMap.size()=' + string.valueOf(lsrgMap.size()); 
    // main-for
    for (lieferscheinposition__c LsP : LPlist) {
            
        // zzberechnen = false;
        zzberechnenLast = false;
        // system.debug('#########BT2017  liste.size = ' + LPlist.size());
        // Erste Prüfung - Abb und Gen
        //system.debug('#########################alex001 '  + LsP.Lieferschein__r.Name);
        if((abbMap.containsKey(LsP.Lieferschein__c)) ) {
            
            system.debug('#########################alex002 '  + LsP.Lieferschein__r.Name);
            if(((art == 1) 
                && ((lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c != 'privat')
                    || (lsp.Kunde__r.Abrechnung_direkt_mit_PPK__c == true))
            )

            || ((art == 3) 
                && ((lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c == 'privat')
                    && (lsp.Kunde__r.Abrechnung_direkt_mit_PPK__c != true))
            )
            ) 
            {         
                    system.debug('##############BT2017 tessssst !!!' + lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c); 
                    cnt++;
                    errorMsg = LsP.Kunde__r.Name__c + ' ' + LsP.Kunde__r.Vorname__c + ' Kdnr: ' + LsP.Kunde__r.Kundennummer_abena__c + ' Lieferschein ' + + LsP.Lieferschein__r.Name + ' art='+art + ' pName=' + pName;
                    system.debug('#########################alex003 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg);
                    if((lsp.Artikel__r.v_pos_1_Name__c == '51') && (!lsp.Lieferschein__r.Kunde_Zuzahlung_befreit__c)) {
                        zzberechnenLast = true;
                        zzMethodLast = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.PG51_Abrechnungs_Methode__c;
                        zzMengeLast = LsP.Menge__c;                         
                    }
                    
                    count++;
                    // Gruppenwechsel LS
                    if(tLS != LsP.Lieferschein__r.Name)  {
                        //system.debug('#########################alex003a LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg);
                        string strNum = '';
                        string plz = '';
                        string ort = '';
                        
                        if(raMap.containsKey(LsP.Kunde__c)) {
                            try {
                                    system.debug('#########################alex412 raMap.get(LsP.Kunde__c)=' + raMap.get(LsP.Kunde__c));
                                    plz = raMap.get(LsP.Kunde__c).PLZ__c;
                                    if(plz == null) {
                                        system.debug('#########################alex004a LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + 'PLZ = null');
                                        errorMsg = errorMsg + '. PLZ = null';
                                        csvError = true;
                                        return null;                                    
                                    }
                                plz = plz.trim();
                                if(plz != '') {
                                    if(plz.length() == 4) {
                                        plz = '0' + plz;
                                    }
                                    if(plz.length() == 3) {
                                        plz = '00' + plz;
                                    }
                                    if(plz.length() == 2) {
                                        plz = '000' + plz;
                                    }                               
                                }
                                ort = raMap.get(LsP.Kunde__c).Ort__c;
                                if(ort == null) {
                                    system.debug('#########################alex004a LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + 'Ort = null');
                                    errorMsg  = errorMsg + '. Ort = null';
                                    csvError = true;
                                    return null;                                    
                                }
                                strNum = raMap.get(LsP.Kunde__c).Stra_e__c;
                                if(strNum == null) {
                                    system.debug('#########################alex004a LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + 'strNum = null');
                                    errorMsg = errorMsg + ' Straße = null';
                                    csvError = true;
                                    return null;                                    
                                }
                            }
                            catch(System.Exception e) {
                                errorMsg += ' Kundenadresse';
                                system.debug('#########################alex004 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + ' e=' + e);
                                csvError = true;
                                return null;
                            }
                        }                        
                        else {
                            system.debug('#########################alex005 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg);
                            errorMsg = errorMsg + '. Keine Kundenadresse gefunden.';
                            csvError = true;
                            return null;
                        }
                        count++;
                        string gebDat = '01.01.2000';
                        try {
                                //                string gebDat = '01.01.0001';
                        
                            if(lsp.Kunde__r.Geburtsdatum_text__c != null) {
                                gebDat = lsp.Kunde__r.Geburtsdatum_text__c;
                            } 
                            
                            if(lfnr > 0) {
                                if(tLP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c != null) {
                                    if(pName != '51') {
                                        system.debug('#########################alex1400 pName=' + pName + ' lfnr=' + lfnr);
                                        csvString += sonderRegelnAbrechnungPO(posSumme, tLP);
                                    }
                                    else {
                                        system.debug('#########################alex1410 pName=' + pName + ' lfnr=' + lfnr);
                                        csvString += normaleAbrechnungPO(posSumme, tLP);
                                    }
                                }
                                if(zzberechnen) {
                                    
                                    system.debug('#########################alex1103 LsP.Kunde__r.Name__c='  + LsP.Kunde__r.Name__c + ' zzMenge=' + zzMenge + ' zzMethod=' + zzMethod);
                                    system.debug('#########################alex1103a LsP.Kunde__r.Name__c='  + LsP.Kunde__r.Name__c + ' zzMenge=' + zzMenge + ' zzMethod=' + zzMethod);
                                    system.debug('#########################alex1103b LsP.Kunde__r.Name__c='  + LsP.Kunde__r.Name__c + ' zzMenge=' + zzMenge + ' zzMethod=' + zzMethod + ' posSumme=' + posSumme);
                                    csvString += 'SU\t' + printZuzahlung(posSumme, zzMenge, zzMethod);
                                }
                                else {
                                    csvString += 'SU\t'  + ksgFunctions.formatCurrency(posSumme) + '\t0\t' + ksgFunctions.formatCurrency(posSumme) + '\r\n';                     
                                }
                                posSumme = 0.00;                    
                            }
                        }
                        catch (System.Exception e) {
                            errorMsg += ' Zuzahlung berechen';
                            system.debug('#########################alex006 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg);
                            csvError = true;
                            return null;
                        }
                        lfnr++;
                        posSumme = 0.00; 
                        count++;
                        string rgnr = '';   
                        // BA-record                    
                        try {
                            if(lsrgMap.isEmpty()) {
                            
                                if(LsP.Artikel__r.v_pos_1_Name__c != '51') {        
                                    if(LsP.Kunde__r.Medifox_2__c) {
                                        if(rgMap.containsKey('medifox54')) rgnr = rgMap.get('medifox54').Name;
                                    }
                                    else {
                                        if(rgMap.containsKey('nonmedifox54')) rgnr = rgMap.get('nonmedifox54').Name;
                                    }
                                }
                                else {
                                    if(LsP.Kunde__r.Medifox_2__c) {
                                        if(rgMap.containsKey('medifox51')) rgnr = rgMap.get('medifox51').Name;
                                    }
                                    else {
                                        if(rgMap.containsKey('nonmedifox51')) rgnr = rgMap.get('nonmedifox51').Name;
                                    }                           
                                }
                            }
                            else {
                                rgnr = lsrgMap.get(LsP.Lieferschein__c);
                            }
                            
                            csvString   += 'BA\t' + string.valueOf(lfnr) 
                                        + '\t' + 'HILFSMITTEL' 
                                        + '\t' + rgnr
                                        + '\t' 
                                        + '\t' 
                                        + '\t' 
                                        + '\t' 
                                        + '\r\n';
                        }
                        catch (System.Exception e) {
                            errorMsg += ' Rechnugsnummer';
                            system.debug('#########################alex007 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + ' e=' + e);
                            csvError = true;
                            return null;
                        }
                        
                        
                        string versNummer = '';
                        try {
                        
                            if(Lsp.Kunde__r.Versichertennummer__c != null) {
                                versNummer = Lsp.Kunde__r.Versichertennummer__c;
                            }               
                            else {
                                if(lsp.Kunde__r.Geburtsdatum_text__c != null) {
                                    versNummer = lsp.Kunde__r.Geburtsdatum_text__c.replace('.', '');
                                }
                                else {
                                    versNummer = Lsp.Kunde__r.Name__c;
                                }                   
                            }
                        }
                        catch (System.Exception e) {
                            errorMsg += ' Geburtsdatum_text';
                            system.debug('#########################alex008 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + ' e=' + e);
                            csvError = true;
                            return null;
                        }
                        string anrede = '';
                        try {
                        
                            if(LsP.Kunde__r.Anrede__c != null) {
                                if(LsP.Kunde__r.Anrede__c.contains('Herr')) {
                                    Anrede = 'h';
                                }
                                else {
                                    Anrede = 'f';
                                }
                            }
                            else {
                                Anrede = ' ';
                            }
                        
                        
                            csvString   += 'VS\t' + Lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.IK_Nummer__c  
                                        + '\t' + versNummer 
                                        + '\t' + '50001'                            
                                        + '\t' + lsp.Kunde__r.Name__c 
                                        + '\t' + lsp.Kunde__r.Vorname__c 
                                        + '\t' + strNum 
                                        + '\t'+ plz 
                                        + '\t'+ ort 
                                        + '\t'+ anrede 
                                        + '\t' + gebDat 
                                        + '\r\n';
                                    
                        }
                        catch (System.Exception e) {
                            errorMsg += ' Anrede';
                            system.debug('#########################alex009 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + ' e=' + e);
                            csvError = true;
                            return null;
                        }
                        string genName = '';
                        string genVon = ''; 
                        boolean keineGenName54 = false;
                        boolean keineGenVon54 = false;
                        // AM 10.12.1028
                        boolean keineGenName51 = false;
                        boolean keineGenVon51 = false;

                        // VO-record
                        try {
                            if(pName != '51') {
                                if(sonderAbrechnungAcc54.containsKey(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c) ) {
                                    if( sonderAbrechnungAcc54.get(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c).contains('Genehmigt ab')) keineGenVon54 = true;
                                    if( sonderAbrechnungAcc54.get(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c).contains('Genemigungsnummer')) keineGenName54 = true;
                                }
                            // } 
                                if(LsP.Lieferschein__r.Genehmigung__c != null) {
                                    if(LsP.Lieferschein__r.Genehmigung__r.Genehmigungsnummer__c != null) {
                                        if(!keineGenName54) genName = LsP.Lieferschein__r.Genehmigung__r.Genehmigungsnummer__c; 
                                    }
                                    system.debug('#########################alex415 lsp.Lieferschein__r.Genehmigung__r.genehmigt_ab__c=' + lsp.Lieferschein__r.Genehmigung__r.genehmigt_ab__c);
                                    if(!keineGenVon54) genVon = datetime.newInstance(lsp.Lieferschein__r.Genehmigung__r.genehmigt_ab__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                                }
                                else {
                                    if(kdGenMap.containsKey(LsP.Kunde__c)) {
                                        if(kdGenMap.get(LsP.Kunde__c).Genehmigungsnummer__c != null) {
                                            if(!keineGenName54) genName = kdGenMap.get(LsP.Kunde__c).Genehmigungsnummer__c;
                                        }
                                        system.debug('#########################alex416 kdGenMap.get(LsP.Kunde__c).genehmigt_ab__c=' + kdGenMap.get(LsP.Kunde__c).genehmigt_ab__c);
                                        if(!keineGenVon54) genVon = datetime.newInstance(kdGenMap.get(LsP.Kunde__c).genehmigt_ab__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                                    }                   
                                }
                            }
                            // AM 10.12.1028
                            if(pName == '51') {
                                if(sonderAbrechnungAcc51.containsKey(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c) ) {
                                    if( sonderAbrechnungAcc51.get(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c).contains('Genehmigt ab')) keineGenVon51 = true;
                                    if( sonderAbrechnungAcc51.get(LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__c).contains('Genemigungsnummer')) keineGenName51 = true;
                                }
                              
                                if(LsP.Lieferschein__r.Genehmigung__c != null) {
                                    if(LsP.Lieferschein__r.Genehmigung__r.Genehmigungsnummer__c != null) {
                                        if(!keineGenName51) genName = LsP.Lieferschein__r.Genehmigung__r.Genehmigungsnummer__c; 
                                    }
                                    system.debug('#########################alex415_51 lsp.Lieferschein__r.Genehmigung__r.genehmigt_ab__c=' + lsp.Lieferschein__r.Genehmigung__r.genehmigt_ab__c);
                                    if(!keineGenVon51) genVon = datetime.newInstance(lsp.Lieferschein__r.Genehmigung__r.genehmigt_ab__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                                }
                                else {
                                    if(kdGenMap.containsKey(LsP.Kunde__c)) {
                                        if(kdGenMap.get(LsP.Kunde__c).Genehmigungsnummer__c != null) {
                                            if(!keineGenName51) genName = kdGenMap.get(LsP.Kunde__c).Genehmigungsnummer__c;
                                        }
                                        system.debug('#########################alex416_51 kdGenMap.get(LsP.Kunde__c).genehmigt_ab__c=' + kdGenMap.get(LsP.Kunde__c).genehmigt_ab__c);
                                        if(!keineGenVon51) genVon = datetime.newInstance(kdGenMap.get(LsP.Kunde__c).genehmigt_ab__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                                    }                   
                                }
                            }
                            // csvString += 'VO\t' 
                                        // + '\t'   
                                        // + '\t'                
                                        // + '\t' + genVon
                                        // + '\t' + genName 
                                        // + '\r\n';
                            csvString += 'VO\t'; 
                            csvString += '\t';   
                            csvString += '\t';                
                            csvString += '\t'; 
                            csvString += genVon;
                            csvString += '\t'; 
                            csvString += genName; 
                            csvString += '\r\n';            
                                        
                        }
                        catch (System.Exception e) {
                            errorMsg += ' Genehmigung von/bis';
                            system.debug('#########################alex010 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + ' e=' + e );
                            csvError = true;
                            return null;
                        }
                        // ZZ-record
                        try {
                            if((lsp.Artikel__r.v_pos_1_Name__c == '51') && (!lsp.Lieferschein__r.Kunde_Zuzahlung_befreit__c)) {
                                zzberechnen = true;                    
                                csvString += 'ZZ\tJa\r\n';
                                // zzMethod = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.PG51_Abrechnungs_Methode__c;
                                // zzMenge = LsP.Menge__c; 
                            }
                            else {                  
                                csvString += 'ZZ\tNein\r\n';
                                zzberechnen = false;
                            }
                        }
                        catch (System.Exception e) {
                            errorMsg += ' zzberechnen';
                            system.debug('#########################alex011 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + ' e=' + e);
                            csvError = true;
                            return null;
                        }

                    } // tLS != LS


                    zzMethod = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.PG51_Abrechnungs_Methode__c;
                    zzMenge = LsP.Menge__c;
                    system.debug('#########################alex003b LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg);
                    string lDat = '';
                    string vzvDat = '';
                    string vzbDat = '';
                    try {
                    
                        if(lsp.Lieferdatum__c != null) {
                            lDat = datetime.newInstance(lsp.Lieferdatum__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                        }               
                        
                        if(lsp.VZ_von__c != null) {
                            vzvDat = datetime.newInstance(lsp.VZ_von__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                        }
                        
                        if(lsp.VZ_bis__c != null) {
                            vzbDat = datetime.newInstance(lsp.VZ_bis__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                        }  
                        }
                    catch (System.Exception e) {
                        errorMsg += ' Lieferdatum';
                        system.debug('#########################alex012 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg +  ' e=' + e);
                        csvError = true;
                        return null;
                    }
                    //system.debug('#########################alex003c LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg);
                    decimal preis = 0.0;
                    decimal menge = 0.0;
                    decimal betrag = 0.0;
                    string eigenanteil = '';    
                    string hkz = '';
                    string tk = '';
                    string ac = '';
                    // PO-record normal
                    try {
                        if(Lsp.Artikel__r.Anlage_4_Preis__c != null) preis = Lsp.Artikel__r.Anlage_4_Preis__c;
                        if(Lsp.Menge__c != null) menge = Lsp.Menge__c;
                        // decimal betrag = preis*menge;
                        betrag = preis;

                        
                            if(lsp.Kunde__r.Beihilfeberechtigt__c) {                    
                                // Hier ist noch die Klärung des Eigenanteils notwendig. Bezieht die sich auf den Einzelpreis (so wie jetzt) oder soll sie sich auf den
                                // Positionspreis beziehen?????   wds          
                                eigenanteil = ksgFunctions.formatCurrency(betrag / 2) ;
                            }
                        
                            if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c != null) {
                                hkz = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c;
                            }
                        
                            if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.TK__c != null) {
                                tk = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.TK__c;
                            }
                        
                            if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.AC__c != null) {
                                ac = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.AC__c;
                            }
                            // normale Position
                            if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c == null) {
                                csvString   += 'PO' 
                                            + '\t' + lsp.Artikel__r.Pflege_Hilfsmittelnr__c
                                            + '\t' + string.valueOf(lsp.Menge__c) 
                                            + '\t' + ksgFunctions.formatCurrency(betrag) 
                                            + '\t' + lsp.Artikel__r.Name 
                                            + '\t' + lDat 
                                            + '\t' + hkz
                                            + '\t' + vzvDat 
                                            + '\t' + vzbDat 
                                            + '\t' + lsp.Artikel__r.a_pac_apo_Mwst__c 
                                            + '\t' 
                                            + '\t' + ac
                                            + '\t' + tk
                                            + '\t' + eigenanteil
                                            + '\r\n';
                            }

                        // hier wird jetzt die Rechnungssumme (pro Lieferung) errechnet!!! wds
                        posSumme = posSumme + betrag * menge; 

                        if(pName == '51') {
                            posSumme = 0.0;
                            zzMethod = LsP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.PG51_Abrechnungs_Methode__c;
                            zzMenge = LsP.Menge__c;                            
                            if(zzMenge != null) posSumme = zzMenge * Lsp.Artikel__r.Anlage_4_Preis__c;                  
                        }                         
                    }
                    catch (System.Exception e) {
                        errorMsg += ' Artikelpreis / Positionsberag LP:' + lsp.name;
                        system.debug('#########################alex013 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + ' e=' + e  );
                        csvError = true;
                        return null;
                    }
                        
                    //system.debug('#########################alex003d LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg);
                    // system.debug('#########################alex417 posSumme=' + posSumme);
                    
                    // last SU-record in table
                    try {
                        if(lfnr == (LPlist.Size()+1)) {
                            if((pName != '51') && (tLP != null) && (tLP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c != null)) {
                                system.debug('#########################alex1401 tLP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c='  + tLP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c + ' pName=' + pName);
                                csvString += sonderRegelnAbrechnungPO(posSumme, tLP);
                            }

                            if(art == 1) {
                                if(zzberechnen) {
                                    csvString += 'SU\t' + printZuzahlung(posSumme, zzMenge, zzMethod);
                                }
                                else {
                                    csvString += 'SU\t'  + ksgFunctions.formatCurrency(posSumme) + '\t0\t' + ksgFunctions.formatCurrency(posSumme) + '\r\n'; 
                                }                       
                            }
                            else {
                                if(zzberechnen) {
                                    csvString += 'SU\t' + printZuzahlung(posSumme, zzMenge, zzMethod);
                                }
                                else {                                              
                                    csvString += 'SU\t'  + ksgFunctions.formatCurrency(posSumme) + '\t' + ksgFunctions.formatCurrency(posSumme / 2) + '\t' + ksgFunctions.formatCurrency(posSumme / 2) + '\r\n';   
                                }
                            }                    
                            posSumme = 0.00;                    
                        }   
                    }
                    catch (System.Exception e) {
                        errorMsg += ' Summe berechnen:';
                        system.debug('#########################alex04 LsP.Lieferschein__r.Name='  + LsP.Lieferschein__r.Name + ' Kunde=' + errorMsg + ' e=' + e);
                        csvError = true;
                        return null;
                    }                       
                    tLS = LsP.Lieferschein__r.Name;
                    tLP = LsP;
                    // und hier alle Daten die wir für Sonderregeln brauchen


                    
            }
        }
    } // end main-for 
    //system.debug('#########################alex204 posSumme=' + posSumme );
    //errorMsg += ' ganz am Ende. zeile=' + string.valueOf(cnt + 1);


    // last SU-record
    if(posSumme > 0) {
        try {
            if((pName != '51') && (tLP != null) && (tLP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c != null)) {
                system.debug('#########################alex1402 tLP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c='  + tLP.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c + ' pName=' + pName);
                csvString += sonderRegelnAbrechnungPO(posSumme, tLP);
            }

            if(art == 1) {
                //system.debug('#########################alex418 posSumme=' + posSumme);
                if(zzberechnenLast) {
                    csvString += 'SU\t' + printZuzahlung(posSumme, zzMengeLast, zzMethodLast);
                }
                else {
                    csvString += 'SU\t'  + ksgFunctions.formatCurrency(posSumme) + '\t0\t' + ksgFunctions.formatCurrency(posSumme) + '\r\n'; 
                }                       
            }
            else {
                //system.debug('#########################alex419 posSumme=' + posSumme);
                if(zzberechnenLast) {
                    csvString += 'SU\t' + printZuzahlung(posSumme, zzMengeLast, zzMethodLast);
                    // csvString += 'SU\t' + printZuzahlungBeihilfe(posSumme);
                }
                else {   
                    csvString += 'SU\t'  + ksgFunctions.formatCurrency(posSumme) + '\t0\t' + ksgFunctions.formatCurrency(posSumme) + '\r\n'; 
                    //  19.05.2018 csvString += 'SU\t'  + ksgFunctions.formatCurrency(posSumme) + '\t' + ksgFunctions.formatCurrency(posSumme / 2) + '\t' + ksgFunctions.formatCurrency(posSumme / 2) + '\r\n';   
                }
            }
        }
        catch (System.Exception e) {
            errorMsg += ' Falsch. posSumme=' + string.valueOf(posSumme) + ' zzMenge=' + string.valueOf(zzMenge) + ' zzMethod=' + zzMethod;
        }
        //system.debug('#########################alex420 posSumme=' + posSumme);
    }
    if(posSumme > 0) {
        system.debug('#########################alex421 csvString=' + csvString);
        try {
            csvBlob = Blob.valueOf(csvString);  
            system.debug('#########################alex425 OK');
            return csvBlob; 
        }
        catch (System.Exception e) {
            errorMsg += ' CSV-Datei erstellen';
            system.debug('#########################alex230 e=' + e  );
            csvError = true;
            return null;
        }     
    } 
    else {
        //csvError = true;
        system.debug('#########################alex422 posSumme=' + posSumme);
        return null;
    }     
      
    // }
    // catch(System.Exception e) {
    // system.debug('#########################alex420 error e=' + e);
    // csvError = true;
    // return null;
    // }
}

public string sonderRegelnAbrechnungPO(decimal posSumme, Lieferscheinposition__c lsp) {
    string pz = ' ';
    string lDat = '';
    string vzvDat = '';
    string vzbDat = '';
    string hkz = '';
    string tk = '';
    string ac = '';
    try {                                   
        if(lsp.Lieferdatum__c != null) {
            lDat = datetime.newInstance(lsp.Lieferdatum__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
        }                                                      
        if(lsp.VZ_von__c != null) {
            vzvDat = datetime.newInstance(lsp.VZ_von__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
        }                                        
        if(lsp.VZ_bis__c != null) {
            vzbDat = datetime.newInstance(lsp.VZ_bis__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
        }
        if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c != null) {
            hkz = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c;
        }

        if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.TK__c != null) {
            tk = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.TK__c;
        }

        if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.AC__c != null) {
            ac = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.AC__c;
        }
        pz  = 'PO' 
            + '\t' + lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c
            + '\t' + string.valueOf(1) 
            + '\t' + ksgFunctions.formatCurrency(posSumme) 
            + '\t' + 'CuraBox' 
            + '\t' + lDat 
            + '\t' + hkz
            + '\t' + vzvDat 
            + '\t' + vzbDat 
            + '\t' + lsp.Artikel__r.a_pac_apo_Mwst__c 
            + '\t' 
            + '\t' + ac
            + '\t' + tk
            + '\t' 
            + '\r\n';  
    }
    catch (System.Exception e) {       
        system.debug('#########################alex1012 e=' + e);       
    }
    return pz;
}

public string normaleAbrechnungPO(decimal posSumme, Lieferscheinposition__c lsp) {
    string pz = ' ';
    string lDat = '';
    string vzvDat = '';
    string vzbDat = '';
    string hkz = '';
    string tk = '';
    string ac = '';
    string eigenanteil = '';  
    decimal preis = 0.00;
    try {   
        if(Lsp.Artikel__r.Anlage_4_Preis__c != null) preis = Lsp.Artikel__r.Anlage_4_Preis__c;                                
        if(lsp.Lieferdatum__c != null) {
            lDat = datetime.newInstance(lsp.Lieferdatum__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
        }                                                      
        if(lsp.VZ_von__c != null) {
            vzvDat = datetime.newInstance(lsp.VZ_von__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
        }                                        
        if(lsp.VZ_bis__c != null) {
            vzbDat = datetime.newInstance(lsp.VZ_bis__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
        }
        if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c != null) {
            hkz = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c;
        }

        if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.TK__c != null) {
            tk = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.TK__c;
        }

        if(lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.AC__c != null) {
            ac = lsp.Auftragsposition__r.Auftrag__r.Kunde__r.Krankenkasse__r.AC__c;
        }

        if(lsp.Kunde__r.Beihilfeberechtigt__c) {                         
            eigenanteil = ksgFunctions.formatCurrency(preis / 2) ;
        }
        pz  = 'PO' 
            + '\t' + lsp.Artikel__r.Pflege_Hilfsmittelnr__c
            + '\t' + string.valueOf(lsp.Menge__c) 
            + '\t' + ksgFunctions.formatCurrency(preis) 
            + '\t' + lsp.Artikel__r.Name 
            + '\t' + lDat 
            + '\t' + hkz
            + '\t' + vzvDat 
            + '\t' + vzbDat 
            + '\t' + lsp.Artikel__r.a_pac_apo_Mwst__c 
            + '\t' 
            + '\t' + ac
            + '\t' + tk
            + '\t' + eigenanteil
            + '\r\n';
    }
    catch (System.Exception e) {       
        system.debug('#########################alex1012 e=' + e);       
    }
    return pz;
}

public string printZuzahlung(decimal d) {
    string pz = '';
    decimal zz = 0.00;
    decimal su = 0.00;
    if (d > 0) {
       zz = d / 10;
       if(zz > 10) zz = 10;
       su = d - zz;
       pz = ksgFunctions.formatCurrency(d) + '\t' + ksgFunctions.formatCurrency(zz) + '\t' + ksgFunctions.formatCurrency(su) + '\r\n'; 
    }
    return pz;
}

public string printZuzahlung(decimal d, decimal Menge, String abrMethode) {
    string pz = '';
    decimal gzProItem = 0.00;
    decimal mz = 0.00;
    decimal zz = 0.00;
    decimal su = 0.00;
    decimal proItem = 0.00;
    system.debug('#########################alex1104 d='  + d + ' Menge=' + Menge + ' abrMethode=' + abrMethode);
    if (d > 0) {
        if(abrMethode != null) {
            if (abrMethode.Contains('mindestens'))
            {
                mz = 5.00;
            }
        }

        if (abrMethode.Contains('pro Artikel')) {
            proItem = d / Menge;
            gzProItem = (proItem / 10).setScale(2, RoundingMode.HALF_UP);
            if (gzProItem > 10) gzProItem = 10.00;
            if ((mz > 0) && (gzProItem < mz)) gzProItem = mz;                  
            zz = (gzProItem * Menge).setScale(2, RoundingMode.HALF_UP);
        }
        else {
            zz = (d / 10).setScale(2, RoundingMode.HALF_UP);
            if(zz > 10) zz = 10;                    
        }


        su = d - zz;
        // 15.08.2017
        pz = ksgFunctions.formatCurrency(d) + '\t' + ksgFunctions.formatCurrency(zz) + '\t' + ksgFunctions.formatCurrency(su) + '\r\n'; 
        // 15.08.2017  pz = ksgFunctions.formatCurrency(su) + '\t0\t' + ksgFunctions.formatCurrency(su) + '\r\n';
        
    }

    return pz;
}

public string printZuzahlungBeihilfe(decimal d) {
    string pz = '';
    decimal zz = 0.00;
    decimal su = 0.00;
    decimal eb = 0.00;
    if (d > 0) {
       eb = d / 2;
       zz = d / 10;
       if(zz > 10) zz = 10;
       su = eb - zz;
       pz = ksgFunctions.formatCurrency(d) + '\t' + ksgFunctions.formatCurrency(zz) + '\t' + ksgFunctions.formatCurrency(su) + '\r\n'; 
    }
    return pz;
}

public list<SelectOption> mfKundenSelect {
    set;
    get {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Standard', 'Standard')); 
        options.add(new SelectOption('Medifox', 'Medifox'));        
        return options;
    }
}

public void setMfKunden(string mfKunden) {
this.mfKunden = mfKunden;
}
public string getMfKunden() {
return mfKunden;
}   


      // wird nicht aufgerufen! Nur für Testabdeckung!!!  
        public class dummyZeile {
                
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

        }    


}