/*/****************************************************************************************************************************
// Erstellt 15.06.2014 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                             22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.:  04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// ID = Kunde__c.id
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//
//
//****************************************************************************************************************************
//Änderungen:
// AM 23.06.2014 Buttons "Fax" und "Mail" abhägig von Krankenkasse__r.bermittlung__c
// WDS 05.08.2014    Geburtsdatum mit andrucken
//
//
// 01.10.2014 von AM: es darf nur eins button (Fax, Mail oder PDF) angezeigt werden
//                           ausgeliefert mit Patch: x.v.zz
//
// 13.11.2014 von AM: Weg. reminder fax/mail - Feld ReminderDateTime (Heute + 14 Tage) und weitere Felder füllen.
//                           ausgeliefert mit Patch: x.v.zz
// 06.03.2015 von wds: Änderung der Versendung auf die Abrechnungsfirma, die in den customsttings hinterlegt ist.
//
// 22.04.2015 von AM Erzeugen tas für dir Grupp 'Nachtelefonie PK'
//
// 03.07.2015 von AM weiterleitung nach dem Mailversand -> wenn 51/54 erkannt dann Genehmigung anlegen und zu Kunde,
//                  wenn nicht erkannt -> neue Genehmigung 
//
// 17.07.2015 von AM  Aktivieren pg51/54
// 10.08.2015 von wds Krankenkasse soll mit in das Formular gesetzt werden (Antragstext)
// 12.08.2015 von AM s.o. aber nur wenn KK-Name != null
// 02.09.2015 von AM : Einbau recordtype für task
// 29.01.2016 von BT Das Feld 'Geburtsdatum__c' wird durch das Feld 'Geburtsdatum_text__c' erstetzt
// 14.12.2016 von BT Nach dem Hochladen des Antragsformulars werden Kundenstatus aktualisiert
// 28.12.2016 von BT Kundenstatus wird auf 'Vorgang geschlossen' gesetzt nur wenn er auf 'Interessent' war.
// 29.08.2017 von BT Fälligkeitsdatum der Aktivität "Nachfassen bei PK wg. offener KÜ" wird im custom setting eingestellt.
//****************************************************************************************************************************
*/

