//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//      Autor:          WDS
//      Stand:          03.09.2015
//      Version:        0.1
//      geändert:       
//      Beschreibung:   controller für sendefaxanPHAG_pdf_mR.page   (mit Rezept)
//                                              
//  Änderungen:
//  14.12.2015 von AM #107897754. Einbau 3 Fragen (9,10 und 11) und Hartmann_Fax_Notizen 
//
// 
//  19.01.2015 von AM   #97879944 Einbau CC
// 29.01.2016 von BT    Das Feld 'Geburtsdatum__c' wird durch das Feld 'Geburtsdatum_text__c' erstetzt
// 24.03.2016 von BT    Löschen von CC
// 31.05.2016 von AM    Task werden doppelt angelegt. Das passiert nur bei MS Edfe / IE. Die beide browsers senden beim Verarbeiten
//                      von VF_Page "action" den zweiten kompletten request der Seite. 
//                      Lösung: beim task Anlegen wird zunächst geprüft ob innerhalb von 5 sek (?) den gleichen 
//                      tas bereits existiert. Wenn ja soll keine gleiche tasks geschriben werden.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public with sharing class sendefaxanPHAG_pdf_mR {
    public string retPage = ApexPages.currentPage().getParameters().get('retURL');
    public ID KdID = null;
    public Anschrift__c AD {get; set;}
    public Kundenstatus__c KDst {get; set;} 
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

    public sendefaxanPHAG_pdf_mR(integer dummy) {
    }

    public sendefaxanPHAG_pdf_mR() {
            this(ApexPages.currentPage().getParameters().get('id'));
    }
        
    public sendefaxanPHAG_pdf_mR(String Kunde_id){ 
        // Schema.DescribeSObjectResult sObjSH = Account.sObjectType.getDescribe();
        // string accKeyPrefix = sObjSH.getKeyPrefix(); 
        // sObjSH = Contact.sObjectType.getDescribe();
        // string conKeyPrefix = sObjSH.getKeyPrefix(); 
        // sObjSH = Kunde__c.sObjectType.getDescribe();
        // string kunKeyPrefix = sObjSH.getKeyPrefix(); 
        
        String strurl = ApexPages.currentPage().getUrl();
        KdID = id.valueOf(Kunde_id);
            
        KD = [SELECT Fax__c, Name, Krankenkasse__r.Name, Krankenkasse__c, Versichertennummer__c,
                Krankenkasse__r.bermittlung__c,
                Krankenkasse__r.IK_Nummer__c,
                Krankenkasse__r.Fax, Krankenkasse__r.Weitere_E_Mail__c,
                Ansprechpartner_Kasse__r.Fax, 
                Ansprechpartner_Kasse__r.Email, 
                Ansprechpartner_Kasse__r.Name,
                Kontakt_Krankenkasse_51__r.Fax, 
                Kontakt_Krankenkasse_51__r.Email,
                Kontakt_Krankenkasse_51__r.Name,
                Anrede__c,
                Vorname__c,
                Name__c,
                Stra_e__c,
                PLZA__c,
                Ort__c,
                Telefon__c,
                Mobil__c,
                e_mail__c,
                Geburtsdatum_text__c,
                inko_frage1__c,
                inko_frage2__c,
                inko_frage3__c,
                inko_frage4__c,
                inko_frage5__c,
                inko_frage6__c,
                inko_frage7__c,
                inko_frage8__c,
                inko_frage9__c,
                inko_frage10__c,
                inko_frage11__c,
                Hartmann_Fax_Notizen__c,
                Betreuer__r.salutation,
                Betreuer__r.Name,
                Betreuer__c,
                Betreuer__r.phone,
                Betreuer__r.MobilePhone,
                Betreuer__r.email,
                next_step__c    
                FROM Kunde__c
                
                WHERE id = :KdID];      

        kdName = KD.Name;
        kkName = KD.Krankenkasse__r.Name;
        kdVersNr = KD.Versichertennummer__c;
        
        buttonFaxVisible = false;
        buttonMailVisible = true;
        buttonPdfVisible = false;
        
        // getKundeKontakt();                              
        
         string txtkey = 'Inkontinenz-Beratungsgespräch Hartmann - Mit Rezept';
         
                      
                   
                    
        list<Antragstext__c> mtList = [SELECT Betreff__c, RichText__c 
                    FROM Antragstext__c 
                    WHERE Textkey__c = :txtkey
                    LIMIT 1];   
        
        if((mtList != null) && (mtList.size() == 1)){
            mText = mtList[0];
            system.debug('######################### wds004 mText' +mText.Betreff__c );

//
//        Diverse Infos bereitstellen
//
                if (kd.next_step__c == 'Gratisprobe'){

                
                List<Auftragsposition__c> APos = [select auftrag__r.bezeichnung__c,
                                                         Kunde__c,
                                                         Artikel__r.name
                                                  from Auftragsposition__c
                                                  where Kunde__c =: KD.id and
                                                        Auftrag__r.bezeichnung__c =: 'Muster-Artikel'
                                                        Limit 5];

                
                Integer j = 0;
                for (integer i = 0; i < apos.size(); i++){
                string p = 'produkt_ID_'+i+'$';
                system.debug('#########################alex004' + p);
                
                if (apos[i] != Null) 
                {
                J = I + 1;
                mText.RichText__c = mText.RichText__c.replace('$product_ID_'+j+'$', apos[i].artikel__r.name);
                   
                    }
                }
                if (apos.size() < 5){
                for (integer k = apos.size(); k < 5; k++){
                
                
                 
                
                J = k + 1;
                mText.RichText__c = mText.RichText__c.replace('$product_ID_'+j+'$', ' ');
                   
                    
                }
                }
                        
        }
        else{
            
            for (Integer j = 1; j < 6; j++){            
               
                mText.RichText__c = mText.RichText__c.replace('$product_ID_'+j+'$', ' ');
                                     
                }
                }
//
            if(KD.Inko_frage1__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage1$', KD.Inko_frage1__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage1$', '');
            }
            
            if(KD.Inko_frage2__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage2$', KD.Inko_frage2__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage2$', '');
            }
            
            if(KD.Inko_frage3__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage3$', KD.Inko_frage3__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage3$', '');
            }
            
            if(KD.Inko_frage4__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage4$', KD.Inko_frage4__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage4$', '');
            }
            
            if(KD.Inko_frage5__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage5$', KD.Inko_frage5__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage5$', '');
            }
            
            if(KD.Inko_frage6__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage6$', KD.Inko_frage6__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage6$', '');
            }
            
            if(KD.Inko_frage7__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage7$', KD.Inko_frage7__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage7$', '');
            }
            
            if(KD.Inko_frage8__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage8$', KD.Inko_frage8__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage8$', '');
            }
            if(KD.Inko_frage9__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage9$', KD.Inko_frage9__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage9$', '');
            }
            
            if(KD.Inko_frage10__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage10$', KD.Inko_frage10__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage10$', '');
            } 

            
            if(KD.Inko_frage11__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage11$', KD.Inko_frage11__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Inko_Frage11$', '');
            }   

            if(KD.Hartmann_Fax_Notizen__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Hartmann_Fax_Notizen$', KD.Hartmann_Fax_Notizen__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Hartmann_Fax_Notizen$', '');
            }
