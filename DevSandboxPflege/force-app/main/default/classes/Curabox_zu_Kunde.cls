//****************************************************************************************************************************
// Erstellt 26.10.2015 von BT
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Lead
//
//****************************************************************************************************************************
//
// Beschreibung:
//                
//
//****************************************************************************************************************************
//Änderungen:
//
// 09.11.2015 von wds   #105175040 zusätzlich noch name in Zeile 5xx korrekt zusammengesetzt! Update k deaktiviert
// 17.11.2015 von BT    #107465608 Pflegedienst-Anschrift auf Standardlieferanschrift setzen, auch bei bestehendem Pflegedienst
// 20.11.2015 von AM    #108605342 Prüfung nach 'PG54' über Kundenstatus__c. 
//                      Das Feld Produktgruppe__c beim Kunde__c wird nicht mehr berücksichtigt
// 04.01.2016 von BT    #108605214 Es wird nur eine Anschrift für den Angehöriger angelegt. 
// 04.01.2016 von BT    #107465608 Pflegedienst-Anschrift auf Standardlieferanschrift setzen, auch bei bestehendem Pflegedienst 
// 08.01.2016 von BT    Überprüfung, ob Postalcode beim Lead 5-stellig ist
// 11.01.2016 von BT    AD-Anschrift wird einmal angelegt
// 15.01.2016 von BT    #111403100 Übernahme der Marketingsdaten bei der Lead-Konvertierung (Ursprungsanfrage, Tracking Order ID, ...)
// 15.01.2016 von BT    #108755784 Löschen des Leerzeichens im Versicherungsnummer
// 29.01.2016 von BT    Das Feld 'Geburtsdatum__c' wird durch das Feld 'Geburtsdatum_text__c' erstetzt
// 14.03.2016 von AM    #115163045 CB-Cross-Selling: Leads aus strukturierten Emails anlegen 
//                      Die neue Felder Angeh_riger_Mobile__c, MobilePhone, CRM_Ticket_ID__c, Mitarbeiter__c, OM_Wizzard_Name__c (Ursprungsanfrage) 
// 30.03.2016 von BT    #115237727 "Art der Anschrift" auf "Betreuer" setzen, anstatt "Angehöriger"
// 31.03.2016 von BT    #115756203 Anlegen von PG51
// 22.04.2016 von BT    Anpassung Kundenstatus
// 22.07.2016 von BT    Verknüpfung Curabox <--> Pflege.de Kontakt
// 10.10.2016 von BT    Zuweisung von pflege.de-Familienangehörigen
// 25.10.2016 von WDS   Zusammensetzung des Adressennamens mit ', ' statt ',' Wichtig, da Adresse sonst nicht gefunden wird.
//                      wurde per email gemeldet
// 21.12.2016 von BT    Erweiterung um das Feld "Pflegegrad"
// 07.07.2017 von MZ    #148414467 linking lead to customer
// 12.07.2017 von MZ    #135048301 #148656721 addTask added
// 16.08.2017 von BT    Jetzt kommt eine Fehlermeldung, wenn das Lead nicht gefunden wurde.
// 20.09.2017 von BT    Erweiterung um das Feld "Pflegegrad seit"
// 25.10.2017 von MZ    case 00001306 - the lead is converted by SF standard lead convert. lead is not deleted any more.
// 29.07.2018 von SD    case 00001616 - das Feld Lead.Vorherige_Anfrage__c in das neue Feld Kunden__c.Vorherige_Anfrage__c 
//                          übernehmen (SD1616)
// 23.10.2018 von MZ    #161257706 Wizard_Version__c added
// 16.04.2019 von MZ    try-catch added on CANNOT_UPDATE_CONVERTED_LEAD
//****************************************************************************************************************************
//
global with sharing class Curabox_zu_Kunde {
    
    public static string DummyAccountName = 'DummyCuraboxAccount';
    public static string DummyContactName = 'DummyCuraboxContact';
    
    public String block = System.currentPagereference().getParameters().get('block');
    public Lead l {get; set;}
    public List<Lead> lead {get; set;}
    // public Kunde__c k {get; set;}
    // public Contact c {get; set;}
    public Account acc {get; set;}
    public transient attachment att {get; set;}

    //public Kunde__c kd {get; set;}

    public boolean fertig {get; set;}
    public boolean kdSelected {get; set;}
    public boolean contSelected {get; set;}
    public boolean pflgSelected {get; set;}
    public boolean fmAnSelected {get; set;}
    public boolean nofmAn {get; set;}
    
    private Kunde__c pdkunde = new Kunde__c();
    
    private list<Kunde__c> kdVorschlag = new list<Kunde__c>();
    private map<id, Kunde__c> kdMapVorschlag = new map<id, Kunde__c>();
    
    private list<account> pdVorschlag = new list<account>();
    private list<contact> anVorschlag = new list<contact>();
    private list<Contact> fmAnVorschlag = new list<contact>();  
    private list<Contact> fmEmpty = new list<contact>();

   // private boolean btnKonvert = false;
    private attachment attach = new attachment();
    
    private string selKd {get; set;}
    private string selPd {get; set;}
    private string selAn {get; set;}
    private string selFmAn {get; set;}
    
    private string msgKd = '';
    private string msgPd = '';
    private string msgAn = '';
    private string msgFmAn = '';
    
    private boolean hasPD = false;
    private boolean hasAN = false;
    private boolean hasFmAn = false;
    private boolean isNew = true;
    private boolean isNewAddress = true;
    private boolean isNewAng = false;
    private boolean isOldAng = false;
    private boolean isKeineAng = true;
    private boolean isNewPD = false;
    private boolean isGefPD = false;
    private boolean isKeinePD = true;    
    
    private integer seite = 1;
    private integer lastPage = 4;
    
    private map<string, string> HandschuheMap = new map<string, string>();
    private Anschrift__c pd_addr {get; set;}
    private Anschrift__c an_addr {get; set;}

    public Boolean disableSaveButton {get; set;}  
    
    global Curabox_zu_Kunde() {
        disableSaveButton = false;
    }
    
    global Curabox_zu_Kunde(ApexPages.StandardController controller) {
            disableSaveButton = false;
            makeHandschuheMap(); 
            konvertieren() ;
            
            if(fertig) {
                if(l.Angehoeriger_Email__c != null) {
                    if(validateEmail(l.Angehoeriger_Email__c) == false)
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Die Email-Adresse des Angehörigers hat kein korrektes Format !'));
                    }
                }
            }
    }
    
    public void seiteweiter() {
        if(pruefen()) {
            if(seite == 3) seite = 4;
            if(seite == 2 && hasAN == true) seite = 3;
            if(seite == 2 && hasAN == false) seite = 4;                
            if(seite == 1 && hasFmAn == true) seite = 2;
            if(seite == 1 && hasFmAn == false) {         
                if(hasAN == true) seite = 3;
                if(hasAN == false) seite = 4;
            }        
        }
    }
    
    public void seitezurueck() {
        if(seite == 2) seite = 1;
        if(seite == 3 && hasFmAn == true) seite = 2;
        if(seite == 3 && hasFmAn == false) seite = 1;
        if(seite == 4 && hasAN == true) seite = 3;
        if(seite == 4 && hasAN == false) {
            if(hasFmAn == true) seite = 2;
            if(hasFmAn == false) seite = 1;        
        }
    }
    
    private boolean pruefen() {
        boolean ok = true;
        if(selKd == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bitte wählen Sie einen Kunde aus'));
            ok = false;
        }
        if(selFmAn == null && hasFmAn && seite == 2 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bitte wählen Sie einen pflege.de-Familienangehörigen aus'));
            ok = false;
        }         
        if(selAn == null && hasAN && seite == 3 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bitte wählen Sie einen Angehörigen aus'));
            ok = false;
        }  
        if(selPd == null && hasPD && seite == 4 ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bitte wählen Sie eine Pflegedienst aus'));
            ok = false;
        }
        if(hasPD && isGefPD && pdkunde.Pflegedienst__c == null && seite == 3 && selPd == '1') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bitte finden Sie eine Pflegedienst aus'));
            ok = false;         
        }
        
        return ok;
    }
    
    public boolean konvertieren() {  
        // kdExistiert = 'Nein';
        // contExistiert = 'Nein';   
        // PflgExistiert = 'Nein';                   
        
        String qID = System.currentPagereference().getParameters().get('ID');
        lead = [SELECT Id, Company , firstname, lastname, Email, Kundennummer__c, Street, City, PostalCode,
                           salutation, Geburtsdatum__c, Pflegestufe__c, Phone, CB_Box__c, CB_Handschuh_Groesse__c, IK_Nummer_des_traegers__c, Kostentr_ger__c,
                           Angehoeriger_Vorname__c, Angehoeriger_Nachname__c, Angehoeriger_Email__c, Angehoeriger_Ort__c, Angehoeriger_PLZ__c, Angehoeriger_Strasse__c,
                           Angehoeriger_Anrede__c, Angehoeriger_Telefon__c, Fax, next_Step__c, CB_Lieferung__c, OM_Wizzard_Name2__c,
                           CB_Pflegedienst_Name__c, CB_Pflegedienst_Ort__c, CB_Pflegedienst_PLZ__c, CB_Pflegedienst_Strasse__c, Versicherungsnummer__c,
                           OM_Tracking_Order_ID__c, OM_Wizard_Version__c, OM_Referrer__c, OM_Partner_ID__c, OM_created_at__c, pflegegrad__c,
                            Mitarbeiter__c, CRM_Ticket_ID__c, MobilePhone, Angeh_riger_Mobile__c, Pflegegrad_seit__c,
                            Vorherige_Anfrage__c
                           FROM Lead WHERE Id =: qID LIMIT 1]; 
        try {
            l = lead[0];             
        }
        catch(system.exception e) {
            fertig = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Dieses Lead wurde wahrscheinlich gelöscht !'));
            system.debug('#####BT2017 : Lead mit ID + \'' + qID + '\' wurde nicht gefunden!');   
            
            return fertig;         
        }
                        
        lesenVorschlag(); 
        lesenFmAn();                 
        lesenAN();
        acc = sucheASPKunden();
        lesenPD();
        attach = checkAnhang();
        if(attach == null) {
            attach = new attachment();
        }
        id cbid = null;
        if(l.CB_Box__c != null) {
                string cbn = '%' + l.CB_Box__c.trim() + '%';
                list<Pflegebox__c> cbList = [SELECT id FROM Pflegebox__c WHERE name LIKE : cbn];
                if((cbList != null ) && (cbList.size() >0)) cbid = cbList[0].id;
        }
        pdkunde.Wunschbox__c = cbid;
        id hsid = null;
        if(l.CB_Handschuh_Groesse__c != null) {
                string hsn = l.CB_Handschuh_Groesse__c.toUppercase();
                list<Artikel__c> atList = [SELECT id FROM Artikel__c WHERE name = : HandschuheMap.get(hsn)];
                if((atList != null ) && (atList.size() >0)) hsid = atList[0].id;
        }       
        pdkunde.bevorzugter_Art_f_r_Einmalhandsch__c = hsid;
       
        if(l.Geburtsdatum__c != null) {
            pdkunde.Geburtsdatum_text__c = l.Geburtsdatum__c;
        }                
        
        if(l.Angehoeriger_Nachname__c != null) hasAN = true;
        
        if(l.CB_Pflegedienst_Name__c != null) hasPD = true;
        if(!hasPD) lastPage = 3;
        if(!hasPD && !hasAN) lastPage = 2;
        if(!hasPD && !hasAN && !hasFmAn) lastpage = 1;
        
        fertig = true;
        
        return fertig;
    }
    

    public Account sucheASPKunden() {
        List<Account> Acclist = [SELECT Id, Name, Kategorie__c FROM Account WHERE Name = 'ASP für Kunden' LIMIT 1];
        if((Acclist != null) && (Acclist.size() > 0)) {
            return Acclist[0];
        }
        else {
            return null;
        }
    }

    public void sendenMsg() {
        string msg = msgKd + ' ' + msgFmAn + ' ' + msgAn + ' ' + msgPd;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, msg));
    }
    
    public void reload(){
        selKd = System.currentPagereference().getParameters().get('kundeid');
        if(selKd == '9') {
            msgKd = 'Neuen Kunden anlegen.';
            isNewAddress = true;
            isNew = true;
        }
        else {
            msgKd = 'Bestehendem Kunden zuweisen.';
            isNewAddress = false;
            string ldAddr = l.Street + ', ' + l.PostalCode + ' ' + l.City;
            if(ldAddr != kdMapVorschlag.get(id.valueOf(selKd)).komb_Adresse__c) {
                msgKd = 'Bestehendem Kunden zuweisen. Eine neue Kundenadresse wird angelegt.';
                isNewAddress = true;
            }
            isNew = false;
        }
        
        system.debug('##########alex001 selkd=' + selkd + ' selpd=' + selpd + ' selan=' + selan);
        sendenMsg();
        // return pageRef;

    }
    
    public void selpdid () {
        selPd = System.currentPagereference().getParameters().get('pdid');
        if(selPd == '0') {
            msgPd = 'Keine Pflegedienst anlegen.';
            isNewPD = false;
            isGefPD = false;
            isKeinePD = true;
        }
         else if(selPd == '9') {
            msgPd = 'Eine neue Pflegedienst anlegen.';
            isNewPD = true;
            isGefPD = false;
            isKeinePD = false;          
        }
        else if(selPd == '1') {
            msgPd = 'Bestehendem Pflegedienst zuweisen.';
            isNewPD = false;
            isGefPD = true;
            isKeinePD = false;  
    
        }
        else {
            msgPd = 'Bestehendem Pflegedienst zuweisen.';
            isNewPD = false;
            isGefPD = false;
            isKeinePD = false;              
        }
        sendenMsg();
        system.debug('##########alex101 selkd=' + selkd + ' selpd=' + selpd + ' selan=' + selan);
    }
    
    public void selAngId () {
        selAn = System.currentPagereference().getParameters().get('angid');
        if(selAn == '0') {
            msgAn = 'Keinen Angehöriger anlegen.';
            isNewAng = false;
            isOldAng = false;
            isKeineAng = true;
        }
        else if(selAn == '9') {
            msgAn = 'Neuen Angehörigen anlegen.';
            isNewAng = true;
            isOldAng = false;
            isKeineAng = false;
        } 
        else {
            msgAn = 'Bestehendem Angehörigen zuweisen.';
            isNewAng = false;
            isOldAng = true;
            isKeineAng = false;         
        }
        sendenMsg();
        system.debug('##########alex001 selkd=' + selkd + ' selpd=' + selpd + ' selan=' + selan);
    }
    
    public void selFmAnId(){
        selFmAn = System.currentPagereference().getParameters().get('fmAnid');      
        msgFmAn = 'Bestehenden pflege.de-Familienangehörigen zuweisen.';
        system.debug('mansi:::::::::: selFmAn '+ selFmAn );
        if(selFmAn == '0'){msgFmAn = 'keinen pflege.de-Familienangehörigen zuweisen.';}
        sendenMsg();
        system.debug('##########alex001 selkd=' + selkd + ' selpd=' + selpd + ' selan=' + selan + ' selFmAn=' + selFmAn);
    }
    
    public PageReference zurueck(){
        PageReference pageRef = new PageReference('/' + l.id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public PageReference konvertieren_los() { 
        disableSaveButton = true;
        Boolean upgedatet = false;
        Boolean insertKd = false;
        
        if(pruefen()) {
            System.debug('##########alex299');
            string lieferanschrift = null;
            if(l.CB_Lieferung__c == 'insured_person') lieferanschrift = 'Adresse Patient';
            if(l.CB_Lieferung__c == 'care_person') lieferanschrift = 'Adresse Pflegeperson';
            if(l.CB_Lieferung__c == 'care_service') lieferanschrift = 'Adresse Pflegedienst';
                
            // Pflegedienst
            id pfdID = null;
            if(isNewPD) {
                Account pflgdienst = new Account();
                pflgdienst.Name = l.CB_Pflegedienst_Name__c;
                pflgdienst.Kategorie__c = '01 Ambulante Pflegedienste';
                pflgdienst.BillingStreet = l.CB_Pflegedienst_Strasse__c;
                pflgdienst.BillingPostalCode = l.CB_Pflegedienst_PLZ__c;
                pflgdienst.BillingCity = l.CB_Pflegedienst_Ort__c; 
                /**           
                pd_addr = new Anschrift__c();
                pd_addr.Art_der_Anschrift__c = 'Pflegedienst';
                pd_addr.Name = l.CB_Pflegedienst_Name__c;
                pd_addr.Ort__c = l.CB_Pflegedienst_Ort__c;
                if(l.CB_Pflegedienst_PLZ__c != null) pd_addr.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.CB_Pflegedienst_PLZ__c));
                pd_addr.Stra_e__c = l.CB_Pflegedienst_Strasse__c;
                **/
                //if(l.CB_Lieferung__c == 'care_service') pd_addr.Standardlieferanschrift__c = true;              
                try {
                    insert pflgdienst;
                    pfdID = pflgdienst.id;
                }
                catch (System.Exception e){
                    system.debug('##########bt2015: Pflegedienst konnte nicht erstellt werden');
                }               
            }
            else if(isGefPD) {
                pfdID = pdkunde.Pflegedienst__c;                
            }
            else if(isKeinePD) {
                
            }
            else {
                pfdID = id.valueOf(selPd);
                system.debug('##########alex200 pfdID=' + pfdID);
            }
            
            // Angehöriger
            id cnid = null;
            if(isNewAng) {
                Contact cont = new Contact();
                if(acc != null) cont.AccountId = acc.id;
                cont.salutation = l.Angehoeriger_Anrede__c;
                cont.firstname = l.Angehoeriger_Vorname__c;
                cont.lastname = l.Angehoeriger_Nachname__c;
                cont.Phone = l.Angehoeriger_Telefon__c;
                cont.Email = l.Angehoeriger_Email__c;
                cont.MailingStreet = l.Angehoeriger_Strasse__c;
                cont.MailingPostalCode = l.Angehoeriger_PLZ__c;
                cont.MailingCity = l.Angehoeriger_Ort__c; 
                cont.MobilePhone = l.Angeh_riger_Mobile__c;
                cont.Pflegegrad__c = l.pflegegrad__c;
                /**                  
                an_addr = new Anschrift__c();
                an_addr.Art_der_Anschrift__c = 'Angehöriger';
                an_addr.Name = l.Angehoeriger_Nachname__c + ',' + l.Angehoeriger_Vorname__c;
                an_addr.Ort__c = l.Angehoeriger_Ort__c; 
                an_addr.Anrede__c = l.Angehoeriger_Anrede__c;
                an_addr.e_mail__c = l.Angehoeriger_Email__c;
                an_addr.Telefon__c = l.Angehoeriger_Telefon__c;                 
                if(l.Angehoeriger_PLZ__c != null) an_addr.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.Angehoeriger_PLZ__c));
                an_addr.Stra_e__c = l.Angehoeriger_Strasse__c;
                if(l.CB_Lieferung__c == 'care_person') an_addr.Standardlieferanschrift__c = true;  
                **/                                               
                try {
                    insert cont;
                    cnid = cont.id;
                }
                catch (System.Exception e){
                    system.debug('##########bt2015: Kontakt konnte nicht erstellt werden');
                }               
            }
            else if (isOldAng) {
                cnid = id.valueOf(selAn);
            }
            
            // Familienangehöriger
            id fmAnId = null;
            if(hasFmAn == true){
                if(selFmAn != '0') fmAnId = id.valueOf(selFmAn);
            }
            
            // Kunde
            system.debug('##########alex201 isNew=' + isNew);
            id kdid = null;
            if(isNew) {
                Kunde__c kd = new Kunde__c();               
                kd.Kundennummer__c = aktuellerKdNr()+ 1;  
                kd.suchfeld_kundennr__c='CB14-' + String.valueof( kd.Kundennummer__c );        
                kd.lead__c = l.id;   
                kd.Anrede__c = l.salutation;
                if (l.firstname == null) 
                    {kd.vorname__c = ' ';
                     kd.name = l.lastname;}
                Else {
                    kd.name = l.lastname + ', ' + l.firstname;
                    kd.vorname__c = l.firstName;}
//               kd.Vorname__c = l.firstname;
                kd.Name__c = l.lastname;
//                kd.name = l.lastname + ',' + l.firstname;
                kd.Stra_e__c = l.Street;            
                if((l.PostalCode != null) && (l.PostalCode.length() == 5)) {
                    try {
                        if(Decimal.valueOf(l.PostalCode) != null) {
                            kd.PLZ__c = Decimal.valueOf(l.PostalCode);
                        }
                    }
                    catch (System.Exception e) {
                        
                    }
                }
                kd.Ort__c = l.City;
                kd.Geburtsdatum_text__c = pdkunde.Geburtsdatum_text__c;
                kd.Pflegestufe__c = l.Pflegestufe__c;
                kd.Telefon__c = l.Phone;    
                kd.Mobil__c = l.MobilePhone;
                kd.Mitarbeiter__c = l.Mitarbeiter__c;
                kd.CRM_Ticket__c = l.CRM_Ticket_ID__c;
                kd.e_mail__c = l.Email;             
                kd.Wunschbox__c = pdkunde.Wunschbox__c;
                kd.Pflegegrad_seit__c = l.Pflegegrad_seit__c;
                kd.bevorzugter_Art_f_r_Einmalhandsch__c = pdkunde.bevorzugter_Art_f_r_Einmalhandsch__c;
                kd.Krankenkasse__c = pdkunde.Krankenkasse__c;
                kd.Pflegedienst__c = pfdID;
                kd.Pflegegrad__c = l.pflegegrad__c;
                //if(l.versicherungsnummer__c != null) kd.Versichertennummer__c = l.versicherungsnummer__c.remove(' ');
                if(l.versicherungsnummer__c != null) kd.Versichertennummer__c = l.versicherungsnummer__c;
                
                id ursp = pdkunde.Ursprungsanfrage__c;              
                if(ursp == null ) {
                     ursp = l.OM_Wizzard_Name2__c;                     
                }
                kd.Ursprungsanfrage__c = ursp;
                
                if(l.IK_Nummer_des_traegers__c != null) {
                    try {
                        if(Decimal.valueOf(l.IK_Nummer_des_traegers__c) != null) {
                            kd.IK_Nummer_des_Tr_gers__c = Decimal.valueOf(l.IK_Nummer_des_traegers__c) ; 
                        }
                    }
                    catch(System.Exception e) {
                    }
                }                   
                kd.Produktgruppe__c = 'PG54;PG51';   
                kd.Lieferadresse__c = lieferanschrift;
                if(cnid != null) {
                    kd.Betreuer__c = cnid;                                          
                }
                
                if(fmAnId != null) {
                    kd.Passendes_Familienmitglied__c = fmAnId;   
                }
                //SD1616
                kd.Vorherige_Anfrage__c = l.Vorherige_Anfrage__c;
                
                try {  
                     Database.DMLOptions dml = new Database.DMLOptions();
                     dml.DuplicateRuleHeader.AllowSave = true;  
                     Database.SaveResult sr = Database.insert(kd, dml); 
                     system.debug('##########bt2015 kdId = :' + kd.Id);
                     kdid = kd.id;   
                     insertKd = true;
                    
                     if(fmAnId != null){
                        List<Contact> contList = [select id, Passender_CB_Kunde__c from Contact where id =: fmAnId LIMIT 1];
                        contList[0].Passender_CB_Kunde__c = kd.id; 
                        
                        try{
                            update contList[0];
                        }
                        catch(system.exception e){
                            system.debug('##########BT2016    Contact konnte nicht upgedatet werden');
                        }                     
                     }             
                     
                     if(cnid != null){
                        List<Contact> cnList = [select id, Pflegegrad__c from Contact where id =: cnid LIMIT 1];
                        cnList[0].Pflegegrad__c = l.pflegegrad__c; 
                        
                        try{
                            update cnList[0];
                        }
                        catch(system.exception e){
                            system.debug('##########BT2016    Contact konnte nicht upgedatet werden');
                        }                     
                     }  
                }
                catch (System.Exception e){
                    system.debug('##########bt2015: Kunde konnte nicht erstellt werden');
                    insertKd = false;
                }  
                
                List<Kundenstatus__c> Kdstlist = [SELECT Kunde__c, Produktgruppe__c, Ursprungsanfrage__c, Tracking_Order_ID__c, Wizard_Version__c, Referrer__c, Partner_ID__c, Created_at__c, CRM_Ticket_ID__c
                                                        FROM Kundenstatus__c WHERE Kunde__c =: kdid AND Produktgruppe__c IN ('PG54', 'PG51') ];                                      
                    
                    if((Kdstlist != null) && (Kdstlist.size() > 0)) {        
                        for(Kundenstatus__c kdst: Kdstlist) {                
                            kdst.Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c;
                            kdst.Wizard_Version__c = l.OM_Wizard_Version__c;
                            kdst.Referrer__c = l.OM_Referrer__c;
                            kdst.Partner_ID__c = l.OM_Partner_ID__c;
                            kdst.Created_at__c = l.OM_created_at__c;
                            kdst.CRM_Ticket_ID__c = l.CRM_Ticket_ID__c;
                            
                            if(ursp != null)  kdst.Ursprungsanfrage__c = ursp;
                        }
                        
                        try{
                            update Kdstlist;
                            update kd;
                        }
                        catch(System.exception e) {
                            system.debug('##########bt2016: Kundenstatus konnte nicht upgedatet werden');
                        }
                        
                    }
                    else {
                        Kundenstatus__c kdst54 = new Kundenstatus__c ( Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c,
                                                                     Wizard_Version__c = l.OM_Wizard_Version__c,
                                                                     Referrer__c = l.OM_Referrer__c,
                                                                     Produktgruppe__c = 'PG54',
                                                                     Partner_ID__c = l.OM_Partner_ID__c,
                                                                     Created_at__c = l.OM_created_at__c,
                                                                     CRM_Ticket_ID__c = l.CRM_Ticket_ID__c,
                                                                     Kunde__c = kdid);
                        
                        Kundenstatus__c kdst51 = new Kundenstatus__c ( Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c,
                                                                     Wizard_Version__c = l.OM_Wizard_Version__c,
                                                                     Referrer__c = l.OM_Referrer__c,
                                                                     Produktgruppe__c = 'PG51',
                                                                     Partner_ID__c = l.OM_Partner_ID__c,
                                                                     Created_at__c = l.OM_created_at__c,
                                                                     CRM_Ticket_ID__c = l.CRM_Ticket_ID__c,
                                                                     Kunde__c = kdid);
                        
                        if(ursp != null)  {
                            kdst54.Ursprungsanfrage__c = ursp;
                            kdst51.Ursprungsanfrage__c = ursp;
                        }
                        
                        try{
                            insert kdst54; 
                            insert kdst51;
                            update kd;
                        }
                        catch(System.exception e) {
                            system.debug('##########bt2016: Kundenstatus konnte nicht angelegt werden');
                        }
                    } 
                // Anschrift__c cb_addr = new Anschrift__c();
                // cb_addr.Name = l.lastname + ',' + l.firstname;
                // cb_addr.Anrede__c = l.Salutation;
                // cb_addr.Kunde__c = kdid;
                // cb_addr.Art_der_Anschrift__c = 'Kundenadresse';
                // cb_addr.e_mail__c = l.Email;
                // cb_addr.Fax__c = l.Fax;
                // cb_addr.Ort__c = l.City;
                // if(l.PostalCode != null) cb_addr.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.PostalCode));
                // cb_addr.Stra_e__c = l.Street;
                // cb_addr.Telefon__c = l.Phone;  
                    
                // if(l.CB_Lieferung__c == 'insured_person') cb_addr.Standardlieferanschrift__c = true;
                // insert cb_addr;  
                if((cnid != null) && (insertKd == true)) {
                List<Anschrift__c> Anlist = [SELECT Name, e_mail__c, Art_der_Anschrift__c FROM Anschrift__c WHERE e_mail__c =: l.Angehoeriger_Email__c
                                                AND Name =: l.Angehoeriger_Vorname__c + ' ' + l.Angehoeriger_Nachname__c
                                                AND Art_der_Anschrift__c = 'Betreuer' LIMIT 1];  
                       
                       if((Anlist != null) && (Anlist.size() > 0)){                           
                           try {
                               Anlist[0].Name = l.Angehoeriger_Nachname__c + ',' + l.Angehoeriger_Vorname__c;
                               if(l.CB_Lieferung__c == 'care_person') Anlist[0].Standardlieferanschrift__c = true; 
                               update Anlist[0];
                               update kd;
                           }
                           catch(System.exception e) {
                               system.debug('##########bt2015: Update fehlgeschlagen');
                           }                  
                       }
                }                
                
                if((pfdID != null) && (insertKd == true)) {
                List<Anschrift__c> pfdlist = [SELECT Name, Art_der_Anschrift__c FROM Anschrift__c WHERE Name =: l.CB_Pflegedienst_Name__c
                                                AND Art_der_Anschrift__c = 'Pflegedienst' LIMIT 1];  
                       
                       if((pfdlist != null) && (pfdlist.size() > 0)){                           
                           try {
                               if(l.CB_Lieferung__c == 'care_service') pfdlist[0].Standardlieferanschrift__c = true;
                               update pfdlist[0];
                               update kd;
                           }
                           catch(System.exception e) {
                               system.debug('##########bt2015: Update fehlgeschlagen');
                           }                  
                       }
                }
                                
            }
            else {
                kdid = id.valueOf(selKd);
                Kunde__c kd = kdMapVorschlag.get(kdid);
                kd.Lieferadresse__c = lieferanschrift;
                kd.Pflegegrad__c = l.pflegegrad__c;
                kd.Pflegegrad_seit__c = l.Pflegegrad_seit__c;
                if(kd.lead__c == null){
                    kd.lead__c = l.id;
                }
                system.debug('##########alex202 kd=' + kd);
                if(!kd.Produktgruppe__c.contains('PG54')) {
                    kd.Produktgruppe__c = kd.Produktgruppe__c + ';PG54';
                }
                if(!kd.Produktgruppe__c.contains('PG51')) {
                    kd.Produktgruppe__c = kd.Produktgruppe__c + ';PG51';
                }
                if(cnid != null) {
                    kd.Betreuer__c = cnid;                                                                                                    
                }
                if(fmAnId != null) {
                    kd.Passendes_Familienmitglied__c = fmAnId;
                }
        
                try {
                    update kd;
                    upgedatet = true;                    
                }
                catch (System.Exception e) {
                        system.debug('##########bt2015: Der Kunde konnte nicht upgedatet werden');
                        upgedatet = false;
                }  
                
                if(fmAnId != null){
                    List<Contact> contList = [select id, Passender_CB_Kunde__c from Contact where id =: fmAnId LIMIT 1];
                    contList[0].Passender_CB_Kunde__c = kd.id;  
                    
                    try{
                        update contList[0];                        
                    }                 
                    catch(system.exception e){
                        system.debug('#############BT2016    Contact konnte nicht upgedatet werden');
                    }
                }

                // id ursp = null;
                // if(l.OM_Wizzard_Name2__c != null) {
                    // list<Campaign> cmList = [SELECT Name, id FROM Campaign WHERE Name = : l.OM_Wizzard_Name2__c];
                    // if((cmList != null) && (cmList.size() > 0)) {
                            // ursp = cmList[0].id;                  
                    // }
                // } 
                
                id ursp = pdkunde.Ursprungsanfrage__c;              
                if(ursp == null ) {
                      ursp = l.OM_Wizzard_Name2__c;                   
                }
                
                
                List<Kundenstatus__c> Kdstlist = [SELECT Kunde__c, Produktgruppe__c, Ursprungsanfrage__c, Tracking_Order_ID__c, Wizard_Version__c, Referrer__c, Partner_ID__c, Created_at__c, CRM_Ticket_ID__c
                                                        FROM Kundenstatus__c WHERE Kunde__c =: kdid AND Produktgruppe__c IN ('PG54', 'PG51') ];                                      
                    
                    if((Kdstlist != null) && (Kdstlist.size() > 0)) {        
                        for(Kundenstatus__c kdst: Kdstlist) {                
                            kdst.Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c;
                            kdst.Wizard_Version__c = l.OM_Wizard_Version__c;
                            kdst.Referrer__c = l.OM_Referrer__c;
                            kdst.Partner_ID__c = l.OM_Partner_ID__c;
                            kdst.Created_at__c = l.OM_created_at__c;
                            kdst.CRM_Ticket_ID__c = l.CRM_Ticket_ID__c;
                            
                            if(ursp != null)  kdst.Ursprungsanfrage__c = ursp;
                        }
                        
                        try{
                            update Kdstlist;
                            update kd;
                        }
                        catch(System.exception e) {
                            system.debug('##########bt2016: Kundenstatus konnte nicht upgedatet werden');
                        }
                        
                    }
                    else {
                        Kundenstatus__c kdst54 = new Kundenstatus__c ( Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c,
                                                                     Wizard_Version__c = l.OM_Wizard_Version__c,
                                                                     Referrer__c = l.OM_Referrer__c,
                                                                     Produktgruppe__c = 'PG54',
                                                                     Partner_ID__c = l.OM_Partner_ID__c,
                                                                     Created_at__c = l.OM_created_at__c,
                                                                     CRM_Ticket_ID__c = l.CRM_Ticket_ID__c,
                                                                     Kunde__c = kdid);
                        
                        Kundenstatus__c kdst51 = new Kundenstatus__c ( Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c,
                                                                     Wizard_Version__c = l.OM_Wizard_Version__c,
                                                                     Referrer__c = l.OM_Referrer__c,
                                                                     Produktgruppe__c = 'PG51',
                                                                     Partner_ID__c = l.OM_Partner_ID__c,
                                                                     Created_at__c = l.OM_created_at__c,
                                                                     CRM_Ticket_ID__c = l.CRM_Ticket_ID__c,
                                                                     Kunde__c = kdid);
                        
                        if(ursp != null)  {
                            kdst54.Ursprungsanfrage__c = ursp;
                            kdst51.Ursprungsanfrage__c = ursp;
                        }
                        
                        try{
                            insert kdst54; 
                            insert kdst51;
                            update kd;
                        }
                        catch(System.exception e) {
                            system.debug('##########bt2016: Kundenstatus konnte nicht angelegt werden');
                        }
                    }
                                                        
                
                if((cnid != null) && (upgedatet == true)) {
                List<Anschrift__c> Anlist = [SELECT Name, e_mail__c, Art_der_Anschrift__c FROM Anschrift__c WHERE e_mail__c =: l.Angehoeriger_Email__c
                                                AND Name =: l.Angehoeriger_Vorname__c + ' ' + l.Angehoeriger_Nachname__c
                                                AND Art_der_Anschrift__c = 'Betreuer' LIMIT 1];  
                       
                       if((Anlist != null) && (Anlist.size() > 0)){                           
                           try {
                               Anlist[0].Name = l.Angehoeriger_Nachname__c + ',' + l.Angehoeriger_Vorname__c;
                               if(l.CB_Lieferung__c == 'care_person') Anlist[0].Standardlieferanschrift__c = true; 
                               update Anlist[0];
                               update kd;
                           }
                           catch(System.exception e) {
                               system.debug('##########bt2015: Update fehlgeschlagen');
                           }                  
                       }
                }           
                
                if((pfdID != null) && (upgedatet == true)) {
                List<Anschrift__c> pfdlist = [SELECT Name, Art_der_Anschrift__c FROM Anschrift__c WHERE Name =: l.CB_Pflegedienst_Name__c
                                                AND Art_der_Anschrift__c = 'Pflegedienst' LIMIT 1];  
                       
                       if((pfdlist != null) && (pfdlist.size() > 0)){                           
                           try { 
                               if(l.CB_Lieferung__c == 'care_service') pfdlist[0].Standardlieferanschrift__c = true;
                               update pfdlist[0];
                               update kd;
                           }
                           catch(System.exception e) {
                               system.debug('##########bt2015: Update fehlgeschlagen');
                           }                  
                       }
                }
                
                system.debug('##########alex203 isNewAddress=' + isNewAddress);
                if(isNewAddress) {
                    Anschrift__c cb_addr = new Anschrift__c();
                    cb_addr.Name = l.lastname + ', ' + l.firstname;
                    cb_addr.Anrede__c = l.Salutation;
                    cb_addr.Kunde__c = kdid;
                    cb_addr.Art_der_Anschrift__c = 'Kundenadresse';
                    cb_addr.e_mail__c = l.Email;
                    cb_addr.Fax__c = l.Fax;
                    cb_addr.Ort__c = l.City;
                    if(l.PostalCode != null) cb_addr.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.PostalCode));
                    cb_addr.Stra_e__c = l.Street;
                    cb_addr.Telefon__c = l.Phone;  
                    
                    if(l.CB_Lieferung__c == 'insured_person') cb_addr.Standardlieferanschrift__c = true;
                    insert cb_addr;                             
                }
            }
            
            if(an_addr != null) {
                an_addr.Kunde__c = kdid;
                insert an_addr;
            }
            else {
                if(cnid != null) {
                    List<Contact> Contlist= [SELECT Id, firstname, lastname, Email, mailingstreet, mailingpostalcode, mailingcity, Phone, salutation
                                            FROM contact
                                            WHERE Id =: cnid
                                            LIMIT 1];
                                
                    List<Anschrift__c> Anlist = [SELECT Id, Art_der_Anschrift__c, Name, Kunde__c, Standardlieferanschrift__c
                                                 FROM Anschrift__c
                                                 WHERE Art_der_Anschrift__c = 'Betreuer'
                                                 AND Kunde__c =: kdid
                                                 AND Name =: Contlist[0].lastname + ',' + Contlist[0].firstname                                                              
                                                 LIMIT 1 ];
                   if((Anlist != null) && (Anlist.size() > 0))   {  
                       Anlist[0].Name = l.Angehoeriger_Nachname__c + ',' + l.Angehoeriger_Vorname__c;          
                       if(l.CB_Lieferung__c == 'care_person') Anlist[0].Standardlieferanschrift__c = true;
                   
                       try{
                           update Anlist[0];
                       }
                       catch(System.exception e){
                           system.debug('##########BT101 Bestehender Anschrift konnte nicht upgedatet werden');
                       }
                   }
                }
            }
            
            if(pd_addr != null) {
                pd_addr.Kunde__c = kdid;                
                insert pd_addr;
            }   
            else {
                if(pfdID != null) {
                    List<Account> PDlist= [SELECT Id, Name, Kategorie__c, billingstreet, billingpostalcode, billingcity   
                                            FROM Account 
                                            WHERE Id =: pfdID 
                                            LIMIT 1];
                                
                    List<Anschrift__c> Anlist = [SELECT Id, Art_der_Anschrift__c, Name, Kunde__c, Standardlieferanschrift__c
                                                 FROM Anschrift__c
                                                 WHERE Art_der_Anschrift__c = 'Pflegedienst'
                                                 AND Kunde__c =: kdid
                                                 AND Name =: PDlist[0].Name
                                                 LIMIT 1 ];
                    
                    if((Anlist != null) && (Anlist.size() > 0))   {        
                        if(l.CB_Lieferung__c == 'care_service') Anlist[0].Standardlieferanschrift__c = true;
                    
                        try{
                            update Anlist[0];
                        }
                        catch(System.exception e){
                            system.debug('##########BT101 Bestehender Anschrift konnte nicht upgedatet werden');
                        }
                   } 
                }
            }        

            att = lesenAtt();
            system.debug('##########alex100 k.id=' + kdid + ' att.name=' + att.name);
            try {
            if((kdid != null) && (att != null)) {
                att.parentid = kdid;
                insert att;
            }
            }
            catch (System.Exception e) {}
            
            createTask(kdid);
            //MZ addTask(kdid, 'Formular per Email versandt', 'Formular per Email versandt');
            
            /***** change to use SF standard lead conversion class. to set the flag isConverted and convertedDate field****/
            //l.Status = 'Qualified';
            //update l;
            saveWithSatndardLeadConvert(l.Id);
            
            if(l.next_step__c != null) {
                if(l.next_Step__c.contains('blanko per Email') || l.next_Step__c.contains('ausgefüllt per Email')) {    
                    
                    // MZ update kd;
                    List<Kunde__c> kdList = [select id, e_mail__c, Betreuer__c, Betreuer__r.Email 
                                                    from Kunde__c
                                                    where id =: kdid  // MZ kd.id
                                                    limit 1 ];
                                                                                                      
                    Formular_versenden fv = new Formular_versenden();
                    fv.KdID = kdid; // MZ kd.id;
                    
                    if(l.next_Step__c.contains('Versicherten')) {
                            fv.addTask('Formular per Email versandt', 'Formular per Email versandt an Kunde ' + 
                                                                    '(' + kdList[0].e_mail__c + ')');                                      
                    }              
                
                    if(l.next_Step__c.contains('Angehörigen')){                                         
                            fv.addTask('Formular per Email versandt', 'Formular per Email versandt an Angehöriger ' + 
                                                                    '(' + kdList[0].Betreuer__r.Email + ')');                                                           
                    }     
                                
                    // MZ update kd;
                
                    PageReference pageRef = new PageReference('/' + kdid);
                    return pageRef;                      
                }
                else {
                    PageReference pageRef = new PageReference('/apex/Formular_versenden?fmType=formular&id=' + kdid);

                    //pageRef.setRedirect(true);
                    return pageRef;             
                }
            }
            else {
                PageReference pageRef = new PageReference('/apex/Formular_versenden?fmType=formular&id=' + kdid);
                //pageRef.setRedirect(true);
                return pageRef;
            }
            
            // MZ PageReference pageRef = new PageReference('/apex/Formular_versenden?fmType=formular&id=' + kdid);

            //pageRef.setRedirect(true);
            // MZ return pageRef;         
        
        }
        else {
            return null;
        }
    }
    
    public void konvertieren_zu_Kunde() { 
    }
    
    public Date setStringToDateFormat(String myDate) { 
       try {
           String myDateOnly = myDate.replace('.', '/');              
           String[] strDate = myDateOnly.split('/');
           Integer myIntDate = integer.valueOf(strDate[0]);
           Integer myIntMonth = integer.valueOf(strDate[1]);
           Integer myIntYear = integer.valueOf(strDate[2]);
           
           
           if (myIntYear < 1700){
               myintYear = 1700;
           }
           else{
               if (myintyear > 4000){
                   myintyear = 4000;
               }
           }
           
           Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
       
           return d;
       }
       catch(System.exception e) {
            system.debug ('##################################BT Ungültiges Datum');            
       
            return null;
       }
    }
    
    public Decimal aktuellerKdNr() {
        Decimal KdNr = 0;

        list<Kunde__c> agKdnr = [SELECT Kundennummer__c 
                                    FROM Kunde__c 
                                    ORDER BY Kundennummer__c DESC NULLS LAST
                                    LIMIT 1];
        if(agKdnr != null) {
            try {
                KdNr = (decimal)agKdnr[0].Kundennummer__c;
            }
            catch (System.Exception e) {
                system.debug ('################################## kdnr error ' + e);
            }   
        }
        
        return KdNr;
    }
    
    public Decimal aktuellerKdNr_wrong() {
        Decimal KdNr = 0;

        AggregateResult[] agKdnr = [SELECT MAX(Kundennummer__c) kdnr FROM Kunde__c];
        if(agKdnr != null) {
            try {
                KdNr = (decimal)agKdnr[0].get('kdnr');
            }
            catch (System.Exception e) {
                system.debug ('################################## kdnr error ' + e);
            }   
        }
        
        return KdNr;
    }
    
    public attachment lesenAtt() {
        attachment att = new attachment();
        list<attachment> attList = [SELECT id, body, name, parentid, ContentType FROM attachment WHERE parentid = : l.id LIMIT 10];
        if((attList != null) && (attList.size() > 0)) {
            att.name = attList[0].name;
            att.body = attList[0].body;
            att.ContentType = attList[0].ContentType;
        }   
        return att;
    }
    
    private list<Kunde__c> lesenVorschlag() {
        if(l.Versicherungsnummer__c != null) {                        
            kdVorschlag = [SELECT id, Name__c, Vorname__c, e_mail__c, Versichertennummer__c, 
                                            komb_Adresse__c, 
                                            Betreuer__c, 
                                            Pflegegrad__c,
                                            Pflegedienst__c, 
                                            Produktgruppe__c,
                                            (SELECT Produktgruppe__c, Status__c FROM Kundenstatus__r) st,
                                            Geburtsdatum_text__c,
                                            Wunschbox__c,
                                            bevorzugter_Art_f_r_Einmalhandsch__c,
                                            lead__c
                                 FROM Kunde__c 
                                 WHERE Versichertennummer__c =: l.Versicherungsnummer__c];
                                 //WHERE Versichertennummer__c =: l.Versicherungsnummer__c.remove(' ')]; 
        }
        else {
            kdVorschlag = [SELECT id, Name__c, Vorname__c, e_mail__c, Versichertennummer__c, 
                                            komb_Adresse__c, 
                                            Betreuer__c, 
                                            Pflegegrad__c,
                                            Pflegedienst__c, 
                                            Produktgruppe__c,
                                            (SELECT Produktgruppe__c, Status__c FROM Kundenstatus__r) st, 
                                            Geburtsdatum_text__c,
                                            Wunschbox__c,
                                            bevorzugter_Art_f_r_Einmalhandsch__c,
                                            lead__c
                                 FROM Kunde__c 
                                 WHERE Name__c =: l.lastname 
                                 AND Vorname__c =: l.firstname 
                                 ];             
        }
        if((kdVorschlag != null) && (kdVorschlag.size() > 0)) {
            for(Kunde__c KD : kdVorschlag) {
                if((KD.Produktgruppe__c == null) || (!KD.Produktgruppe__c.Contains('PG54'))) {
                    for(Kundenstatus__c KS : KD.Kundenstatus__r) {
                        if(KS.Produktgruppe__c.Contains('PG54')) {
                            if(KD.Produktgruppe__c == null) {
                                KD.Produktgruppe__c = 'PG54 ' + KS.Status__c; 
                            }
                            else KD.Produktgruppe__c = KD.Produktgruppe__c + ';PG54 ' + KS.Status__c;  
                        }
                    }
                }
                kdMapVorschlag.put(KD.id, KD);
            }
            
        }
        
        return kdVorschlag;
    }
    
    public list<Kunde__c> getKdVorschlag() {
        return kdVorschlag;
    }   
    
    public attachment checkAnhang() {
        list<attachment> attList = [SELECT id, name, parentid, ContentType FROM attachment WHERE parentid = : l.id];
        if((attList != null) && (attList.size() > 0)) {
        return attList[0];
        }
        else return null;
    }
    
    public attachment getAttach() {
        return attach;
    }
    
    public Kunde__c getpdkunde() {
        return pdkunde;
    }
    
    public void lesenPD() {
        pdVorschlag = [SELECT Id, Name, Kategorie__c, billingstreet, billingpostalcode, billingcity   
                        FROM Account 
                        WHERE Name LIKE : '%' + l.CB_Pflegedienst_Name__c +'%'
                        AND Kategorie__c = '01 Ambulante Pflegedienste'];
        
    }
    
    private void lesenAN() {
            //string query = 'SELECT Id, firstname, lastname, Email, mailingstreet, mailingpostalcode, mailingcity FROM contact WHERE lastname = \'' + l.Angehoeriger_Nachname__c + '\''
            //                + ' AND firstname = \'' + l.Angehoeriger_Vorname__c + '\'' 
            //                + ' AND Account.name = \'ASP für Kunden\'';
            //if(l.Angehoeriger_Email__c != null) query = query + ' AND Email = \'' +  l.Angehoeriger_Email__c + '\'';
            // if(l.Angehoeriger_Ort__c != null) query = query + ' AND MailingCity = \'' +  l.Angehoeriger_Ort__c + '\'';
            
            
            
            //system.debug ('##################################alex300 query=' + query);
            //anVorschlag = (List<contact>)Database.query(query);
            if(l.Angehoeriger_Email__c != null) {
                anVorschlag = [SELECT Id, firstname, lastname, Email, mailingstreet, mailingpostalcode, mailingcity 
                                FROM contact 
                                WHERE lastname = : l.Angehoeriger_Nachname__c
                                AND firstname = : l.Angehoeriger_Vorname__c
                                AND Account.name = 'ASP für Kunden'
                                AND Email = : l.Angehoeriger_Email__c];
            }
            else {
                anVorschlag = [SELECT Id, firstname, lastname, Email, mailingstreet, mailingpostalcode, mailingcity 
                                FROM contact 
                                WHERE lastname = : l.Angehoeriger_Nachname__c
                                AND firstname = : l.Angehoeriger_Vorname__c
                                AND Account.name = 'ASP für Kunden'];           
            }
            system.debug ('##################################alex301 ' + anVorschlag);
            
    }
    
    public void lesenFmAn(){
           list<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name = 'Familienangehörige' and sObjectType = 'Contact'];     
           
           if(rtList != null && rtList.size() != 0){        
                fmAnVorschlag = [select id, Name, firstname, lastname, Email, Phone, RecordTypeId, AccountId,  
                                       Familien_Zugeh_rigkeit__c, MailingStreet, MailingCity, MailingPostalCode, Account.name
                                       from Contact 
                                       where ((Email =: l.Email and Email != null) 
                                       or (firstname =: l.firstname and lastname =: l.lastname and firstname != null and lastname != null)) 
                                       and Account.name != 'ASP für Kunden'
                                       and RecordTypeId =: rtList[0].Id]; 
                
                if(fmAnVorschlag != null && fmAnVorschlag.size() != 0) hasFmAn = true;            
           }
           else {
               system.debug('#################BT2016: Kein Recordtype Familienangehörige/Standard wurde gefunden !');
           }
    }

    public list<contact> getFmAnVorschlag() {
        return fmAnVorschlag;
    } 

    public list<contact> getAnVorschlag() {
        return anVorschlag;
    } 
    
    public list<account> getPdVorschlag() {
        return pdVorschlag;
    }  

    public string getSelKD() {
        return selKD;
    }
    
    public string getSelFmAn() {
        return selFmAn;
    }    
    
    public string getSelAn() {
        return selAn;
    }
    
    public string getSelPd() {
        return selPd;
    }
        
    public integer getSeite() {
        return seite;
    }
    
    public integer getLastPage() {
        return lastPage;
    }
    
    public void makeHandschuheMap() {
        HandschuheMap.put('XS', 'Peha-soft Vinyl Einmalhandschuhe (Größe XS)');
        HandschuheMap.put('S', 'Peha-soft Vinyl Einmalhandschuhe (Größe S)');
        HandschuheMap.put('M', 'Peha-soft Vinyl Einmalhandschuhe (Größe M)');
        HandschuheMap.put('L', 'Peha-soft Vinyl Einmalhandschuhe (Größe L)');
        HandschuheMap.put('XL', 'Peha-soft Vinyl Einmalhandschuhe (Größe XL)');
    }

    public void createTask(id kdid) {
        system.debug ('##################################alex205 kdid=' + kdid);            
       
        id rtid = null;                                
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'PG54'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        } 
        Task th = new Task(ActivityDate = Date.today(),
                            Subject='Kunde wünscht CB-Formular ' + l.next_Step__c,
                            WhatId = kdId,
                            Description = 'Kunde wünscht CB-Formular ' + l.next_Step__c,
                            OwnerId = UserInfo.getUserId(),
                            RecordTypeId = rtid,
                            Status='Geschlossen');
        
        insert th;
    }
    
    public static void saveWithSatndardLeadConvert(Id leadId){
    
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setDoNotCreateOpportunity(true);
        
        Id dummyAccountId;
        Id dummyContactId; 
        List<Account> aList = [select id, name from Account where name = : DummyAccountName limit 1];
        if(alist != null && alist.size()>0){
            dummyAccountId = alist[0].id;
        }else{
            Account dummyAccount = new Account(name = DummyAccountName);
            insert dummyAccount;
            dummyAccountId = dummyAccount.Id;
        }
        List<Contact> cList = [select id from Contact where accountId = :dummyAccountId limit 1];
        if(clist != null && clist.size()>0){
            dummyContactId = clist[0].id;
        }else{
            Contact dummyContact = new Contact(lastname=DummyContactName, accountId= dummyAccountId);
            insert dummyContact;
            dummyContactId = dummyContact.Id;
        }
        lc.setAccountId(dummyAccountId);
        lc.setContactId(dummyContactId);
        
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Qualified' LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        // try-catch added to avoid sending exception email on CANNOT_UPDATE_CONVERTED_LEAD. error happens if user goes back to the previous page after clicking on save button. then click on save button again. error can be ignored.  
        try{
            Database.LeadConvertResult lcr = Database.convertLead(lc);
        }catch(System.DmlException e){
            System.debug('####KSG:::'+ e.getMessage());
        }
    }
      
    
    public static Boolean validateEmail(String email) {
        Boolean res = true;        
    
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; 
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);

        if (!MyMatcher.matches()) res = false;
        
        return res; 
    }     


    
        // wird nicht aufgerufen! Nur für Testabdeckung!!!  
        public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;}
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
              
        }
}