global with sharing class sendenFaxAusKunde {
    public string retPage = ApexPages.currentPage().getParameters().get('retURL');
    public ID KdID = null; 
    public Kunde__c KD {get; set;}
    public Kunde__c Abrechnungsfirma;
    public string kdMail = null;
    public string kdFax = null;
    public string kdSubject = 'Antrag auf Kostenübernahme, § 78 Abs.1 SGB XI i. V. m. § 40 Abs. 2 SGB XI';
    public string kdText = 'Bewilligungsantrag';
    public string kdName = null;
    public string kdVersNr = null;
    public string kdGeburtsdatum = null;
    public string kkName = null;
    public string kdBody = null;
    public string apName = null;
    public string kdBody2 = null;
    public ID ktID = null;
    public KundeKontakt__c KDKont {get; set;}
    public Antragstext__c mText {get; set;}
    public Antragstext__c mBText = new Antragstext__c();
    public string artikelGruppe {get; set;}
    
    public boolean buttonFaxVisible = false;
    public boolean buttonMailVisible = true;
    public boolean buttonPdfVisible = true;
    public string seitenTitel = null;
    public string tMail = null;
    public string atID = null;
    
    public string nachParagraf = null;
    
    // public string mAtID = null;
    // public string fAtID = null;
    public List<Attachment> att{get;set;}
    public transient Attachment AT {get;set;}
    public String kdKontakt = null;
    
    public asMail__c asMail {get; set;}
    
    public List<Kundenstatus__c> KSlist = new List<Kundenstatus__c>();
    
    public sendenFaxAusKunde(ApexPages.StandardController stdController) {      
        KdID = ApexPages.currentPage().getParameters().get('ID');

        seteInitialisieren();

    }
    
    public sendenFaxAusKunde() {
    }
    
    public void seteInitialisieren() {
        KD = [SELECT e_mail__c, Fax__c, Name, Krankenkasse__r.Name, Krankenkasse__c, Versichertennummer__c,
                Krankenkasse__r.bermittlung__c,
                Krankenkasse__r.Fax, Krankenkasse__r.Weitere_E_Mail__c,
                Ansprechpartner_Kasse__r.Fax, Ansprechpartner_Kasse__r.Email, 
                Ansprechpartner_Kasse__r.Name,
                Kontakt_Krankenkasse_51__r.Fax, Kontakt_Krankenkasse_51__r.Email,
                Kontakt_Krankenkasse_51__r.Name,
                Geburtsdatum_text__c
                FROM Kunde__c
                WHERE id = :KdID];
                
//*** ab hier wird der Abrechner gelesen
        system.debug('#########################alex001');
        // Abrechnungsfirma = [SELECT
                                            // Name, e_mail__c
                                    // FROM
                                            // Kunde__c
                                    // WHERE
                                            // Name = :AB_KK__c.getInstance('AB_KK_Einstellungen').Abrechnungsfirma__c];       
//*** Belegung der Asugabe mit der Email Adresse des Abrechners
        

 //       kdMail = Abrechnungsfirma.e_mail__c;
        kdName = KD.Name;
        kkName = KD.Krankenkasse__r.Name;
        kdVersNr = KD.Versichertennummer__c;
        system.debug('#########################alex002 artikelGruppe=' + artikelGruppe);
        buttonFaxVisible = false;
        buttonMailVisible = true;
        buttonPdfVisible = false;
        
        // getKundeKontakt();  
        if(artikelGruppe == null) {
        system.debug('#########################alex003');
        Att = [SELECT   a.ParentId, a.Parent.Type, a.OwnerId, a.Name, a.Owner.Name,
                        a.Parent.Name, a.Id, a.Description, a.ContentType, a.BodyLength 
                FROM Attachment a
                WHERE a.ParentId = :KdID ORDER BY a.CreatedDate DESC
                ];
        if((Att != null) && (Att.size() > 0)) {
            for(Attachment at : Att) {
                if(at.Name.containsIgnoreCase('51')) {
                    nachParagraf = '51';
                    artikelGruppe = 'PG 51';
                    break;
                }
                if(at.Name.containsIgnoreCase('54')) {
                    nachParagraf = '54';
                    artikelGruppe = 'PG 54';
                    break;
                }
                if(at.Name.containsIgnoreCase('5X')) {
                    nachParagraf = '5X';
                    artikelGruppe = 'PG 54';
                    break;
                }               
            }
        }       
        system.debug('#########################alex004 artikelGruppe=' + artikelGruppe);
        if(nachParagraf == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Paragraf für die Genehmigung nicht erkannt.'));        
        }
        }
        if(artikelGruppe == null) {
            artikelGruppe = 'PG 54';
        }   
        
        system.debug('#########################alex005 artikelGruppe=' + artikelGruppe);
        string txtkey = 'Antrag auf Kostenübernahme 54';
        if(artikelGruppe == 'PG 51') {
            txtkey = 'Antrag auf Kostenübernahme 51';
        }
        list<Antragstext__c> mtList = [SELECT Betreff__c, RichText__c 
                    FROM Antragstext__c 
                    WHERE Textkey__c = :txtkey
                    LIMIT 1];   
        
        if((mtList != null) && (mtList.size() == 1)){
            mText = mtList[0];
            if(KD.Krankenkasse__r.Name != null) {
                mText.RichText__c = mText.RichText__c.replace('$krankenkasse$', KD.Krankenkasse__r.Name);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$krankenkasse$', '');
            }
            mText.RichText__c = mText.RichText__c.replace('$kunde$', KD.Name);
            if(KD.Versichertennummer__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$versichertennummer$', KD.Versichertennummer__c);               
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$versichertennummer$', '');   
            }
            system.debug('#########################alex004');
            string gbdat = '01.01.0001';
            if(kd.Geburtsdatum_text__c != null) {
                gbdat = kd.Geburtsdatum_text__c;
            }
            mText.RichText__c = mText.RichText__c.replace('$geburtsdatum$', gbdat); 
            kdText = kdBody;       
            kdSubject = mText.Betreff__c;   
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Textvorlage nicht gefunden.'));       
        }
    }

    public PageReference sendenFaxAusKunde_reload() {       
        seteInitialisieren();
        PageReference returnPage = ApexPages.currentPage();
        returnPage.setRedirect(true);
        return null;
    }
    
    public PageReference sendenFaxAusKunde_zurueck() {       
        PageReference returnPage = new PageReference('/' + KdID);
        returnPage.setRedirect(true);
        return returnPage;
    }   
    
    public PageReference startMail() {   
       
        if ((kdMail == null ) || (kdMail == '' )) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'KontaktID ist leer'));            
            return null;
        }
        else {

                    kkName = KD.Krankenkasse__r.Name;

           
                    kdText = mText.RichText__c;
                
          
            
        }
        
        if (mAtId != null) {
        
                  AT = [SELECT a.ParentId, a.Parent.Type, a.OwnerId, a.Name, a.Owner.Name,
                        a.Parent.Name, a.Id, a.Description, a.ContentType, a.BodyLength, a.Body 
                    FROM Attachment a
                    WHERE a.Id = :mAtId
                    ];
            Messaging.Emailfileattachment Attach = new  Messaging.Emailfileattachment();                    
            Attach.Body = AT.Body;
            Attach.setContentType(AT.ContentType);
            Attach.setFileName(AT.Name);
            Attach.setInline(false);
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            String[] toAddress = new String[] {kdMail};
            mail.setToAddresses(toAddress);
            tMail = kdMail;
            atID = mAtId;
            mail.setSubject(kdSubject);
            mail.setHtmlBody(kdText);
            mail.setFileAttachments(new Messaging.Emailfileattachment[] {Attach});
            mail.setPlainTextBody(kdText);
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Mail gesendet an ' + kdMail));   
                createTask();
            }
            catch (System.Exception e)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Fehler beim Senden Mail'));    
                system.debug('#########################email####### error '  + e);
                return null;
            }
  
        }
        
        PageReference weiter = new PageReference('/apex/neuePBGenehmigungController');
        weiter.getParameters().put('kdid', KdID);
        weiter.getParameters().put('nextURL', '/apex/Formular_versenden');
        weiter.setRedirect(true);
        return weiter;
        
        // return null;
    }
    
    public PageReference startFax() { 
       if ((kdFax == null ) || (kdFax == '' )) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Fax ist leer'));            
            return null;
        }
        else {

                    kkName = KD.Krankenkasse__r.Name;                    
                    kdText = mText.RichText__c;
        } 
        if (fAtId != null) {
                AT = [SELECT a.ParentId, a.Parent.Type, a.OwnerId, a.Name, a.Owner.Name,
                        a.Parent.Name, a.Id, a.Description, a.ContentType, a.BodyLength, a.Body 
                    FROM Attachment a
                    WHERE a.Id = :fAtId
                    ];
            Messaging.Emailfileattachment Attach = new  Messaging.Emailfileattachment();                    
            Attach.Body = AT.Body;
            Attach.setContentType(AT.ContentType);
            Attach.setFileName(AT.Name);
            Attach.setInline(false);
            string fax = kdFax + '@fax.fax-mobile.de';
            tMail = kdFax;
            atID = fAtId;
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            String[] toAddress = new String[] {fax};
            String[] toCcAddress = new String[] {'alex.mischenko@freenet.de'};
            mail.setToAddresses(toAddress);
            mail.setCcAddresses(toCcAddress);
            mail.setSubject(kdSubject);
            mail.setHtmlBody(kdText);
            mail.setFileAttachments(new Messaging.Emailfileattachment[] {Attach});
            mail.setPlainTextBody(kdText);
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Fax gesendet an ' + kdFax)); 
                createTask();               
            }
            catch (System.Exception e)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Fehler beim Senden Fax'));    
                system.debug('#########################email####### error '  + e);
            }
            
            
                    
            
        } 
        return null;
    }
    
   public string getArtikelGruppe () {
        return ArtikelGruppe;
    }
    
    public void setArtikelGruppe (string ArtikelGruppe) {
        this.ArtikelGruppe = ArtikelGruppe;
    }

     public  List<SelectOption> getArtikelGruppen() {
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('PG 51', 'PG 51'));
         options.add(new SelectOption('PG 54', 'PG 54'));
         return options;
     }
     
    public string getKdMail() {
        return kdMail;
    }
    
    public void setKdMail(string kdMail) {
        this.kdMail = kdMail;       
    }
    
    public string getKdSubject() {
        return kdSubject;
    }
    
    public void setKdSubject(string kdSubject) {
        this.kdSubject = kdSubject;     
    }
    
    public string getKdText() {
        return kdText;
    }
    
    public void setKdText(string kdText) {
        this.kdText = kdText;       
    }
    
    public string getKdName() {
        return kdName;
    }
    
    public void setKdName(string kdName) {
        this.kdName = kdName;       
    }
    