//
//        Infos des Ansprechpartners füllen
//
             if (Kd.Betreuer__c != Null){           

            

                AD = [SELECT  Name, 
                    Fax__c,
                    Anrede__c,
                    Stra_e__c,
                    PLZ__c,
                    Ort__c,
                    Telefon__c,                 
                    e_mail__c                   
                    FROM Anschrift__c
                    WHERE Kunde__c = :Kd.ID And Art_der_Anschrift__c =: 'Betreuer' 
                    Limit 1];                       
                    
                if(KD.betreuer__r.salutation != null) {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_anrede$', KD.betreuer__r.salutation );
                }
                else {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_anrede$', '');
                }
                
                if(KD.betreuer__r.name != null) {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_Nachname$', KD.betreuer__r.name );
                }
                else {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_Nachname$', '');
                } 
                if(AD.Stra_e__c != null) {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_Straße$', AD.Stra_e__c );
                }
                else {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_Straße$', '');
                }
            
                if(AD.PLZ__c != null) {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_Plz$', AD.PLZ__c );
                }
                else {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_Plz$', '');
                }
            
                if(AD.Ort__c != null) {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_Ort$', AD.Ort__c );
                }
                else {
                    mText.RichText__c = mText.RichText__c.replace('$ASP_Ort$', '');
                }
            }
             else {       
                mText.RichText__c = mText.RichText__c.replace('$ASP_Email$', '');
                mText.RichText__c = mText.RichText__c.replace('$ASP_Ort$', '');
                mText.RichText__c = mText.RichText__c.replace('$ASP_Plz$', '');
                mText.RichText__c = mText.RichText__c.replace('$ASP_Straße$', '');
             }
             
            if(KD.betreuer__r.Phone != null) {
                mText.RichText__c = mText.RichText__c.replace('$ASP_Telefon$', KD.betreuer__r.Phone );
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$ASP_Telefon$', '');
            }
            
            if(KD.betreuer__r.Mobilephone != null) {
                mText.RichText__c = mText.RichText__c.replace('$ASP_mobil$', KD.betreuer__r.Mobilephone);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$ASP_mobil$', '');
            }
            
            if(KD.betreuer__r.email != null) {
                mText.RichText__c = mText.RichText__c.replace('$ASP_Email$', KD.betreuer__r.email );
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$ASP_Email$', '');
            }
            
            //
            //        Kundeninfos füllen
            //            
            
            if(KD.Mobil__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$mobil$', KD.Mobil__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$mobil$', '');
            }
            
            if(KD.e_mail__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Email$', KD.e_mail__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Email$', '');
            }
            
            if(KD.Telefon__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Telefon$', KD.Telefon__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Telefon$', '');
            }
            
            if(KD.Ort__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Ort$', KD.Ort__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Ort$', '');
            }
            
            if(KD.PLZA__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Plz$', KD.PLZA__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Plz$', '');
            }
            
            if(KD.Stra_e__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Straße$', KD.Stra_e__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Straße$', '');
            }
            
            if(KD.name__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Nachname$', KD.name__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Nachname$', '');
            }
            
            if(KD.vorname__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$Vorname$', KD.vorname__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Vorname$', '');
            }
            
            if(KD.anrede__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$anrede$', KD.anrede__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$anrede$', '');
            }
            
            if(KD.Krankenkasse__r.Name != null) {
                mText.RichText__c = mText.RichText__c.replace('$Kostentraeger$', KD.Krankenkasse__r.Name);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$Kostentraeger$', '');
            }
            
            if(KD.Krankenkasse__r.IK_Nummer__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$IK_Nummer$', KD.Krankenkasse__r.IK_Nummer__c);
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$IK_Nummer$', '');
            }
            mText.RichText__c = mText.RichText__c.replace('$kunde$', KD.Name);
            if(KD.Versichertennummer__c != null) {
                mText.RichText__c = mText.RichText__c.replace('$versichertennummer$', KD.Versichertennummer__c);         
            }
            else {
                mText.RichText__c = mText.RichText__c.replace('$versichertennummer$', '');   
            }
            mText.RichText__c = mText.RichText__c.replace('$ASP_email$', '');
            system.debug('#########################alex004');
            string gbdat = '01.01.0001';
            if(kd.Geburtsdatum_text__c != null) {
                gbdat = KD.Geburtsdatum_text__c;
            }
            mText.RichText__c = mText.RichText__c.replace('$geburtsdatum$', gbdat); 
            kdText = kdBody;       
            kdSubject = mText.Betreff__c;
