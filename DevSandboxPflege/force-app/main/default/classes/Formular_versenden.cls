//*****************************************************************************************************************************
// Erstellt xx.02.2015 von AM
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
// 11.03.2015 von AM: Einbau der Mailtexten aus Antragstext__c
//                        
//      
// 21.04.2015 von wds: Anrede bei Email geändert
// 22.04.2015 von AM:   Per eMail kein Anschreiben als Attachment versenden, nur mail-text. 
// 24.04.2015 von AM:   Prüfen ob Anschrift vorhanden   
// 05.08.2015 von AM: RemDateTime füe öffene tasks = heute + 3 Tage         
// 02.09.2015 von AM: Einbau recordtype für Task      
// 05.11.2015 von AM: Fehlerkorrektur - Beim Auswahl Empfänger 'Kunde' waren die Daten nicht übernommen    
// 18.02.2016 von AM:    #113991141 - knz hasAddress für Bereuer/Angehöriger war falsch gesetzt    
// 05.10.2016 von BT: Es wird keine "Nachtelefonie von Interessenten" mehr eingerichtet, wenn sowohl Kunde als auch Angehöriger 
//                                                                keine Telefonnummer hintergelegt haben.
// 02.11.2016 von BT: #133603095 Anlage der Nachtelefonie: Berücksichtigung der Mobilfunknummer
// 06.07.2018 von MS: #158424300/1576:
//                         - blanko per Mail (perEmail()) and vorausgefüllt per Mail (perEmailAssistent)
//                           are now HTML emails, using a custom html-email-template
//                         - vorausgefüllt per Mail now opens directly pdf attachment, therefore replaced
//                           var pdfPageName_Assistent by pdfAttachmentId_Assistent
// 26.10.2018 von MS: #160450239/1753:
//                         - blanko per Mail (perEmail()), fmType = eingangsbest edited, now also using custom html-email
//                              template, making a difference between gesetzlich and privat versichert
//****************************************************************************************************************************


