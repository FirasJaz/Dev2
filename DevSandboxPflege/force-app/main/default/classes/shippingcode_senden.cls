/****************************************************************************************************************************
// Erstellt 04.09.2015 von AM, GL
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
//
//****************************************************************************************************************************
//
// Beschreibung:
// Suchen nach shipping code (statusMsgId__c) und senden email an kunde
//
//****************************************************************************************************************************
//Änderungen:
//16.11.2015 von BT  #108204330 Das Feld "mail_an_kunde gesendet_am" wird immer upgedatet unabhängig davon, 
//                              ob die Mail richtig gesendet wurde oder nicht.
//17.11.2015 von AM  #108204330 senden nur an Lieferanschrift__c aber updaten alle
//02.12.2015 von WDS #109346676 Adresse From fehlerhaft, die shop-Adresse auslesen!
//****************************************************************************************************************************
*/

global with sharing class shippingcode_senden {
    
    private string templateMail2 = '\n\n\nTesten Sie die Produkte in aller Ruhe und überzeugen Sie sich von Qualität und Komfort!\n\n\nWir sind immer für Sie da!\nIhr pflege.de-Team';
    private string templateMail1 = '\n\nwir freuen uns Ihnen mitzuteilen, dass Ihre kostenfreie Gratisprobe für\nInkontinenzmaterialien bereits auf dem Weg zu Ihnen ist.\nUnter folgendem Link können Sie genau verfolgen, wo sich Ihre individuellen \n';
    private Antragstext__c mText {get; set;}
    private Antragstext__c mkText {get; set;}
    private string templateBody {get; set;}
    private string currentBody {get; set;}
    
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
    
    public class kdmail {
        public string toAddr {get; set;}
        public string subject {get; set;}
        public string body {get; set;}
        public id kdid {get; set;}
    }
    
    public list<kdmail> maillist = new list<kdmail>();
    
    public shippingcode_senden() {
        map<id, Lieferbest_tigung__c> kdLbMap = new map<id, Lieferbest_tigung__c>();
        map<id, Lieferbest_tigung__c> lbMap = new map<id, Lieferbest_tigung__c>();
        map<id, string> emMap = new map<id, string>();
        set<string> addrSet = new set<string>();
        list<Lieferbest_tigung__c> lbList = [SELECT statusMsgId__c, Kunde__c, 
                                                    Kunde__r.e_mail__c,
                                                    Kunde__r.Anrede__c,
                                                    Kunde__r.Name__c,
                                                    Kunde__r.Vorname__c,
                                                    mail_an_kunde_gesendet_am__c,
                                                    Lieferschein__r.Lieferanschrift__r.e_mail__c,
                                                    Lieferschein__r.Lieferadresse__c,
                                                    Lieferschein__r.Lieferschein_text__c, 
                                                    Lieferschein__r.Liefertext__c
                                                FROM Lieferbest_tigung__c
                                                WHERE statusMsgId__c != null
                                                AND mail_an_kunde_gesendet_am__c = null
                                                AND Rechnung__c = null
                                                AND ((Lieferschein__r.Liefertext__c = 'Muster-Artikel') 
                                                OR (Lieferschein__r.Lieferschein_text__c = 'Inko'))
                                                ];
                                                
        list<Lieferbest_tigung__c> shoplbList = [SELECT statusMsgId__c, Kunde__c, 
                                                    Kunde__r.e_mail__c,
                                                    Kunde__r.Anrede__c,
                                                    Kunde__r.Name__c,
                                                    Kunde__r.Vorname__c,
                                                    Kunde__r.Stra_e__c,
                                                    Kunde__r.PLZ__c,
                                                    Kunde__r.Ort__c,
                                                    mail_an_kunde_gesendet_am__c,
                                                    Lieferschein__r.Lieferanschrift__r.e_mail__c,
                                                    Lieferschein__r.Lieferadresse__c,
                                                    Lieferschein__r.Lieferschein_text__c, 
                                                    Lieferschein__r.Liefertext__c
                                                FROM Lieferbest_tigung__c
                                                WHERE statusMsgId__c != null
                                                AND mail_an_kunde_gesendet_am__c = null
                                                AND Rechnung__c = null
                                                AND ((Lieferschein__r.Liefertext__c = 'Shop') 
                                                OR (Lieferschein__r.Lieferschein_text__c = 'Shop'))
                                                ];                                                
        
        if((lbList != null) && (lbList.size() > 0)) {
            list<Antragstext__c> mtList = [SELECT Betreff__c, RichText__c 
                                            FROM Antragstext__c 
                                            WHERE Textkey__c = 'DHL shipping code'
                                            AND Texttyp__c = 'Inko'
                                            LIMIT 1];   
            if((mtList != null) && (mtList.size() == 1)){
                mkText = mtList[0];
                templateBody = mtList[0].RichText__c;
                system.debug('#########################alex001 mkText=' + mkText);
            }
            
            // richtige adresse ermitteln
            for(Lieferbest_tigung__c LB : lbList) {
                lbMap.put(LB.id, LB);   
                addrSet.add(LB.Lieferschein__r.Lieferadresse__c);
            }
            
            list<Anschrift__c> addrList = [SELECT Kunde__c, e_mail__c, Kundenadresse__c 
                                            FROM Anschrift__c 
                                            WHERE komb_Adresse__c IN : addrSet];
            if((addrList != null) && (addrList.size() > 0)) {
                for(Anschrift__c AN : addrList) {
                    if((!AN.Kundenadresse__c) && (AN.e_mail__c != null)) emMap.put(AN.Kunde__c, AN.e_mail__c);
                }
            }
                                            
            for(Lieferbest_tigung__c LB : lbList) {
                mText = mkText;
                currentBody = templateBody;
                system.debug('#########################alex002 mText=' + mText);
                kdLbMap.put(LB.Kunde__c, LB);
                kdmail mailZeile = new kdmail();
                LB.mail_an_kunde_gesendet_am__c = date.today();
                string Anredeformel = 'Sehr geehrte Damen und Herren, ';
                
                // if(emMap.containsKey(LB.Kunde__c)) {
                
                    // mailZeile.toAddr = emMap.get(LB.Kunde__c);
                if(LB.Lieferschein__r.Lieferanschrift__r.e_mail__c != null) {
                    mailZeile.toAddr = LB.Lieferschein__r.Lieferanschrift__r.e_mail__c;
                }
                else {
                    if (LB.Kunde__r.Anrede__c != null) {
                        if (LB.Kunde__r.Anrede__c.contains('Herr') ) {                 
                                Anredeformel = 'Sehr geehrter ' +(LB.Kunde__r.Anrede__c + ' ' + LB.Kunde__r.Name__c).trim() +',';                                                 
                        }
                        if (LB.Kunde__r.Anrede__c.contains('Frau') ) { 
                                Anredeformel = 'Sehr geehrte ' +(LB.Kunde__r.Anrede__c + ' ' + LB.Kunde__r.Name__c).trim() +',';                                                   
                        }         
                    }  
                    mailZeile.toAddr = LB.Kunde__r.e_mail__c;
                }
                
                string dhlurl = 'https://nolp.dhl.de/nextt-online-public/set_identcodes.do?idc=' + LB.statusMsgId__c;
                dhlurl = '<a href="' + dhlurl + '">' + LB.statusMsgId__c + '</a>';
                
                
                
                
                if(currentBody == null) {
                    mailZeile.body = Anredeformel + templateMail1 + dhlurl + templateMail2;
                    mailZeile.subject = 'Ihre kostenfreie Gratisprobe für Inkontinenzmaterialien ist bereits auf dem Weg zu Ihnen';
                }
                else {
                    if(Anredeformel != null) {
                        currentBody = currentBody.replace('$anredeformel$', Anredeformel);
                    }
                    else {
                        currentBody = currentBody.replace('$anredeformel$', '');
                    }
                    if(dhlurl != null) {
                        currentBody = currentBody.replace('$dhlurl$', dhlurl);
                    }
                    else {
                        currentBody = currentBody.replace('$dhlurl$', '');
                    }
                    system.debug('#########################alex003 currentBody=' + currentBody);
                    mailZeile.body = currentBody;
                    mailZeile.subject = mText.Betreff__c; 
                }
                mailZeile.kdid = LB.Kunde__c;
                if(mailZeile.toAddr != null) {
                    maillist.add(mailZeile);
                    system.debug('#########################alex200 '  + mailZeile);
                }
            }
            if(!maillist.isEmpty()) {
                boolean error = false;
                List<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress
                                                        where DisplayName =  'Pflege.de Kundenservice'];
                                                        system.debug('#########################alex201 '  + owa);
                Messaging.SingleEmailMessage[] mlist = new Messaging.SingleEmailMessage[]{};
                for(kdmail kdm : maillist) {
                
                    Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                    //OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress limit 1];
                    
                    
// set it in meassage as

                    mail.setOrgWideEmailAddressId(owa[0].id);
                    system.debug('#########################alex200 owa[0].id'  + owa[0].id);
                    system.debug('#########################alex200 kdm.toAddr'  + kdm.toAddr);
                    String[] toAddress = new String[] {kdm.toAddr};
                    // String[] toAddress = new String[] {'kontakt@klosesrockepartner.de'};
                    mail.setToAddresses(toAddress);
                    mail.setSubject(kdm.Subject);
                    mail.setHtmlBody(kdm.body);
                    mail.setPlainTextBody(kdm.body.replaceAll('<[^>]+>',' '));
                    mlist.add(mail);
                }
                system.debug('######################### mlist.size()='  + mlist.size());
                if(!mlist.isEmpty()) {
                    try {
                        Messaging.sendEmail(mlist);
                    }
                    catch (System.Exception e) {
                        error = true;
                        system.debug('#########################email####### error '  + e);
                    }                   
                }
                //if(!error) {
                    // list<Lieferbest_tigung__c> lbToUpd = new list<Lieferbest_tigung__c>();
                    // for(kdmail kdm : maillist) {
                        // Lieferbest_tigung__c LB = kdLbMap.get(kdm.kdid);
                        // LB.mail_an_kunde_gesendet_am__c = date.today();
                        // lbToUpd.add(LB);
                    // }
                    // if(!lbToUpd.isEmpty()) {
                        // try {
                            // update lbToUpd;
                        // }
                        // catch (System.Exception e) {
                            // system.debug('################################ error update lbToUpd: '  + e);
                        // }
                        
                    // }
                //}
            }
            try {
                update lbList;
            }
            catch (System.Exception e) {
                system.debug('################################ error update lbList: '  + e);
            }           
            
        }    
        
        
        if((shoplbList != null) && (shoplbList.size() > 0)) {
            mkText = null;
            mText = null;
            currentBody = null;
            templateBody = null;
            
            maillist.clear();
            kdLbMap.clear();
            lbMap.clear();
            emMap.clear();
            addrSet.clear();
            
            list<Antragstext__c> mtList = [SELECT Betreff__c, RichText__c 
                                            FROM Antragstext__c 
                                            WHERE Textkey__c = 'DHL Shipping Code - SHOP'
                                            LIMIT 1];   
            if((mtList != null) && (mtList.size() == 1)){
                mkText = mtList[0];
                templateBody = mtList[0].RichText__c;
                system.debug('#########################alex001 mkText=' + mkText);
            }
            
            // richtige adresse ermitteln
            for(Lieferbest_tigung__c LB : shoplbList) {
                lbMap.put(LB.id, LB);   
                addrSet.add(LB.Lieferschein__r.Lieferadresse__c);
            }
            
            list<Anschrift__c> addrList = [SELECT Kunde__c, e_mail__c, Kundenadresse__c 
                                            FROM Anschrift__c 
                                            WHERE komb_Adresse__c IN : addrSet];
            if((addrList != null) && (addrList.size() > 0)) {
                for(Anschrift__c AN : addrList) {
                    if((!AN.Kundenadresse__c) && (AN.e_mail__c != null)) emMap.put(AN.Kunde__c, AN.e_mail__c);
                }
            }
                                            
            for(Lieferbest_tigung__c LB : shoplbList) {
                mText = mkText;
                currentBody = templateBody;
                system.debug('#########################alex002 mText=' + mText);
                kdLbMap.put(LB.Kunde__c, LB);
                LB.mail_an_kunde_gesendet_am__c = date.today();
                kdmail mailZeile = new kdmail();
                string Anredeformel = 'Sehr geehrte Damen und Herren, ';
                // if(emMap.containsKey(LB.Kunde__c)) {
                    // mailZeile.toAddr = emMap.get(LB.Kunde__c);
                // }
                if(LB.Lieferschein__r.Lieferanschrift__r.e_mail__c != null) {
                    mailZeile.toAddr = LB.Lieferschein__r.Lieferanschrift__r.e_mail__c;
                }
                else {
                    if (LB.Kunde__r.Anrede__c != null) {
                        if (LB.Kunde__r.Anrede__c.contains('Herr') ) {                 
                                Anredeformel = 'Sehr geehrter ' +(LB.Kunde__r.Anrede__c + ' ' + LB.Kunde__r.Name__c).trim() +',';                                                 
                        }
                        if (LB.Kunde__r.Anrede__c.contains('Frau') ) { 
                                Anredeformel = 'Sehr geehrte ' +(LB.Kunde__r.Anrede__c + ' ' + LB.Kunde__r.Name__c).trim() +',';                                                   
                        }         
                    }  
                    mailZeile.toAddr = LB.Kunde__r.e_mail__c;
                }
                string dhlurl = 'https://nolp.dhl.de/nextt-online-public/set_identcodes.do?idc=' + LB.statusMsgId__c;
                dhlurl = '<a href="' + dhlurl + '">' + LB.statusMsgId__c + '</a>';
                
                
                
                
                if(currentBody != null) {
                    if(Anredeformel != null) {
                        currentBody = currentBody.replace('$anredeformel$', Anredeformel);
                    }
                    else {
                        currentBody = currentBody.replace('$anredeformel$', '');
                    }
                    if(dhlurl != null) {
                        currentBody = currentBody.replace('$dhlurl$', dhlurl);
                    }
                    else {
                        currentBody = currentBody.replace('$dhlurl$', '');
                    }
                    if(LB.Kunde__r.Anrede__c != null) {
                        currentBody = currentBody.replace('Anrede', LB.Kunde__r.Anrede__c);
                    }
                    else {
                        currentBody = currentBody.replace('Anrede', '');
                    }
                    if(LB.Kunde__r.Vorname__c != null) {
                        currentBody = currentBody.replace('Vorname', LB.Kunde__r.Vorname__c);
                    }
                    else {
                        currentBody = currentBody.replace('Vorname', '');
                    }
                    if(LB.Kunde__r.Name__c != null) {
                        currentBody = currentBody.replace('Name', LB.Kunde__r.Name__c);
                    }
                    else {
                        currentBody = currentBody.replace('Name', '');
                    }
                    if(LB.Kunde__r.Stra_e__c != null) {
                        currentBody = currentBody.replace('Straße', LB.Kunde__r.Stra_e__c);
                    }
                    else {
                        currentBody = currentBody.replace('Straße', '');
                    }
                    if(LB.Kunde__r.PLZ__c != null) {
                        currentBody = currentBody.replace('PLZ', string.valueOf(LB.Kunde__r.PLZ__c));
                    }
                    else {
                        currentBody = currentBody.replace('PLZ', '');
                    }
                    if(LB.Kunde__r.Ort__c != null) {
                        currentBody = currentBody.replace('Ort', LB.Kunde__r.Ort__c);
                    }
                    else {
                        currentBody = currentBody.replace('Ort', '');
                    }
                    system.debug('#########################alex003 currentBody=' + currentBody);
                    mailZeile.body = currentBody;
                    mailZeile.subject = mText.Betreff__c; 
                }
                mailZeile.kdid = LB.Kunde__c;
                if(mailZeile.toAddr != null) {
                    maillist.add(mailZeile);
                    system.debug('#########################alex200 '  + mailZeile);
                }
            }
            if(!maillist.isEmpty()) {
                List<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress limit 1];
                boolean error = false;
                Messaging.SingleEmailMessage[] mlist = new Messaging.SingleEmailMessage[]{};
                for(kdmail kdm : maillist) {
                
                    Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                    // List<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress limit 1];

// set it in meassage as

                    mail.setOrgWideEmailAddressId(owa[0].id);
                    
                    String[] toAddress = new String[] {kdm.toAddr};
                    // String[] toAddress = new String[] {'kontakt@klosesrockepartner.de'};
                    mail.setToAddresses(toAddress);
                    mail.setSubject(kdm.Subject);
                    mail.setHtmlBody(kdm.body);
                    mail.setPlainTextBody(kdm.body.replaceAll('<[^>]+>',' '));
                    mlist.add(mail);
                }
                system.debug('######################### mlist.size()='  + mlist.size());
                if(!mlist.isEmpty()) {
                    try {
                        Messaging.sendEmail(mlist);
                    }
                    catch (System.Exception e) {
                        error = true;
                        system.debug('#########################email####### error '  + e);
                    }                   
                }
                //if(!error) {
                    // list<Lieferbest_tigung__c> lbToUpd = new list<Lieferbest_tigung__c>();
                    // for(kdmail kdm : maillist) {
                        // Lieferbest_tigung__c LB = kdLbMap.get(kdm.kdid);
                        // LB.mail_an_kunde_gesendet_am__c = date.today();
                        // lbToUpd.add(LB);
                    // }
                    // if(!lbToUpd.isEmpty()) {
                        // try {
                            // update lbToUpd;
                        // }
                        // catch (System.Exception e) {
                            // system.debug('################################ error update lbToUpd: '  + e);
                        // }
                        
                    // }
                //}
            }
            
            try {
                update shoplbList;
            }
            catch (System.Exception e) {
                system.debug('################################ error update shoplbList: '  + e);
            }               
        }    
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