//            createTask();   
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Textvorlage nicht gefunden.'));       
        }
        }
        public PageReference createTask(){
            string notask= null;
            id rtid = null;                                
            list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'Inko'];
            if((rtList != null) && (rtList.size() > 0)) {
                rtId = rtList[0].id;
            } 
            list<task> existTask = [SELECT id, createddate FROM task 
                                        WHERE ActivityDate = :Date.today()
                                        AND OwnerId = :UserInfo.getUserId()
                                        AND Status = 'Geschlossen'
                                        AND Subject = 'Fax "Inkontinenz-Beratungsgespräch Hartmann - Mit Rezept" an PHAG versendet'
                                        AND WhatId = :KdId
                                        AND RecordTypeId = :rtid
                                        ORDER BY createddate DESC
                                        LIMIT 1];
        if((existTask != null) && (existTask.size() > 0)) {
            if(existTask[0].createddate.addSeconds(5) > datetime.now()) notask = 'notask';
        } 
            
        if(notask != 'notask') {
            Task th = new Task(ActivityDate = Date.today(),
                            Subject='Fax "Inkontinenz-Beratungsgespräch Hartmann - Mit Rezept" an PHAG versendet',
                            WhatId = KdID,
                            RecordTypeId = rtid,
                            OwnerId = UserInfo.getUserId(),
                            Status='Geschlossen');
            insert th;
            try {
                KDst = [SELECT Erstkontakt_hartmann__c FROM Kundenstatus__c WHERE Kunde__c = :KDid and Produktgruppe__c = 'Inko'];
                if (kdst.Erstkontakt_Hartmann__c == Null){
                    kdst.Erstkontakt_Hartmann__c = date.today();
                    update kdst;
                }
            }
            catch(system.Exception e) {
                system.debug('####################### Es gibt keinen Inko Eintrag im Kundenstatus!');
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
         options.add(new SelectOption('Mit Rezept', 'Mit Rezept'));
         options.add(new SelectOption('Ohne Rezept', 'Ohne Rezept'));
         options.add(new SelectOption('Bereits durchgestellt', 'Bereits durchgestellt'));
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
            
         
        }
}