public with sharing class Formular_versenden {
    
    public string fmType = ApexPages.currentPage().getParameters().get('fmType');
    public string retMsg = ApexPages.currentPage().getParameters().get('retMsg');
    public ID KdID = ApexPages.currentPage().getParameters().get('ID');
    public string mainPageName {get; set;}
    public string pageTitle {get; set;}
    public string beschreibung {get; set;}
    public string mainPageName_inko {get; set;}
    public string pageTitle_inko {get; set;}
    public string beschreibung_inko {get; set;}
    public string mailHinweis {get; set;}
    public string addrHinweis {get; set;}
    public ID rcpt {get; set;}
    public string mailTo {get; set;}
    public string subject {get; set;}
    public string subject_inko {get;set;}
    public boolean hasMail = false;
    public boolean hasAddr = false;
    public string empfaenger {get; set;}
    public string Anredeformel {get; set;}
    public string kunde {get; set;}
    public rcptAddr mailAdressen{get; set;}
    public List<SelectOption> selRCPT {get; set;}
    public string selectedRcpt = null;
    public string kdnr =  null;
    public Antragstext__c mText {get; set;}
    public string mainPageName_Assistent {get; set;}
    
    // ms 27.10.18
    public boolean gesetzlich = true;
    /**
     * pdfAttachmentId_Assistent
     * contains the ID of the attachment of Kunde__c
     * named "CB_Formular" which shall be opened, when "Vorausgefüllt per Post" is
     * clicked on VF-Page Formular_versenden
     **/
    public string pdfAttachmentId_Assistent {get;set;}
    public string pageTitle_Assistent {get; set;}
    public string beschreibung_Assistent {get; set;}
    public string subject_Assistent {get;set;}
    
    private boolean mailVorschau = false;
    private list<Attachment> att = new list<Attachment>();
    
    /*
    * mailHtmlValue
    * htmlValue of email Template for preview of email "vorausgefüllt per Email"
    * in VF-Page Formular_versenden:PageBlocksection "eMail Vorschau"
    */
    public String mailHtmlValue {get; set;}
    /*
    * mailSubject
    * Subject of email Template for preview of email "vorausgefüllt per Email"
    * in VF-Page Formular_versenden:PageBlocksection "eMail Vorschau"
    */
    public String mailSubject {get; set;} 

        public class empSatz {
            public string empType {get; set;}
            public string empName {get; set;}
            public string empMail {get;set;}
            public string empAnredeformel {get;set;}
            public id empRcpt {get; set;}
            public boolean empHasMail = false;
            public boolean empHasAddr = false;
        }
    
    public class rcptAddr {
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
        private boolean gesetzlich {get; set;} //ms 26.10.18
        public List<SelectOption> options = new List<SelectOption>();
        // constructor

        
        public map<string, empSatz> empMap = new map<string, empSatz>();
        
        
        public rcptAddr(ID KundeID) {
            this.KdID = KundeID;
            list<Kunde__c> kdList = [SELECT id, Name, Anrede__c, Vorname__c, Name__c, Telefon__c, 
                                            Pflegedienst__c, Betreuer__c, e_mail__c, kundennummer__c, Betreuer__r.Phone,
                                            Krankenkasse__r.Kanal_Unterpunkt__c
                                        FROM Kunde__c 
                                        WHERE id = :KdID LIMIT 1];
            kdnr = string.valueof(kdlist[0].kundennummer__c);
            kunde = (kdlist[0].Vorname__c + ' ' + kdlist[0].Name__c).trim();
            if((kdList != null) && (kdList.size() > 0)) {
                // ms 26.10.18, assuming that if Krankenkasse is not privat, it is gesetzlich
                if(kdList[0].Krankenkasse__r.Kanal_Unterpunkt__c == 'privat'){
                    this.gesetzlich = false;
                } else {
                    this.gesetzlich = true;
                }
                
                
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
                                        AND Art_der_Anschrift__c IN ('Betreuer', 'Angehöriger')
                                        LIMIT 1];

                        
                        mailTo = ktList[0].Email;
                        empSatz ES = new empSatz();
                        ES.empType = 'Angehöriger';
                        ES.empName = ktList[0].Name;
                        ES.empMail = ktList[0].Email;
                        ES.empRcpt = kdList[0].Betreuer__c;
                        if((ansch != null) && (ansch.size() > 0)) {
                            if((ansch[0].Stra_e__c == null) || (ansch[0].PLZ__c == null) || (ansch[0].Ort__c == null)) {
                                ES.empHasAddr = false ;
                            }                       
                            else ES.empHasAddr = true ;
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
                rcpt = KdID;
                list<Anschrift__c>  kdAnsch = [SELECT Stra_e__c, PLZ__c, Ort__c, Anrede__c
                                            FROM Anschrift__c 
                                            WHERE Kunde__c = :kdList[0].id 
                                            AND Art_der_Anschrift__c = 'Kundenadresse' LIMIT 1] ;
            
                
                mailTo = kdList[0].e_mail__c;
                empSatz ES = new empSatz();
                if((kdAnsch != null) && (kdAnsch.size() > 0)) { 
                    if((kdAnsch[0].Stra_e__c == null) || (kdAnsch[0].PLZ__c == null) || (kdAnsch[0].Ort__c == null)) {
                        ES.empHasAddr = false ;
                    }                       
                    else ES.empHasAddr = true ;     
                } 
                else ES.empHasAddr = false ;
                ES.empType = 'Kunde';
                ES.empName = kdList[0].Name;
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
        
            
            
        }

        public void fillTable(string sR) {
            empSatz es = empMap.get(sR);
            empfaenger = es.empType;
            system.debug('#########################alex622 selectedRcpt=' + sR + ' empfaenger=' + empfaenger + ' es=' + es);
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
        }
        
        public boolean hatFehler() {
            return error;
        }
        
        public boolean getHasMail() {
            return hasMail;
        }
        
        public boolean getGesetzlich() {
            return gesetzlich;
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
        
    }
    
    // constructor
    public Formular_versenden() {}
    
    public Formular_versenden(ApexPages.StandardController stdController) {   
        
        mailAdressen = new rcptAddr(KdID);
        gesetzlich = mailAdressen.getGesetzlich();// ms 26.10.18
        empfaenger = mailAdressen.getEmpfaenger();
        rcpt = mailAdressen.getRcpt();
        mailTo = mailAdressen.getMailTo();
        mailHinweis = mailAdressen.getMailHinweis();
        hasMail = mailAdressen.getHasMail();
        addrHinweis = mailAdressen.getAddrHinweis();
        hasAddr = mailAdressen.getHasAddr();
        kunde = mailAdressen.getKunde();
        Anredeformel = mailAdressen.getAnredeformel();
        selRCPT = mailAdressen.selectRcpt();
        selectedRCPT = mailAdressen.getselectedRcpt();
        kdnr=mailAdressen.kdnr;


        makeMainPageName();
    } 
    
    public void makeMainPageName() {
        if(fmType == 'formular') {
//
//  Settings für Formularversand PG54 u 51
//       

            mainPageName = 'Anschreiben_Formular_CB';
            pageTitle = 'Formular verschicken';
            beschreibung = 'Anschreiben für PG54 und PG51 ausdrucken';
            subject = 'Formular';
//
//  Settings für Formularversand Inko
//             
            mainPageName_Inko = 'Anschreiben_formular_inko_neu';
            pageTitle_Inko = 'Formular verschicken';
            beschreibung_Inko = 'Anschreiben für Inko ausdrucken';
            subject_inko = 'Formular';
            
//
//  Settings für Formularversand Assistent
//             
            mainPageName_Assistent = 'Anschreiben_CB_Assistent';


            pageTitle_Assistent = 'Formular verschicken';
            beschreibung_Assistent = 'Vorausgefüllt ausdrucken';
            subject_Assistent = 'Formular';  

            list<Attachment> atList = [select id, body, Name, ParentId from Attachment 
                                 where ParentId = :KdID 
                                and name like 'CB_Formular%'
                                 order by createdDate desc];
            if((atList != null) && (atList.size() > 0)) {
                Attachment attach = atList[0];
                pdfAttachmentId_Assistent = attach.Id;
                  
            }
        
            else {
                system.debug('######################### No attachment found for Kunde ::' );
            }
      
        }
        if(fmType == 'eingangsbest') {
            mainPageName = 'Curabox_Empfangsschreiben_CB';
            /*ms 27.10.18, no difference anymore between betreuer/kunde as rcpt
             * if(rcpt == KdID) {
                mainPageName = 'Curabox_Empfangsschreiben';
            }
            else {
                mainPageName = 'RA_nur_anzeigen_ent_Kd';
            }*/
            pageTitle = 'Eingangsbestätigung verschicken';
            beschreibung = 'Eingangsbestätigung ausdrucken';
            subject = 'Eingang Ihrer curabox Bestellung; Ihre Kundennummer CB14'+Kdnr;
        }
        mainPageName = '/apex/' + mainPageName + '?id=' + KdID + '&rcpt=' + rcpt; 
        mainPageName_inko = '/apex/' + mainPageName_inko + '?id=' + KdID + '&rcpt=' + rcpt; 
        mainPageName_Assistent =  '/apex/' + mainPageName_Assistent + '?id=' + KdID + '&rcpt=' + rcpt;     
    }

    public List<SelectOption> getselRCPT() {
            return selRCPT;
    }
    
    public PageReference perEmailAssistent() {  
            mailVorschau = true;
          /*  mText = [SELECT Betreff__c, RichText__c FROM Antragstext__c WHERE Textkey__c = 'Anschreiben_CB_Assistent_mail' LIMIT 1];               
            if(mText != null) {             
                mText.RichText__c = mText.RichText__c.replace('$anredeformel$', mailAdressen.getAnredeformel());     
            }*/
            EmailTemplate template;
            try {
                template = [SELECT Id, HtmlValue, Name, Subject, Body
                                         FROM EmailTemplate  WHERE Name = 'curabox_vorausgefuellt_per_email']; 
               
            
            } catch(Exception e) {
                system.debug('#########################ms error get template e=' + e);
            }
            
            mailHtmlValue = template.HtmlValue;
            mailHtmlValue = mailHtmlValue.replace('$anredeformel$', Anredeformel);
            
            mailSubject = template.Subject;
            
            att = [select id, Name, ContentType from Attachment 
                                 where ParentId = :KdID 
                                and name like 'CB_Formular%'
                                 order by createdDate desc];            
        return null;
    }
    
    public void startMail() {
        string plaintext = 'S. Anhang.\n ';
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        String[] toAddress = new String[] {mailTo};
        mail.setToAddresses(toAddress);
        mail.setSubject(mailSubject);
        transient Messaging.EmailFileAttachment [] pdfList = new List<Messaging.EmailFileAttachment> () ;
        Messaging.EmailFileAttachment spdfAttc = new Messaging.EmailFileAttachment();
        list<Attachment> atList = [select id, body, Name, ParentId from Attachment 
                             where Id = :id.valueOf(mAtID)];
        if((atList != null) && (atList.size() > 0)) {
            Attachment attach = atList[0];
            spdfAttc.setFileName(attach.Name);
            spdfAttc.setBody(attach.Body); 
        }   
        spdfAttc.setContentType('application/pdf');
        spdfAttc.setInline(false);
        pdfList.add(spdfAttc) ;     
        mail.setHtmlBody(mailHtmlValue); 
        mail.setSubject(mailSubject);  
        mail.setFileAttachments(pdfList); 
        mail.setPlainTextBody(plaintext);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });       
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Mail mit Anhang gesendet an ' + mailTo));
        }
        catch(System.Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Fehler beim Senden Mail')); 
        }
    }
    
    public void pageBack() {
        mailVorschau = false;
    }
    
    
 //   public PageReference sendVor() {
  //      return null;        
   // }
    
    public PageReference perEmail() {       
        string plaintext = 'S. Anhang.\n ';
        mainPageName += '&task=notask';
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        String[] toAddress = new String[] {mailTo};
        mail.setToAddresses(toAddress);
        mail.setSubject(subject);   
        transient Messaging.EmailFileAttachment [] pdfList = new List<Messaging.EmailFileAttachment> ();
        if(fmType == 'formular') {
            StaticResource sr = [
                                    SELECT Body
                                    FROM StaticResource
                                    WHERE Name = 'Antrag_Formular'
                                    LIMIT 1
                                ];
            Messaging.EmailFileAttachment spdfAttc = new Messaging.EmailFileAttachment();
            spdfAttc.setContentType('application/pdf');
            spdfAttc.setInline(false);
            spdfAttc.setFileName('Antrag_Formular.pdf');
            spdfAttc.setBody(sr.Body);
            pdfList.add(spdfAttc) ;  
            
            try {
                EmailTemplate template = [SELECT Id, HtmlValue, Name, Subject, Body
                                         FROM EmailTemplate  WHERE Name = 'curabox_blanko_per_email']; 
                String htmlValue = template.HtmlValue;
                htmlValue = htmlValue = htmlValue.replace('$anredeformel$', Anredeformel);
                
                plaintext = template.Body;
                plaintext = plaintext.replace('$anredeformel$', Anredeformel);
                
                mail.setHtmlBody(htmlValue);
                mail.setSubject(template.Subject);
            
            } catch(Exception e) {
                system.debug('#########################ms error get template e=' + e);
            }
            

            
  /*      
  5.7.18 ms change from Antragstext__c to custom email Template!    
            mText = [SELECT Betreff__c, RichText__c FROM Antragstext__c WHERE Textkey__c = 'Anschreiben_formular' LIMIT 1];               
            if(mText != null) {
                mText.RichText__c = mText.RichText__c.replace('$anredeformel$', Anredeformel);     
                mail.setHtmlBody( mText.RichText__c); 
                mail.setSubject(mText.Betreff__c); 
            }    */            
        }
         if(fmType == 'eingangsbest') {
             String emailTemplateName = 'curabox_empfangsschreiben_gesetzlich';
             if(gesetzlich == false){
                 emailTemplateName = 'curabox_empfangsschreiben_privat';
             }
            try {
                EmailTemplate template = [SELECT Id, HtmlValue, Name, Subject, Body
                                         FROM EmailTemplate  WHERE Name = :emailTemplateName]; 
                String htmlValue = template.HtmlValue;
                htmlValue = htmlValue = htmlValue.replace('$anredeformel$', Anredeformel);
                
                plaintext = template.Body;
                plaintext = plaintext.replace('$anredeformel$', Anredeformel);
                
                mail.setHtmlBody(htmlValue);
                mail.setSubject(template.Subject);
            
            } catch(Exception e) {
                system.debug('#########################ms error get template e=' + e);
            }             
             
             /*
              * 26.10.18 ms change from Antragstext__c to custom emailTemplate as well... (see above)
              * no distinction made anymore between sending email to betreuer or kunde, but making difference between
              * gesetzlich and privat versicherte
              * 
            if(rcpt == KdID) {
                mText = [SELECT Betreff__c, RichText__c FROM Antragstext__c WHERE Textkey__c = 'Eingang_kunde' LIMIT 1];       
            }
            else {
                mText = [SELECT Betreff__c, RichText__c FROM Antragstext__c WHERE Textkey__c = 'Eingang_andere' LIMIT 1];       
            }
            if(mText != null) {
                mText.RichText__c = mText.RichText__c.replace('$anredeformel$', Anredeformel);   
                date datum = date.today();
                string eingangsdatum = datum.format();
                mText.RichText__c = mText.RichText__c.replace('$eingangsdatum$', eingangsdatum);  
                mText.RichText__c = mText.RichText__c.replace('$kunde$', kunde);                
                mail.setHtmlBody( mText.RichText__c); 
                mail.setSubject(mText.Betreff__c); 
            } */
         }          
        
        // Blob pdf;
        // PageReference fmPDF = new PageReference(mainPageName);
        try {
            // pdf = fmPDF.getContent();
            // Messaging.EmailFileAttachment pdfAttc = new Messaging.EmailFileAttachment();
            // pdfAttc.setContentType('application/pdf');
            // pdfAttc.setInline(false);
            // pdfAttc.setFileName(subject + '.pdf');
            // pdfAttc.setBody(pdf);
            // pdfList.add(pdfAttc) ;
            
            // ms 26.10.18 small improvement since already working here
            String apexPageMessage = 'Mail gesendet an ';
            if(!pdfList.isEmpty()){
                mail.setFileAttachments(pdfList);
                apexPageMessage = 'Mail mit PDF-Anhang gesendet an ';
            }
            mail.setPlainTextBody(plaintext);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, apexPageMessage + mailTo));
            addTask(subject +' per Email versandt', subject +' per Email versandt an ' +empfaenger + ' (' +  mailTo + ')' );
        }
        catch (VisualforceException e) {
            system.debug('#########################alex200 Error getContent e=' + e);
        }   
        PageReference curPage = new PageReference(ApexPages.currentPage().getUrl());
        curPage.setRedirect(true);
        return null;        

        
        
    }
    
    public PageReference perEmailInko() {       
        
        mainPageName += '&task=notask';
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        String[] toAddress = new String[] {mailTo};
        mail.setToAddresses(toAddress);
        mail.setSubject(subject);   
        transient Messaging.EmailFileAttachment [] pdfList = new List<Messaging.EmailFileAttachment> () ;
        if(fmType == 'formular') {
             
            
            mText = [SELECT Betreff__c, RichText__c FROM Antragstext__c WHERE Textkey__c = 'Anschreiben_formular_inko' LIMIT 1];               
            if(mText != null) {
                mText.RichText__c = mText.RichText__c.replace('$anredeformel$', Anredeformel);     
                mail.setHtmlBody( mText.RichText__c); 
                mail.setSubject(mText.Betreff__c); 
            }                
        }
         if(fmType == 'eingangsbest') {
            if(rcpt == KdID) {
                mText = [SELECT Betreff__c, RichText__c FROM Antragstext__c WHERE Textkey__c = 'Eingang_kunde' LIMIT 1];       
            }
            else {
                mText = [SELECT Betreff__c, RichText__c FROM Antragstext__c WHERE Textkey__c = 'Eingang_andere' LIMIT 1];       
            }
            if(mText != null) {
                mText.RichText__c = mText.RichText__c.replace('$anredeformel$', Anredeformel);   
                date datum = date.today();
                string eingangsdatum = datum.format();
                mText.RichText__c = mText.RichText__c.replace('$eingangsdatum$', eingangsdatum);  
                mText.RichText__c = mText.RichText__c.replace('$kunde$', kunde);                
                mail.setHtmlBody( mText.RichText__c); 
                mail.setSubject(mText.Betreff__c); 
            } 
         }          
        
        // Blob pdf;
        // PageReference fmPDF = new PageReference(mainPageName);
        try {
            // pdf = fmPDF.getContent();
            // Messaging.EmailFileAttachment pdfAttc = new Messaging.EmailFileAttachment();
            // pdfAttc.setContentType('application/pdf');
            // pdfAttc.setInline(false);
            // pdfAttc.setFileName(subject + '.pdf');
            // pdfAttc.setBody(pdf);
            // pdfList.add(pdfAttc) ;
//            mail.setFileAttachments(pdfList); 
//            mail.setPlainTextBody(plaintext);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Mail mit PDF-Anhang gesendet an ' + mailTo));
            addTask(subject +' per Email versandt', subject +' per Email versandt an ' +empfaenger + ' (' +  mailTo + ')' );
        }
        catch (VisualforceException e) {
            system.debug('#########################alex200 Error getContent e=' + e);
        }   
        PageReference curPage = new PageReference(ApexPages.currentPage().getUrl());
        curPage.setRedirect(true);
        return null;        

        
        
    }      

    public PageReference zurueck() {       
        PageReference returnPage = new PageReference('/' + KdID);
        returnPage.setRedirect(true);
        return returnPage;
    }   

    public string getPageTitle() {
        return pageTitle;
    }
    
    public string getBeschreibung() {
        return beschreibung;
    }

    public string getBeschreibung_Assistent() {
        return beschreibung_Assistent;
    }
        
    public string getEmpfaenger() {
        return empfaenger;
    }
    
    public string getMailHinweis() {
        return mailHinweis;
    }
    
    public string getAddrHinweis() {
        return addrHinweis;
    }
    
    public string getMainPageName() {
        return MainPageName;
    }

    public string getFmType() {
        return fmType;
    }
        
    public string getMainPageName_inko() {
        return MainPageName;
    }

    public string getMainPageName_Assistent() {
        return MainPageName_Assistent;
    }
    
    public boolean getHasMail() {
        return hasMail;
    }
    
    public boolean getHasAddr() {
        return hasAddr;
    }
    
    public rcptAddr getMailAdressen() {
        return mailAdressen;
    }
 
    public string getSelectedRcpt() {
        return selectedRcpt;
    }

    public void setSelectedRcpt(string selectedRcpt) {
            this.selectedRcpt = selectedRcpt;
    }
    
    public void changeRcpt() {
        system.debug('#########################alex700 setSelectedRcpt=' + SelectedRcpt);
        //mailAdressen.setSelectedRcpt(this.selectedRcpt);  
        mailAdressen.fillTable(selectedRcpt);
        empfaenger = mailAdressen.getEmpfaenger();
        rcpt = mailAdressen.getRcpt();
        mailTo = mailAdressen.getMailTo();
        mailHinweis = mailAdressen.getMailHinweis();
        hasMail = mailAdressen.getHasMail();
        hasAddr = mailAdressen.getHasAddr();
        addrHinweis = mailAdressen.getAddrHinweis();
        makeMainPageName();
        system.debug('#########################alex710 empfaenger=' + empfaenger);
    }
    
    public void addTask(string subject, string descr){
            system.debug('#########################alex210 subject=' + subject);
            id rtid = null;                                
            list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'PG54'];
            if((rtList != null) && (rtList.size() > 0)) {
                rtId = rtList[0].id;
            } 
            
            task newTask = new Task(ActivityDate = Date.today(),
                                    Description =  descr,
                                    Priority = 'Normal',
                                    Status = 'Geschlossen',
                                    Subject = subject,            
                                    WhatId = KdID,
                                    RecordTypeId = rtid,
                                    IsReminderSet = false
                                       );
             // Insert the new Task
             insert newTask;
             List<Kunde__c> kdList = [SELECT id, Betreuer__c, Betreuer__r.Phone, Telefon__c, Mobil__c, Betreuer__r.mobilephone 
                                      FROM Kunde__c 
                                      WHERE id =: KdID 
                                      LIMIT 1];
             
             if(kdList[0].Telefon__c != null || kdList[0].Mobil__c != null || kdList[0].Betreuer__r.Phone != null || kdList[0].Betreuer__r.mobilephone != null){
                if(subject.contains('Formular')) { 
                id grID = UserInfo.getUserId(); 
                list<Group> grList = [SELECT id FROM Group WHERE Name = 'Nachtelefonie' LIMIT 1];
                if((grList != null) && (grList.size() > 0)) {   
                    grID = grList[0].id;
                }
                list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                                FROM GroupMember WHERE GroupId = : grID];
                list<task> tsList = new list<task>();
                if((gmList != null) && (gmList.size() > 0)) { 
                    for(GroupMember GM : gmList) {
                        Task t = new Task(ActivityDate = Date.today().addDays(3),
                                            Subject='Nachtelefonie von Interessenten',
                                            WhatId = KdID,
                                            OwnerId = GM.UserOrGroupId,
                                            IsReminderSet = true,
                                            ReminderDateTime = System.now()+3,                                     
                                            Description = 'Nachtelefonie von Interessenten',   
                                            RecordTypeId = rtid,
                                            Status='Open');
                        tsList.add(t);
                    }
                }
                else {
                
                        Task t = new Task(ActivityDate = Date.today().addDays(3),
                                            Subject='Nachtelefonie von Interessenten',
                                            WhatId = KdID,
                                            OwnerId = UserInfo.getUserId(),
                                            IsReminderSet = true,
                                            ReminderDateTime = System.now()+3,                                     
                                            Description = 'Nachtelefonie von Interessenten',   
                                            RecordTypeId = rtid,
                                            Status='Open');
                        tsList.add(t);                  
                }
                insert tsList;       
             }  
           }            
        }

    public boolean getMailVorschau() {
        return mailVorschau;
    }

    public Antragstext__c getmText() 
    {
        return mText;
    }
     
    public string getsubject_Assistent() {
        return subject_Assistent;
    }
    
    public list<Attachment> getatt() {
        return att;
    }

    public string mAtID {
        get;
        set {
            mAtID = value;
        }
        
    }
    
    public boolean eingBest {
        get {
            if(fmType == 'eingangsbest') {
                return true;
            }
            else return false;
        } 
        set ;
    }
    
  }