//    public void getKdGeburtsdatum(string kdGeburtsdatum) {
//        return kdGeburtsdatum;       
//    } 
    
//    public void setKdGeburtsdatum(string kdGeburtsdatum) {
//        this.kdGeburtsdatum = kdGeburtsdatum;       
//    }    

    public string getKkName() {
        return kkName;
    }

    public string getKdFax() {
        return kdFax;
    }
    
    public string getKdVersNr() {
        return  KdVersNr;
    }
    
    public void setKdFax(string kdFax) {
        this.kdFax = kdFax;     
    }
    
    public string fAtID {
        get;
        set {
            fAtID = value;
        }
        
    }
    
    public string mAtID {
        get;
        set {
            mAtID = value;
        }
        
    }
    
    public void setFAtID(string fAtID) {
        this.fAtID = fAtID;     
    }


    public  List<SelectOption> getKundeKontakt() {
        List<SelectOption> options = new List<SelectOption>();
        List<KundeKontakt__c> kdKt = [SELECT Kontakt__c, Kontakt__r.Name
                                        FROM KundeKontakt__c
                                        WHERE Kunde__c = :KdID];
                                        
        if (kdKt != null && kdKt.size() != 0) {
            for (KundeKontakt__c KdK : kdKt) {
                options.add(new SelectOption(KdK.Kontakt__c, KdK.Kontakt__r.Name) );            
            }
            
        }                                       
        return options;
    
    }
    
    public  List<SelectOption> getTargetMail() {
        List<SelectOption> options = new List<SelectOption>();
        
        string mailTo = null;       
        
        asMail = asMail__c.getValues('Intern');
        try {
            mailTo = asMail.toAddr__c;
            options.add(new SelectOption(mailTo, mailTo) );  
        }
        catch (System.Exception e) {}
        asMail = asMail__c.getValues('asb');
        try {
            mailTo = asMail.toAddr__c;
            options.add(new SelectOption(mailTo, mailTo) );  
        }
        catch (System.Exception e) {}
        
                                               
        return options;
    
    }   
    

    public String getKdKontakt() {              
                return kdKontakt;
    }
        
    public String getKdBody() {              
                return kdBody;
    }

    public String getApName() {              
        return apName;
    }

    public String getKdBody2() {              
                return kdBody2;
    }
    
    public void setKdKontakt(String kdKontakt) {
                this.kdKontakt = kdKontakt;
    }
        
    public void setKdBody(String kdBody) {
                this.kdBody = kdBody;
    }
        
    public boolean getButtonMailVisible() {
        return buttonMailVisible;
    }
    
    public boolean getButtonFaxVisible() {
        return buttonFaxVisible;
    } 
    
    public boolean getButtonPdfVisible() {
        return buttonPdfVisible;
    } 
        
    public Antragstext__c getMtext() {
        return mText;
    }
 
     public Antragstext__c getMBtext() {
        return mBText;
    }  

    public id getKdID() {
        return KdID;
    }   
    
    public string getSeitenTitel() {
                if(buttonFaxVisible) {
                        return  'Senden Fax an Kunde.';
                }
                if(buttonMailVisible) {
                        return  'Senden Mail an Kunde.';
                }
                if(buttonPdfVisible) {
                        return  'Senden Brief an Kunde.';
                }        
                return  'Elektronische Datenübermittlung';
    }
    
    public void createTask() {
        string pg = 'PG54';
        if(artikelGruppe == 'PG 51') {
            pg = 'PG51';
        }
        id rtid = null;                                
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = :pg];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }       
        
        Task th = new Task(ActivityDate = Date.today(),
                            Subject='Antrag an PK übermittelt',
                            WhatId = KdID,
                            OwnerId = UserInfo.getUserId(),
                            RecordTypeId = rtid,
                            Status='Geschlossen');
        insert th;  
        // Gruppe 
                id grID = UserInfo.getUserId(); 
                list<Group> grList = [SELECT id FROM Group WHERE Name = 'Nachtelefonie PK' LIMIT 1];
                if((grList != null) && (grList.size() > 0)) {   
                    grID = grList[0].id;
                }
                list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                                FROM GroupMember WHERE GroupId = : grID];
                list<task> tsList = new list<task>();
                
                Date faelligkeitsdatum;
                DateTime remDateTime;
                
                try {
                    Faelligkeitsdatum__c  fDatum = Faelligkeitsdatum__c.getValues('Nachfassen bei PK wg offener KU');
                    remDateTime = System.now() + fDatum.zeitraum__c;
                    faelligkeitsdatum = Date.today().addDays(Integer.ValueOf(fDatum.zeitraum__c));
                }
                catch(system.exception e){
                    system.debug('error : ' + e.getMessage());
                    remDateTime = System.now() + 14;
                    faelligkeitsdatum = Date.today().addDays(14);
                }
                
                if((gmList != null) && (gmList.size() > 0)) { 
                    for(GroupMember GM : gmList) {
                        Task t = new Task(ActivityDate = faelligkeitsdatum,
                                            Subject='Nachfassen bei PK wg. offener KÜ',
                                            WhatId = KdID,
                                            OwnerId = GM.UserOrGroupId,
                                            IsReminderSet = true,
                                            ReminderDateTime = remDateTime,                                     
                                            Description = 'Nachfassen bei PK wg. offener KÜ',   
                                            RecordTypeId = rtid,                                            
                                            Status='Open');
                        tsList.add(t);
                    }
                }
                else {
                        Task t = new Task(ActivityDate = faelligkeitsdatum,
                                            Subject='Nachfassen bei PK wg. offener KÜ',
                                            WhatId = KdID,
                                            OwnerId = UserInfo.getUserId(),
                                            IsReminderSet = true,
                                            ReminderDateTime = remDateTime,                                     
                                            Description = 'Nachfassen bei PK wg. offener KÜ',    
                                            RecordTypeId = rtid,
                                            Status='Open');
                        tsList.add(t);                  
                }
        		Database.insert(tsList, false);
    }  

}