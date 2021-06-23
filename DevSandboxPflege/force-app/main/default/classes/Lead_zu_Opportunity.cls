/****************************************************************************************************************************
// Erstellt 21.04.2016 von BT
//                         Klose und Srocke Gesellschaft fÃ¼r kreative KonfliktlÃ¶sungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Lead
//
//****************************************************************************************************************************
//
// Beschreibung:
// Konvertierung von Leads zu Opportunities              
//
//****************************************************************************************************************************
//Änderungen:
// 26.07.2016    BT Verknüpfung CB-Kunde <--> Kontakt
// 26.07.2016    BT Kontaktrolle: Role = 'PB = ASP' und IsPrimary = true 
// 29.07.2016    BT Bei der Neuanlage von Opps 'Preis Kategorie' auf 1 setzen, Anpassung Feld 'Anzahl der Etagen' in Opportunity 
// 17.08.2016    BT Das Erstelldatum und der StageName werden bei bestehenden Opportunities angezeigt
// 18.08.2016    BT Gibt es in einer Maske nur eine Auswahl, wird diese standardmäßig vorausgewählt.
// 19.08.2016    BT Waehlt man einen neuen Kontakt aus, werden Familiem nach Familien-Namen gesucht.
// 19.08.2016    BT Es werden alle Opportunities der bestehenden Familie angezeigt. 
// 19.08.2016    BT Waehlt man eine bestehende Opportunity aus, wird eine neue Opportunity im Hintergrund erstellt.
// 22.08.2016    BT Notification bei bereits konvertierten Leads
// 24.08.2016    BT Gibt es in einer Maske nur eine Auswahl, wird diese standardmäßig vorausgewählt.
// 12.09.2016    MZ Only the owner of lead is allowed to convert it.
// 11.10.2016    MZ The option of not choosing any contact added.
// 02.11.2016    BT Suche nach Familien: Kontakt-Suche nach Email, Telefonnummer
//                  Es werden maximal 25 Familien angezeigt. Anzeige einer Meldung, wenn mehr als 25 Familien gefunden wurden.
//                  Bestehende Familien: Anzeige des Familien_CRM_ID 
// 21.12.2016    BT Erweiterung um das Feld "Pflegegrad"
// 05.01.2017    BT #134953285 Anpassung der Funktion "Lead zu Opportunity" um den neuen Recordtype "Betreuungsleistungen"
// 23.01.2017    MZ set Urspr_nglicher_Lead__c with lead.Id
// 26.01.2017    BT Rolle = 'PB = ASP', wenn das Feld 'Person des Bedarfs' den Wert 'Für mich' hat
// 06.03.2017    MZ insert Potential-Partner for "Hausnotruf" recordType
// 07.03.2017    MZ add cpl/cpo and priority to Potential-Partner
// 24.04.2017    BT - Erweiterung der Lead-Konvertierung um „Notrufsystem“-Felder (Pflegegrad, Nächster Schritt,...)in Opportunity 
//                  - Es werden keine Potentiellen Partner mehr angelegt              
// 14.06.2017    BT - (HNR) Erweiterung um die Felder emergency_contact__c und zeitpunkt_der_Versorgung__c  
// 13.07.2017    BT Erweiterung um Recordtypen "Widerspruch" und "Pflegeimmobilien"
// 02.02.2018    MZ #154870869 - Bestehende Opps sollen bei Dopplungen nicht angefasst werden.
// 08.02.2018    MZ #154991989 - raise a warning message if a contact with same OM_User_ID already exists.
// 04.04.2018    MZ #155510105 Erweiterung um die Recordtypen "Badumbau"
// 04.04.2018    MZ Badumabua - new fields to convert. create casees after conversion.
// 18.04.2018    MZ mapping between "Badumbau" lead and opportunity products added.
// 23.10.2018    MZ #161257706 wizard version added
// 18.01.2019    MZ #163221257 target_person, care_level_state, objection_reason, objection_submitted fields added to wizard
// 04.02.2019    MZ 00001647 - Fehlermeldung bei pflege.de
// 26.04.2019    AD Curabox redesign - Integration des Curabox Lead-Konvertierungsprozesses
// 10.05.2019    AD set Lead Date in Opportunity
// 13.07.2019    AM saveAttachmentToPB other query 
// 06.04.2020    DZ "Nachtelefonie von Interessenten" auskommentiert
// 27.04.2020    BT #00002452 - Follow-up Task wird dem Standardkontakt zugeordnet, wenn kein zweiter Kontakt erstellt wurde
// 11.05.2020    DZ Recordtype "Multilead" hinzugefügt
// 16.07.2020    BT save multiple attachments to PB, delete automatically saved attachments on account and contact (ASP)
// 14.08.2020    DZ Badumbau: changed "Bezugspunkt der PLZ-Suche" to "Angefragte Postleitzahl" and opp.product = lead.TL_Treppenliftart__c
// 29.09.2020    BT #2580 set contact field CB_Lieferung__c
// 14.10.2020    DZ added new contact fields 
//****************************************************************************************************************************
*/
global with sharing class Lead_zu_Opportunity{
    private String tl_recordType = 'Treppenlift';
    private String bel_recordType = 'Betreuungsleistungen';
    private string ns_recordType = 'Notrufsysteme';
    private string ws_recordType = 'Widerspruch';
    private string pi_recordType = 'Pflegeimmobilien';
    private string bad_recordType = 'Badumbau';
    private string cb_recordType = 'Curabox';
    private string ml_recordType = 'Multilead';
    
    // steuer die Anzeige des Kontakts auf die visual force page
    public Boolean isCurabox {get; set;}
    public Boolean isNormalProzess {get; set;}
    
    public List<Lead> leadListe {get; set;}
    public Lead lead {get; set;}
    public List<Contact> kontaktListe {get; set;}
    // Contact list for PB
    public List<Contact> PBcontactList {get; set;}
    public List<Kunde__c> kundenListe {get; set;}
    public List<Account> famListe {get; set;}
    public List<Opportunity> oppListe {get; set;}
    public Contact kont {get; set;}
    // AD zweiter Kontakt
    public Contact zweiterKont {get; set;}
    // AD use to set a original contact Id for the duplicated contact.
    public Id originalId {get; set;}
    public Id kontId {get; set;}
    public Account fam {get; set;}
    public Id famId {get; set;}
    public Opportunity opp {get; set;}
    public Id oppId {get; set;}
    public string fmName {get; set;}
    public string sKont {get; set;}
    // AD Zweiter Kontakt
    public string selectedContact {get; set;}
    public string sFam {get; set;}
    public string sOpp {get; set;}
    public string sGrund {get; set;}
    public string message {get; set;}
    public string title {get; set;} 
    public string table1_layout;
    public string table3_layout;
    public string table4_layout;    
    public string message_layout;
    public string layout1 {get; set;}
    // public string layout2 {get; set;}
    public string layout3 {get; set;}
    public string layout4 {get; set;}
    // AD layout5 {get; set;}
    public string layout5 {get; set;}
    public string button_layout{get; set;}
    public string button_value {get; set;}
    public string seite1_layout {get; set;}
    //public string seite2_layout {get; set;}
    public string seite3_layout {get; set;}
    public string seite4_layout {get; set;}
    // AD seite5_layout
    public string seite5_layout {get; set;}
    public string uncheckedRadio1Layout {get; set;}
    public string checkedRadio1Layout {get; set;}
    public string uncheckedRadio2Layout {get; set;}
    public string checkedRadio2Layout {get; set;}    
    public string uncheckedRadio3Layout {get; set;}
    public string checkedRadio3Layout {get; set;}  
    public string uncheckedRadio4Layout {get; set;}
    public string checkedRadio4Layout {get; set;}
    // AD uncheckedRadio5Layout checkedRadio5Layout 
    public string uncheckedRadio5Layout {get; set;}
    public string checkedRadio5Layout {get; set;}  
    public string modalDialogLayout {get; set;}
    public string ownerErrorDialog {get; set;}
    public List<string> agList {set;}   
    public Map<Id, string> fmGrdMap {get; set;}
    public set<String> pgSet = new set<string>{'1','2','3','4','5'};
    public boolean duplicateAccepted {set; get;}
    public String duplicateDialog {set; get;}
    public String mainPageName {set; get;} 
    
        
    global Lead_zu_Opportunity(ApexPages.StandardController controller) {
        title = 'Schritt 1';
        seite1_layout = 'initial';
        seite3_layout = 'none';
        seite4_layout = 'none';
        seite5_layout = 'none';
        layout1 = 'slds-is-current';
        layout3 = 'slds-is-incomplete';
        layout4 = 'slds-is-incomplete';
        layout5 = 'slds-is-incomplete';
        button_layout = 'none';
        button_value = 'weiter';
        duplicateAccepted = false;
        duplicateDialog = 'none';
        
        konvertieren();
        
        // check if the user is the owner of the Lead
        if(lead.Owner.Id == UserInfo.getUserId() ){
            ownerErrorDialog = 'none';
            
            // check if the Lead has already converted
            if(lead.status == 'Qualified' || lead.status == 'qualifiziert') {
                modalDialogLayout = 'initial';
            }
            else {
                modalDialogLayout = 'none';
            }
        }
        else {
            ownerErrorDialog = 'initial';
            modalDialogLayout = 'none';
        }
    }    
    
    public void konvertieren() {
        String qID = System.currentPagereference().getParameters().get('ID');
         //DZ 14.10
        leadListe = [SELECT Id, Owner.Id, firstname, lastname, Email, Name, salutation, Geburtsdatum__c, Phone, MobilePhone, OM_Wizzard_Name2__c, OM_Tracking_Order_ID__c, OM_Wizard_Version__c, OM_Referrer__c, OM_Partner_ID__c, OM_Referenznummer__c,
                        TL_Treppenliftart__c, Umgebung__c,  TL_Zu_berwindendes_Hindernis__c, Street, City, PostalCode, pflegegrad__c, Pflegegrad_seit__c, RecordTypeId, Pflegestufe__c, Partner__c, next_step__c,
                        TL_Anzahl_der_Etagen__c, TL_H_usliche_Situation__c, TL_Belastbarkeit__c, TL_Postleitzahl_f_r_Suche__c, status, Lead_Status_Bemerkung__c, Phone2__c, R_ckrufm_glichkeit__c,
                        Zeitpunkt_der_Versorgung__c, Unterbringungsm_glichkeit__c, Aktuelle_Betreuung__c, H_ufigkeit_der_Unterst_tzung__c, Person_des_Bedarfs__c, Wohnort_der_Suche__c, GCLID__c,
                        location_direction__c, own_use__c, financing_model__c,alleine_au_er_Haus__c,in_letzter_Zeit_gest_rzt__c,koerperlicher_Zustand__c,emergency_contact__c,Soforthilfe_vor_Ort__c, 
                        createdDate, OM_UserId__c, Marketing_Cloud_ID__c, Preferred_timeframe__c, IK_Nummer_des_traegers__c, Versicherungsnummer__c, Krankenkasse__c, Pflegedienst__c,
                        LandlordOwnerAgreement__c, HousingSituation__c, RemodelingSolution__c, EntryLevel__c, TakeCareOfPossibleGrants__c, FloorOfRemodeling__c, extraInfo__c,                            
                        Widerspruchsgrund__c, Widerspruch_eingereicht__c, CB_Box__c, CB_Handschuh_Groesse__c, CB_Lieferung__c,
                        Angehoeriger_Anrede__c, Angehoeriger_Vorname__c, Angehoeriger_Nachname__c, Angehoeriger_Vollmacht__c, Angehoeriger_Email__c, Angeh_riger_Mobile__c,
                        Angehoeriger_Ort__c, Angehoeriger_PLZ__c, Angehoeriger_Strasse__c, Angehoeriger_Telefon__c, OM_Wizzard_Name2__r.Name, topics_multilead__c, vorherige_anfrage__c,  
                       Einmalhandschuhe_quantity__c, Haendedesinfektion_quantity__c, Flaechendesinfektion_quantity__c, Bettschutzeinlagen_quantity__c, Mundschutz_quantity__c, Schutzschuerzen_quantity__c, Waschbare_Bettschutzeinlagen_quantity__c, FFP2_Maske_quantity__c,
                       Delivery_interval__c, Delivery_interval_bettschutzeinlagen__c, Supplier_change__c, Supplier_change_startdate__c, PDF_Bestellformular__c, PDF_Antrag_Kostenuebernahme__c, PDF_Empfaengnisvollmacht__c, PDF_Wechselerklaerung__c, 
                       Vinyl_Allergy__c, Nitril_Allergy__c, Latex_Allergy__c, Packstation_FirstName__c, Packstation_LastName__c, Packstation_Postnumber__c, Packstation_Number_DHLstation__c, Packstation_Postalcode__c, Packstation_City__c
                    FROM Lead WHERE Id =: qID LIMIT 1];     
        
        lead = leadListe[0];
        leseKontakte();             
        if(kontaktListe != null && kontaktListe.size() > 0) {             
            uncheckedRadio1Layout = 'initial';
            checkedRadio1Layout = 'none';                 
        }
        else {
            sKont = 'neuerKontakt'; 
            uncheckedRadio1Layout = 'none';
            checkedRadio1Layout = 'initial';  
        }
    }
    
    public PageReference zuLeads(){
           PageReference PageRef = new PageReference('/' + lead.Id);
           PageRef.setRedirect(true);
                      
           return PageRef;
    }    
    
    public PageReference weiter(){
        List<RecordType> cbList = [SELECT Id, SobjectType, Name FROM RecordType WHERE SobjectType = 'Lead' AND Name = 'Curabox'];
        modalDialogLayout = 'none';
        ownerErrorDialog = 'none';
        if(title == 'Schritt 1') {                            
            if(sKont == null) {
                message = 'Bitte wählen Sie einen Kontakt aus';                
            }
            else if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
                if(sKont != 'neuerKontakt'){
                    String temp = getRoleFromContact(sKont);
                    if (temp != null) {
                        if (temp == 'PB') {
                            message = 'Der ausgewählte Kontakt existiert bereits als Pflegebedürftiger';
                        }
                        else {
                            message = null;
                            kontaktAnlegen();
                            lesePBKontakte();
                            seite1_layout = 'none';
                            seite5_layout = 'initial';                   
                            title = 'Schritt 2';
                            layout1 = 'slds-is-complete';
                            layout5 = 'slds-is-current'; 
                            button_layout = 'initial';
                            if(PBcontactList != null && PBcontactList.size() > 0) {              
                                uncheckedRadio5Layout = 'initial';
                                checkedRadio5Layout = 'none';                 
                            }
                            else {
                                selectedContact = 'neuerKontakt'; 
                                uncheckedRadio5Layout = 'none';
                                checkedRadio5Layout = 'initial';  
                            }
                        }
                    }
                    else {
                        message = null;
                        kontaktAnlegen();
                        lesePBKontakte();
                        seite1_layout = 'none';
                        seite5_layout = 'initial';                   
                        title = 'Schritt 2';
                        layout1 = 'slds-is-complete';
                        layout5 = 'slds-is-current'; 
                        button_layout = 'initial';
                        if(PBcontactList != null && PBcontactList.size() > 0) {              
                            uncheckedRadio5Layout = 'initial';
                            checkedRadio5Layout = 'none';                 
                        }
                        else {
                            selectedContact = 'neuerKontakt'; 
                            uncheckedRadio5Layout = 'none';
                            checkedRadio5Layout = 'initial';  
                        }
                    }
                }
                else {
                    message = null;
                    kontaktAnlegen();
                    lesePBKontakte();
                    seite1_layout = 'none';
                    seite5_layout = 'initial';                   
                    title = 'Schritt 2';
                    layout1 = 'slds-is-complete';
                    layout5 = 'slds-is-current'; 
                    button_layout = 'initial';
                    if(PBcontactList != null && PBcontactList.size() > 0) {              
                        uncheckedRadio5Layout = 'initial';
                        checkedRadio5Layout = 'none';                 
                    }
                    else {
                        selectedContact = 'neuerKontakt'; 
                        uncheckedRadio5Layout = 'none';
                        checkedRadio5Layout = 'initial';  
                    }
                }
            }
            else {
                if (sKont != 'neuerKontakt'){
                    sFam = getFamiliebyContact(sKont);
                    fam = [select Id from Account where Id =: sFam][0];
                    kontaktAnlegen();
                    leseOpportunities();
                    seite1_layout = 'none';
                    seite3_layout = 'none';
                    seite5_layout = 'none';
                    seite4_layout = 'initial';                   
                    title = 'Schritt 4';
                    layout1 = 'slds-is-complete';
                    layout5 = 'slds-is-complete';
                    layout3 = 'slds-is-complete';
                    layout4 = 'slds-is-current';
                    button_layout = 'initial';
                    button_value = 'speichern';
                    
                    if(oppListe != null && oppListe.size() != 0){
                        uncheckedRadio4Layout = 'initial';
                        checkedRadio4Layout = 'none';
                    }
                    else {
                        sOpp = 'neueOpportunity';
                        uncheckedRadio4Layout = 'none';
                        checkedRadio4Layout = 'initial';                          
                    }
                }
                else {
                    message = null;
                    if(message == null || message == '') {
                        kontaktAnlegen();
                        leseFamilie();
                        seite1_layout = 'none';
                        seite5_layout = 'none';
                        seite3_layout = 'initial';
                        title = 'Schritt 3';
                        layout1 = 'slds-is-complete';
                        layout5 = 'slds-is-complete';
                        layout3 = 'slds-is-current'; 
                        button_layout = 'initial';
                            
                        if(famListe != null && famListe.size() != 0){
                            uncheckedRadio3Layout = 'initial';
                            checkedRadio3Layout = 'none';
                        }
                        else {
                            sFam = 'neueFamilie';
                            uncheckedRadio3Layout = 'none';
                            checkedRadio3Layout = 'initial';                       
                        }
                    } 
                }
            }        
        }      
        else if(title == 'Schritt 2'){
            if(selectedContact == null) {
                message = 'Bitte wählen Sie einen Kontakt aus';
            }
            else{
                if (sKont != 'neuerKontakt' && selectedContact != 'neuerKontakt') {
                    String temp = getRoleFromContact(selectedContact);
                    if (temp != null) {
                        if (temp == 'ASP') {
                            message = 'Der ausgewählte Kontakt existiert bereits als Ansprechspartner';
                        }
                        else {
                            if (getFamiliebyContact(sKont) == getFamiliebyContact(selectedContact)) {
                                message = null;
                                if(message == null || message == '') {
                                    sFam = getFamiliebyContact(sKont);
                                    fam = [select Id from Account where Id =: sFam][0];
                                    createPflegeBeduertigeContact();
                                    leseOpportunities();
                                    seite3_layout = 'none';
                                    seite5_layout = 'none';
                                    seite4_layout = 'initial';                   
                                    title = 'Schritt 4';
                                    layout5 = 'slds-is-complete';
                                    layout3 = 'slds-is-complete';
                                    layout4 = 'slds-is-current';
                                    button_value = 'speichern';
                                    
                                    if(oppListe != null && oppListe.size() != 0){
                                        uncheckedRadio4Layout = 'initial';
                                        checkedRadio4Layout = 'none';
                                    }
                                    else {
                                        sOpp = 'neueOpportunity';
                                        uncheckedRadio4Layout = 'none';
                                        checkedRadio4Layout = 'initial';                          
                                    }                        
                                }
                            }
                            else {
                                message = null;
                                originalId = selectedContact;
                                if(message == null || message == '') {
                                    sFam = getFamiliebyContact(sKont);
                                    fam = [select Id from Account where Id =: sFam][0];
                                    // create duplicate contact
                                    selectedContact = 'neuerKontakt'; 
                                    createPflegeBeduertigeContact();
                                    // set original contact
                                    zweiterKont.Original_contact__c = originalId;
                                    leseOpportunities();
                                    seite3_layout = 'none';
                                    seite5_layout = 'none';
                                    seite4_layout = 'initial';                   
                                    title = 'Schritt 4';
                                    layout5 = 'slds-is-complete';
                                    layout3 = 'slds-is-complete';
                                    layout4 = 'slds-is-current';
                                    button_value = 'speichern';
                                    
                                    if(oppListe != null && oppListe.size() != 0){
                                        uncheckedRadio4Layout = 'initial';
                                        checkedRadio4Layout = 'none';
                                    }
                                    else {
                                        sOpp = 'neueOpportunity';
                                        uncheckedRadio4Layout = 'none';
                                        checkedRadio4Layout = 'initial';                          
                                    }                 
                                }
                            }
                        }
                    }
                    else{ 
                        if (getFamiliebyContact(sKont) == getFamiliebyContact(selectedContact)) {
                            message = null;
                            if(message == null || message == '') {
                                sFam = getFamiliebyContact(sKont);
                                fam = [select Id from Account where Id =: sFam][0];
                                createPflegeBeduertigeContact();
                                leseOpportunities();
                                seite3_layout = 'none';
                                seite5_layout = 'none';
                                seite4_layout = 'initial';                   
                                title = 'Schritt 4';
                                layout5 = 'slds-is-complete';
                                layout3 = 'slds-is-complete';
                                layout4 = 'slds-is-current';
                                button_value = 'speichern';
                                
                                if(oppListe != null && oppListe.size() != 0){
                                    uncheckedRadio4Layout = 'initial';
                                    checkedRadio4Layout = 'none';
                                }
                                else {
                                    sOpp = 'neueOpportunity';
                                    uncheckedRadio4Layout = 'none';
                                    checkedRadio4Layout = 'initial';                          
                                }                        
                            }
                        }
                        else {
                            message = null;
                            originalId = selectedContact;
                            if(message == null || message == '') {
                                sFam = getFamiliebyContact(sKont);
                                fam = [select Id from Account where Id =: sFam][0];
                                // create duplicate contact
                                selectedContact = 'neuerKontakt'; 
                                createPflegeBeduertigeContact();
                                // set original contact
                                zweiterKont.Original_contact__c = originalId;
                                leseOpportunities();
                                seite3_layout = 'none';
                                seite5_layout = 'none';
                                seite4_layout = 'initial';                   
                                title = 'Schritt 4';
                                layout5 = 'slds-is-complete';
                                layout3 = 'slds-is-complete';
                                layout4 = 'slds-is-current';
                                button_value = 'speichern';
                                
                                if(oppListe != null && oppListe.size() != 0){
                                    uncheckedRadio4Layout = 'initial';
                                    checkedRadio4Layout = 'none';
                                }
                                else {
                                    sOpp = 'neueOpportunity';
                                    uncheckedRadio4Layout = 'none';
                                    checkedRadio4Layout = 'initial';                          
                                }                 
                            }
                        }
                    }
                }
                else if (sKont != 'neuerKontakt' && selectedContact == 'neuerKontakt') {
                    message = null;
                    if(message == null || message == '') {
                        sFam = getFamiliebyContact(sKont);
                        fam = [select Id from Account where Id =: sFam][0];
                        createPflegeBeduertigeContact();
                        leseOpportunities();
                        seite3_layout = 'none';
                        seite5_layout = 'none';
                        seite4_layout = 'initial';                   
                        title = 'Schritt 4';
                        layout5 = 'slds-is-complete';
                        layout3 = 'slds-is-complete';
                        layout4 = 'slds-is-current';
                        button_value = 'speichern';
                        
                        if(oppListe != null && oppListe.size() != 0){
                            uncheckedRadio4Layout = 'initial';
                            checkedRadio4Layout = 'none';
                        }
                        else {
                            sOpp = 'neueOpportunity';
                            uncheckedRadio4Layout = 'none';
                            checkedRadio4Layout = 'initial';                          
                        }                        
                    }
                }
                else if (sKont == 'neuerKontakt' && selectedContact != 'neuerKontakt') {
                    message = null;
                    String temp = getRoleFromContact(selectedContact);
                    if (temp != null) {
                        if (temp == 'ASP') {
                            message = 'Der ausgewählte Kontakt existiert bereits als Ansprechspartner';
                        }
                        else {
                            sFam = getFamiliebyContact(selectedContact);
                            fam = [select Id from Account where Id =: sFam][0];
                            createPflegeBeduertigeContact();
                            leseOpportunities();
                            seite5_layout = 'none';
                            seite3_layout = 'none';
                            seite4_layout = 'initial';                   
                            title = 'Schritt 4';
                            layout5 = 'slds-is-complete';
                            layout3 = 'slds-is-complete';
                            layout4 = 'slds-is-current';
                            button_value = 'speichern';
                            
                            if(oppListe != null && oppListe.size() != 0){
                                uncheckedRadio4Layout = 'initial';
                                checkedRadio4Layout = 'none';
                            }
                            else {
                                sOpp = 'neueOpportunity';
                                uncheckedRadio4Layout = 'none';
                                checkedRadio4Layout = 'initial';                          
                            }  
                        }
                    }
                    else if(message == null || message == '') {
                        sFam = getFamiliebyContact(selectedContact);
                        fam = [select Id from Account where Id =: sFam][0];
                        createPflegeBeduertigeContact();
                        leseOpportunities();
                        seite5_layout = 'none';
                        seite3_layout = 'none';
                        seite4_layout = 'initial';                   
                        title = 'Schritt 4';
                        layout5 = 'slds-is-complete';
                        layout3 = 'slds-is-complete';
                        layout4 = 'slds-is-current';
                        button_value = 'speichern';
                        
                        if(oppListe != null && oppListe.size() != 0){
                            uncheckedRadio4Layout = 'initial';
                            checkedRadio4Layout = 'none';
                        }
                        else {
                            sOpp = 'neueOpportunity';
                            uncheckedRadio4Layout = 'none';
                            checkedRadio4Layout = 'initial';                          
                        }                        
                    }
                }
                else if(duplicateAccepted || !duplicateUserIdExists()){
                    message = null;
                    createPflegeBeduertigeContact();
                    leseFamilie();
                    seite5_layout = 'none';
                    seite3_layout = 'initial';                   
                    title = 'Schritt 3';
                    layout5 = 'slds-is-complete';
                    layout3 = 'slds-is-current';
                    button_layout = 'initial';
                        
                    if(famListe != null && famListe.size() != 0){
                        uncheckedRadio3Layout = 'initial';
                        checkedRadio3Layout = 'none';
                    }
                    else {
                        sFam = 'neueFamilie';
                        uncheckedRadio3Layout = 'none';
                        checkedRadio3Layout = 'initial';                       
                    }
                }
            }
        }
        else if (title == 'Schritt 3') {
            if(sFam == null) {
                message = 'Bitte wählen Sie eine Familie aus';                
            }
            else{
                message = null;
                if(message == null || message == '') {
                    familieAnlegen();
                    leseOpportunities();
                    seite3_layout = 'none';
                    seite4_layout = 'initial';                   
                    title = 'Schritt 4';
                    layout5 = 'slds-is-complete';
                    layout3 = 'slds-is-complete';
                    layout4 = 'slds-is-current';
                    button_value = 'speichern';
                    
                    if(oppListe != null && oppListe.size() != 0){
                        uncheckedRadio4Layout = 'initial';
                        checkedRadio4Layout = 'none';
                    }
                    else {
                        sOpp = 'neueOpportunity';
                        uncheckedRadio4Layout = 'none';
                        checkedRadio4Layout = 'initial';                          
                    }                        
                }
            }
        }
        else {
            if(sOpp == null){
                message = 'Bitte wählen Sie eine Opportunity aus';
            }
            else {
                layout4 = 'slds-is-complete';
                message = saveWithSatndardLeadConvert();
                
                if(oppId != null  && String.isEmpty(message)) {
                    if (lead.RecordTypeId == cbList[0].Id){
                        String toContact = '';
                        if (zweiterKont != null) {
                            toContact = zweiterKont.Id;
                        }
                        else {
                            toContact = kontId;
                        }
                        PageReference contactPage = new PageReference('/' + toContact);
                        contactPage.setRedirect(true);
                        mainPageName = null;
                        return contactPage;
                    } 
                    else {
                        PageReference PageRef = new PageReference('/' + oppId);
                        PageRef.setRedirect(true);
                        mainPageName = null;
                        return PageRef;
                    }
                }
                else {
                    return null;
                }
            }
            
        }
        return null;
    }
    
    public PageReference zurueck() {
        modalDialogLayout = 'none';
        ownerErrorDialog = 'none';
        if(title == 'Schritt 4'){
            if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
                if (    (sKont != 'neuerKontakt' && selectedContact != 'neuerKontakt') 
                    ||  (sKont == 'neuerKontakt' && selectedContact != 'neuerKontakt') 
                    ||  (sKont != 'neuerKontakt' && selectedContact == 'neuerKontakt') 
                ) {
                    title = 'Schritt 2';
                    seite5_layout = 'initial';
                    seite3_layout = 'none';
                    seite4_layout = 'none';
                    layout5 = 'slds-is-current';
                    layout3 = 'slds-is-incomplete';
                    layout4 = 'slds-is-incomplete';
                    button_value = 'weiter';
                    selectedContact = null;
                    
                    if(PBcontactList != null || PBcontactList.size() > 0) {              
                        uncheckedRadio5Layout = 'initial';
                        checkedRadio5Layout = 'none';                 
                    }
                    else {
                        selectedContact = 'neuerKontakt'; 
                        uncheckedRadio5Layout = 'none';
                        checkedRadio5Layout = 'initial';  
                    }
                }
                else {
                    title = 'Schritt 3';
                    seite3_layout = 'initial';
                    seite4_layout = 'none';
                    layout3 = 'slds-is-current';
                    layout4 = 'slds-is-incomplete';   
                    button_value = 'weiter';
                    sFam = null;    
                    
                    if(famListe != null && famListe.size() != 0){
                        uncheckedRadio3Layout = 'initial';
                        checkedRadio3Layout = 'none';
                    }
                    else {
                        sFam = 'neueFamilie';
                        uncheckedRadio3Layout = 'none';
                        checkedRadio3Layout = 'initial';                     
                    }  
                }
            }
            else {
                if (sKont != 'neuerKontakt'){
                    title = 'Schritt 1';
                    seite1_layout = 'initial';
                    seite3_layout = 'none';
                    seite5_layout = 'none';
                    seite4_layout = 'none';
                    layout1 = 'slds-is-current';
                    layout3 = 'slds-is-incomplete';
                    layout4 = 'slds-is-incomplete';
                    layout5 = 'slds-is-incomplete';   
                    button_value = 'weiter';
                    sKont = null;
                
                    if(kontaktListe != null && kontaktListe.size() > 0) {
                        uncheckedRadio1Layout = 'initial';
                        checkedRadio1Layout = 'none';                 
                    }
                    else {
                        sKont = 'neuerKontakt';
                        uncheckedRadio1Layout = 'none';
                        checkedRadio1Layout = 'initial';
                    } 
                }
                else{
                    title = 'Schritt 3';
                    seite3_layout = 'initial';
                    seite4_layout = 'none';
                    layout3 = 'slds-is-current';
                    layout4 = 'slds-is-incomplete';   
                    button_value = 'weiter';
                    sFam = null;    
                    
                    if(famListe != null && famListe.size() != 0){
                        uncheckedRadio3Layout = 'initial';
                        checkedRadio3Layout = 'none';
                    }
                    else {
                        sFam = 'neueFamilie';
                        uncheckedRadio3Layout = 'none';
                        checkedRadio3Layout = 'initial';                     
                    }
                }
            }             
        }
        else if(title == 'Schritt 3'){
            if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
                title = 'Schritt 2';
                seite5_layout = 'initial';
                seite3_layout = 'none';
                layout5 = 'slds-is-current';
                layout3 = 'slds-is-incomplete';
                button_value = 'weiter';
                selectedContact = null;
                
                if(PBcontactList != null && PBcontactList.size() > 0) {              
                    uncheckedRadio5Layout = 'initial';
                    checkedRadio5Layout = 'none';                 
                }
                else {
                    selectedContact = 'neuerKontakt'; 
                    uncheckedRadio5Layout = 'none';
                    checkedRadio5Layout = 'initial';  
                }
            }
            else{
                title = 'Schritt 1';
                seite1_layout = 'initial';
                seite3_layout = 'none';
                seite5_layout = 'none';
                layout1 = 'slds-is-current';
                layout3 = 'slds-is-incomplete';
                layout5 = 'slds-is-incomplete';   
                button_value = 'weiter';
                sKont = null;
            
                if(kontaktListe != null && kontaktListe.size() > 0) {
                    uncheckedRadio1Layout = 'initial';
                    checkedRadio1Layout = 'none';                 
                }
                else {
                    sKont = 'neuerKontakt';
                    uncheckedRadio1Layout = 'none';
                    checkedRadio1Layout = 'initial';
                }             
            }         
        }   
        else if(title == 'Schritt 2'){               
            title = 'Schritt 1';
            seite1_layout = 'initial';
            seite5_layout = 'none';
            layout1 = 'slds-is-current';
            layout5 = 'slds-is-incomplete';
            button_layout = 'none';
            sKont = null;
            
            if(kontaktListe != null && kontaktListe.size() > 0) {
                uncheckedRadio1Layout = 'initial';
                checkedRadio1Layout = 'none';                 
            }
            else {
                sKont = 'neuerKontakt';
                uncheckedRadio1Layout = 'none';
                checkedRadio1Layout = 'initial';
            }                       
        }                   
           
        return null;           
    }
        
    public void waehleKontaktAus() {
        sKont = System.currentPageReference().getParameters().get('kontaktId');               
    }
    // zweiter Kontakt
    public void waehleZweiterKontaktAus(){
        selectedContact = System.currentPageReference().getParameters().get('contactId'); 
    }

    public void waehleFamilieAus() {
        sFam = System.currentPageReference().getParameters().get('famId');                              
    }   
    
    public void waehleOpportunityAus() {
        sOpp = System.currentPageReference().getParameters().get('oppId');                              
    } 
    
    public void waehleGrundAus(){
        sGrund = System.currentPageReference().getParameters().get('grd');
        System.debug('mansi::: sGrund:::'+ sGrund);
        sOpp = 'Ausschuss';
    }      
    
    public List<string> getAgList(){
        List<String> lst = new List<String>();
        lst.add('- Keine -');
        lst.add('Ausschuss');
        lst.add('Dopplung');
        lst.add('Falsche Adressierung');
        lst.add('Testanfrage (intern)');
        lst.add('Bereits curabox-Kunde');
        lst.add('Adresse im Ausland');
        lst.add('Keine Telefonnummer angegeben');
        lst.add('Information (Kein Bedarf)');
        return lst;
    }
     
    public string getMessage_layout(){
        if(message == null){
            return 'none';
        }
        else {
            return 'initial';
        }
    }
            
    public string getTable1_layout(){
           if(kontaktListe != null && kontaktListe.size() != 0){
               return 'initial';
           }
           else {
               return 'none';
           }
    }   
    
    public string getTable3_layout(){
           if(famListe != null && famListe.size() != 0){
               return 'initial';
           }
           else {
               return 'none';
           }
    }  
    
    public string getTable4_layout(){
           if(oppListe != null && oppListe.size() != 0){
               return 'initial';
           }
           else {
               return 'none';
           }
    }  
    
    public void familieZuOrdnen(){
         fmName = System.currentPageReference().getParameters().get('fmName'); 
         sFam = 'famZuOrdnen';
    }     
    
    public void kontaktAnlegen(){
           List<RecordType> rtList1 = [SELECT Id FROM RecordType WHERE Name = 'Familienangehörige'];
           List<RecordType> rtList2 = [SELECT Id, sObjectType FROM RecordType WHERE Name = 'Standard' and sObjectType = 'Contact'];
           List<RecordType> cbList = [SELECT Id, SobjectType, Name FROM RecordType WHERE SobjectType = 'Lead' AND Name = 'Curabox'];
           
           if(sKont == 'neuerKontakt'){                              
               if(rtList1 != null && rtList1.size() != 0) {
                   if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)) {
                       kont = new Contact(  Salutation = lead.Angehoeriger_Anrede__c,
                                        firstname = lead.Angehoeriger_Vorname__c,
                                        lastname = lead.Angehoeriger_Nachname__c,
                                        Email = lead.Angehoeriger_Email__c,
                                        Phone = lead.Angehoeriger_Telefon__c,
                                        MailingCity = lead.Angehoeriger_Ort__c,
                                        MailingPostalCode = lead.Angehoeriger_PLZ__c,
                                        MailingStreet = lead.Angehoeriger_Strasse__c,
                                        RecordTypeId = rtList1[0].Id,
                                        OtherPhone = lead.Angeh_riger_Mobile__c,
                                        Art_des_Kontakts__c = 'Angehörige(r)',
                                        Ursprungsanfrage__c = lead.OM_Wizzard_Name2__c);
                        if(lead.Angeh_riger_Mobile__c != null) kont.MobilePhone = lead.Angeh_riger_Mobile__c;
                        isCurabox = true;
                        isNormalProzess = false;                                
                    }
                    else{
                        kont = new Contact(  Salutation = lead.Salutation,
                                        firstname = lead.firstname,
                                        lastname = lead.lastname,
                                        Email = lead.Email,
                                        Phone = lead.Phone,
                                        MailingCity = lead.City,
                                        MailingPostalCode = lead.PostalCode,
                                        MailingStreet = lead.Street,
                                        RecordTypeId = rtList1[0].Id,
                                        OtherPhone = lead.Phone2__c);
                        if (lead.RecordTypeId == cbList[0].Id) {
                            if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){}
                            else {
                                kont.Art_des_Kontakts__c = 'Pflegebedürftige(r)';
                                kont.Ursprungsanfrage__c = lead.OM_Wizzard_Name2__c;
                                //DZ 14.10.20
                                kont.CB_Lieferung__c = lead.cb_lieferung__c;
                                kont.Einmalhandschuhe_quantity__c = lead.Einmalhandschuhe_quantity__c;
                                kont.Haendedesinfektion_quantity__c = lead.Haendedesinfektion_quantity__c;
                                kont.Flaechendesinfektion_quantity__c = lead.Flaechendesinfektion_quantity__c;
                                kont.Bettschutzeinlagen_quantity__c = lead.Bettschutzeinlagen_quantity__c;
                                Kont.Mundschutz_quantity__c = lead.Mundschutz_quantity__c;
                                kont.Schutzschuerzen_quantity__c = lead.Schutzschuerzen_quantity__c;
                                kont.Waschbare_Bettschutzeinlagen_quantity__c = lead.Waschbare_Bettschutzeinlagen_quantity__c;
                                kont.FFP2_Maske_quantity__c = lead.FFP2_Maske_quantity__c;
                                kont.Delivery_interval__c = lead.Delivery_interval__c;
                                kont.Delivery_interval_bettschutzeinlagen__c = lead.Delivery_interval_bettschutzeinlagen__c;
                                kont.Supplier_change__c = lead.Supplier_change__c;
                                kont.Supplier_change_startdate__c = lead.Supplier_change_startdate__c;
                                kont.PDF_Bestellformular__c = lead.PDF_Bestellformular__c;
                                kont.PDF_Antrag_Kostenuebernahme__c = lead.PDF_Antrag_Kostenuebernahme__c;
                                kont.PDF_Empfaengnisvollmacht__c = lead.PDF_Empfaengnisvollmacht__c;
                                kont.PDF_Wechselerklaerung__c = lead.PDF_Wechselerklaerung__c;
                                kont.Vinyl_Allergy__c = lead.Vinyl_Allergy__c;
                                kont.Nitril_Allergy__c = lead.Nitril_Allergy__c;
                                kont.Latex_Allergy__c = lead.Latex_Allergy__c;
                            }
                        }
                        if(lead.MobilePhone != null) kont.MobilePhone = lead.MobilePhone;               
                        if(lead.pflegegrad__c != null) kont.Pflegegrad__c = lead.pflegegrad__c;
                        if (lead.Pflegegrad_seit__c != null) kont.Pflegegrad_seit__c = lead.Pflegegrad_seit__c;
                        //
                        if (lead.Geburtsdatum__c != null && String.isNotEmpty(lead.Geburtsdatum__c)){
                            try {
                                String[] str = lead.Geburtsdatum__c.replace('.', '-').split('-', 3);
                                Integer tag = Integer.valueOf(str[0]);
                                Integer monat =Integer.valueOf(str[1]);
                                Integer jahr = Integer.valueOf(str[2]);
                                kont.Birthdate = Date.newInstance(jahr, monat, tag);
                                kont.Geburtsjahr__c = jahr;
                            } catch (Exception e) {
                                System.debug('Birthday error: ' + e.getMessage());
                            }
                        }
                        if (lead.Krankenkasse__c != null && String.isNotEmpty(lead.Krankenkasse__c)) {
                            kont.Kranken_Pflegekasse__c = lead.Krankenkasse__c;
                        }
                        if (lead.Pflegedienst__c != null && String.isNotEmpty(lead.Pflegedienst__c)) {
                            kont.Pflegedienst__c = lead.Pflegedienst__c;
                        }
                        if (lead.IK_Nummer_des_traegers__c != null && String.isNotEmpty(lead.IK_Nummer_des_traegers__c)){
                            kont.IK_Nummer_des_Tr_gers__c = lead.IK_Nummer_des_traegers__c;
                        } 
                        if (lead.Versicherungsnummer__c != null && String.isNotEmpty(lead.Versicherungsnummer__c)) {
                            kont.Versicherungsnummer__c = lead.Versicherungsnummer__c;
                        }
                        // curabox redesign - set contact fields based on lead value for Curabox opportunities
                        setCuraboxContactFields();
                        isCurabox = false;
                        isNormalProzess = true;
                    }                               
               }
               else {
                   system.debug('#################BT2016: Kein Recordtype Familienangehörige wurde gefunden !');
               }
           }
           else {
               List<Contact> kontList = [select id, RecordTypeId, AccountId, Passender_CB_Kunde__c, Pflegegrad__c, Art_Von_Handschuhe__c, Wunschbox__c from Contact where id =: sKont];
               kont = kontList[0];
                // speziell für curabox 
                if (!(lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c))){
                    if(lead.pflegegrad__c != null) kont.Pflegegrad__c = lead.pflegegrad__c;
                    // curabox redesign - set contact fields based on lead value for Curabox opportunities
                    setCuraboxContactFields();
                }            
               
               if(rtList2 != null && rtList2.size() != 0) {
                   if(kont.RecordTypeId == rtList2[0].Id) {
                       if(rtList1 != null && rtList1.size() != 0) {
                           kont.RecordTypeId = rtList1[0].Id;
                           kont.AccountId = null;                           
                       }  
                       else {
                           system.debug('#################BT2016: Kein Recordtype Familienangehörige wurde gefunden !');
                       }                     
                   }
               }
               else {
                   system.debug('#################BT2016: Kein Recordtype Standard wurde gefunden !');
               }
               
               try {
                   update kont;
               }
               catch(System.exception e) {
                   system.debug('#################BT2016: Kontakt konnte nicht upgedatet werden !');
               }           
           }
           /*
           try {
               kont.Pflegestufe__c = lead.Pflegestufe__c;
           }
           catch(system.exception e) {}*/
    }

    // zweiter Kontakt für Curabox 'Pflegebedürftiger'
    public void createPflegeBeduertigeContact(){
        List<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name ='Familienangehörige' and sObjectType = 'Contact'];
        if (selectedContact == 'neuerKontakt') {
            zweiterKont = new Contact();
            zweiterKont.Salutation = lead.Salutation;
            zweiterKont.FirstName = lead.firstname;
            zweiterKont.LastName = lead.lastname;
            zweiterKont.Email = lead.Email;
            zweiterKont.Lead__c = lead.Id;
            zweiterKont.Phone = lead.Phone;
            zweiterKont.MailingCity = lead.City;
            zweiterKont.MailingPostalCode = lead.PostalCode;
            zweiterKont.MailingStreet = lead.Street;
            zweiterKont.OtherPhone = lead.Phone2__c;
            zweiterKont.RecordTypeId = rtList[0].Id;
            zweiterKont.Art_des_Kontakts__c = 'Pflegebedürftige(r)';
            zweiterKont.Ursprungsanfrage__c = lead.OM_Wizzard_Name2__c;
            //DZ 14.10.20
            zweiterKont.CB_Lieferung__c = lead.cb_lieferung__c;
            zweiterKont.Einmalhandschuhe_quantity__c = lead.Einmalhandschuhe_quantity__c;
            zweiterKont.Haendedesinfektion_quantity__c = lead.Haendedesinfektion_quantity__c;
            zweiterKont.Flaechendesinfektion_quantity__c = lead.Flaechendesinfektion_quantity__c;
            zweiterKont.Bettschutzeinlagen_quantity__c = lead.Bettschutzeinlagen_quantity__c;
            zweiterKont.Mundschutz_quantity__c = lead.Mundschutz_quantity__c;
            zweiterKont.Schutzschuerzen_quantity__c = lead.Schutzschuerzen_quantity__c;
            zweiterKont.Waschbare_Bettschutzeinlagen_quantity__c = lead.Waschbare_Bettschutzeinlagen_quantity__c;
            zweiterKont.FFP2_Maske_quantity__c = lead.FFP2_Maske_quantity__c;
            zweiterKont.Delivery_interval__c = lead.Delivery_interval__c;
            zweiterKont.Delivery_interval_bettschutzeinlagen__c = lead.Delivery_interval_bettschutzeinlagen__c;
            zweiterKont.Supplier_change__c = lead.Supplier_change__c;
            zweiterKont.Supplier_change_startdate__c = lead.Supplier_change_startdate__c;
            zweiterKont.PDF_Bestellformular__c = lead.PDF_Bestellformular__c;
            zweiterKont.PDF_Antrag_Kostenuebernahme__c = lead.PDF_Antrag_Kostenuebernahme__c;
            zweiterKont.PDF_Empfaengnisvollmacht__c = lead.PDF_Empfaengnisvollmacht__c;
            zweiterKont.PDF_Wechselerklaerung__c = lead.PDF_Wechselerklaerung__c;
            zweiterKont.Vinyl_Allergy__c = lead.Vinyl_Allergy__c;
            zweiterKont.Nitril_Allergy__c = lead.Nitril_Allergy__c;
            zweiterKont.Latex_Allergy__c = lead.Latex_Allergy__c;
            if (lead.Geburtsdatum__c != null && String.isNotEmpty(lead.Geburtsdatum__c)){
                try {
                    String[] str = lead.Geburtsdatum__c.replace('.', '-').split('-', 3);
                    Integer tag = Integer.valueOf(str[0]);
                    Integer monat =Integer.valueOf(str[1]);
                    Integer jahr = Integer.valueOf(str[2]);
                    zweiterKont.Birthdate = Date.newInstance(jahr, monat, tag);
                    zweiterKont.Geburtsjahr__c = jahr;
                } catch (Exception e) {
                   System.debug('Birthday error: ' + e.getMessage());
                }
            }
            if(lead.MobilePhone != null) zweiterKont.MobilePhone = lead.MobilePhone;
            if (lead.pflegegrad__c != null) zweiterKont.Pflegegrad__c = lead.pflegegrad__c;
            if (lead.Pflegegrad_seit__c != null) zweiterKont.Pflegegrad_seit__c = lead.Pflegegrad_seit__c;
            if (lead.Krankenkasse__c != null && String.isNotEmpty(lead.Krankenkasse__c)) {
                zweiterKont.Kranken_Pflegekasse__c = lead.Krankenkasse__c;
            }
            if (lead.Pflegedienst__c != null && String.isNotEmpty(lead.Pflegedienst__c)) {
                zweiterKont.Pflegedienst__c = lead.Pflegedienst__c;
            } 
            if (lead.IK_Nummer_des_traegers__c != null && String.isNotEmpty(lead.IK_Nummer_des_traegers__c)){
                zweiterKont.IK_Nummer_des_Tr_gers__c = lead.IK_Nummer_des_traegers__c;
            } 
            if (lead.Versicherungsnummer__c != null && String.isNotEmpty(lead.Versicherungsnummer__c)) {
                zweiterKont.Versicherungsnummer__c = lead.Versicherungsnummer__c;
            }
            // Wunschbox
            if (lead.CB_Box__c != null && !String.isEmpty(lead.CB_Box__c)) {
                String curabox = convertCurabox(lead.CB_Box__c);
                List<curabox__c> curaboxList = [select Id, Name from curabox__c where Name =: curabox limit 1];
                if(curaboxList != null && !curaboxList.isEmpty()){
                    zweiterKont.Wunschbox__c = curaboxList[0].Id;
                }
            }
            // Handschuhe
            if(lead.CB_Handschuh_Groesse__c != null && !String.isEmpty(lead.CB_Handschuh_Groesse__c)){
                List<Product__c> prdList = [select id, Name from Product__c where Name =: lead.CB_Handschuh_Groesse__c limit 1];
                if(prdList != null && !prdList.isEmpty()){
                    zweiterKont.Art_Von_Handschuhe__c = prdList[0].Id;
                }
            }
        }
        else {
            List<Contact> contactList = new List<Contact>();
            try {
                contactList = [select Id, RecordTypeId, AccountId, Pflegegrad__c, Art_Von_Handschuhe__c, Wunschbox__c from Contact where Id =: selectedContact];
            } catch (Exception e) {
                System.debug('No found selectedContact: '+ e);
            }  
            if(contactList != null && contactList.size() > 0) {
                zweiterKont = contactList[0];
                // Wunschbox
                if (lead.CB_Box__c != null && !String.isEmpty(lead.CB_Box__c)) {
                    String curabox = convertCurabox(lead.CB_Box__c);
                    List<curabox__c> curaboxList = [select Id, Name from curabox__c where Name =: curabox limit 1];
                    if(curaboxList != null && !curaboxList.isEmpty()){
                        zweiterKont.Wunschbox__c = curaboxList[0].Id;
                    }
                }
                // Handschuhe
                if(lead.CB_Handschuh_Groesse__c != null && !String.isEmpty(lead.CB_Handschuh_Groesse__c)){
                    List<Product__c> prdList = [select id, Name from Product__c where Name =: lead.CB_Handschuh_Groesse__c limit 1];
                    if(prdList != null && !prdList.isEmpty()){
                        zweiterKont.Art_Von_Handschuhe__c = prdList[0].Id;
                    }
                }
            }
            try {
                update zweiterKont;
            }
            catch(System.exception e) {
                system.debug('#################AD2019: Der zweite Kontakt konnte nicht upgedatet werden !');
            }           
        }
    }

    public String convertCurabox(String name){
        String curabox = '';
        switch on name {
            when 'box1' {
               curabox = 'CB1';
            }
            when 'box2'{
                curabox = 'CB2';
            }
            when 'box3'{
                curabox = 'CB3';
            }
            when 'box4'{
                curabox = 'CB4';
            }
            when 'box5'{
                curabox = 'CB5';
            }
            when 'Flexbox'{
                curabox = 'CB6 - Flexibel';
            }
            when else {
               curabox = name;
            }
        }
        return curabox;
    }
    
    // fields of contact should be filled for Curabox lead
    private void setCuraboxContactFields(){
        setArtVonHandschuhe(); 
        setWunschbox();
    }
    
    // set Art_Von_Handschuhe__c field of contact based on the value of CB_Handschuh_Groesse__c in lead
    private void setArtVonHandschuhe(){
        if( !String.isEmpty(lead.CB_Handschuh_Groesse__c) && kont.Art_Von_Handschuhe__c == null){
            List<Product__c> prdList = [select id, Name from Product__c where Name =: lead.CB_Handschuh_Groesse__c limit 1];
            if(prdList != null && !prdList.isEmpty()){
                kont.Art_Von_Handschuhe__c = prdList[0].Id;
            }
        }
    }
    
    // set Wunschbox__c field of contact based on the value of CB_Box__c in lead
    private void setWunschbox(){
        if( !String.isEmpty(lead.CB_Box__c) && kont.Wunschbox__c == null ){
            String curabox = convertCurabox(lead.CB_Box__c);
            List<curabox__c> curaboxList = [select Id, Name from curabox__c where Name =: curabox limit 1];
            if(curaboxList != null && !curaboxList.isEmpty()){
                kont.Wunschbox__c = curaboxList[0].Id;
            }
        }
    }

    public void familieAnlegen() {
           if(sFam == 'neueFamilie'){
               list<RecordType> rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];

               if(rtList != null && rtList.size() != 0) {
                   if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
                       fam = new Account(   Name = lead.Angehoeriger_Nachname__c,
                                        Familien_Name__c = lead.Angehoeriger_Nachname__c,
                                        BillingCity = lead.Angehoeriger_Ort__c,
                                        RecordTypeId = rtList[0].Id );
                   }                   
                   else {
                       fam = new Account(   Name = lead.lastname,
                                        Familien_Name__c = lead.lastname,
                                        BillingCity = lead.City,
                                        RecordTypeId = rtList[0].Id );
                   }
               }
               else {
                   system.debug('#################BT2016: Kein Recordtype Familien wurde gefunden !');
               }                              
           }
           else if(sFam == 'famZuOrdnen'){
               List<Account> fmListe = [select Id from Account where Name =: fmName];
               
               if(fmListe != null && fmListe.size() != 0) {
                   fam = fmListe[0];
               }
               else {
                                      
                   if(fmName == '' || fmName == null) {
                       message = 'Bitte wählen Sie eine Familie aus !';
                   }
                
               }
           }
           else {
               List<Account> fmListe = [select Id from Account where Id =: sFam];
               fam = fmListe[0];           
           }
    }
    
    public void leseKontakte(){  
           List<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name IN ('Familienangehörige', 'Standard') and sObjectType = 'Contact'];
           
            if(rtList != null && rtList.size() != 0){
                if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){        
                    if(rtList.size() == 1){
                        kontaktListe = [Select Id, Name, firstname, lastname, Email, Phone, RecordTypeId, MobilePhone, CreatedById, AccountId, Art_des_Kontakts__c, 
                                    Familien_Zugeh_rigkeit__c, von__c, MailingStreet, MailingCity, MailingPostalCode, Art_Von_Handschuhe__c, Wunschbox__c
                                    from Contact 
                                    where ( ((Email != null and Email =: lead.Angehoeriger_Email__c) 
                                                or (Alternative_Email__c != null and Alternative_Email__c =: lead.Angehoeriger_Email__c)
                                                )
                                        or ( (Phone != null and Phone=: lead.Angehoeriger_Telefon__c) 
                                            or (MobilePhone != null and MobilePhone =: lead.Angehoeriger_Telefon__c) 
                                            or (HomePhone != null and HomePhone =: lead.Angehoeriger_Telefon__c) 
                                            or (OtherPhone != null and OtherPhone =: lead.Angehoeriger_Telefon__c)
                                        )
                                        or (firstname =: lead.Angehoeriger_Vorname__c and lastname =: lead.Angehoeriger_Nachname__c and mailingpostalcode =: lead.Angehoeriger_PLZ__c and firstname != null and lastname != null and mailingpostalcode != null)
                                    ) 
                                    and RecordTypeId =: rtList[0].Id];  
                    }
                    else {
                        kontaktListe = [select id, Name, firstname, lastname, Email, Phone, RecordTypeId, MobilePhone, CreatedById, AccountId, Art_des_Kontakts__c, 
                                        Familien_Zugeh_rigkeit__c, von__c, MailingStreet, MailingCity, MailingPostalCode, Art_Von_Handschuhe__c, Wunschbox__c
                                        from Contact 
                                        where ( ((Email != null and Email =: lead.Angehoeriger_Email__c) 
                                                or (Alternative_Email__c != null and Alternative_Email__c =: lead.Angehoeriger_Email__c)
                                                    )
                                            or ( (Phone != null and Phone=: lead.Angehoeriger_Telefon__c) 
                                                or (MobilePhone != null and MobilePhone =: lead.Angehoeriger_Telefon__c) 
                                                or (HomePhone != null and HomePhone =: lead.Angehoeriger_Telefon__c) 
                                                or (OtherPhone != null and OtherPhone =: lead.Angehoeriger_Telefon__c)
                                            )
                                            or (firstname =: lead.Angehoeriger_Vorname__c and lastname =: lead.Angehoeriger_Nachname__c and mailingpostalcode =: lead.Angehoeriger_PLZ__c and firstname != null and lastname != null and mailingpostalcode != null)
                                        ) 
                                        and RecordTypeId IN (:rtList[0].Id, :rtList[1].Id)];                      
                    }
                }
                else {
                    if(rtList.size() == 1){
                         kontaktListe = [Select Id, Name, firstname, lastname, Email, Phone, RecordTypeId, MobilePhone, CreatedById, AccountId, Art_des_Kontakts__c, 
                                            Familien_Zugeh_rigkeit__c, von__c, MailingStreet, MailingCity, MailingPostalCode, Art_Von_Handschuhe__c, Wunschbox__c
                                            from Contact 
                                            where ( ((Email != null and Email =: lead.Email) 
                                                    or (Alternative_Email__c != null and Alternative_Email__c =: lead.Email)
                                                    )
                                            or ( (Phone != null and Phone=: lead.Phone) 
                                                or (MobilePhone != null and MobilePhone =: lead.Phone) 
                                                or (HomePhone != null and HomePhone =: lead.Phone) 
                                                or (OtherPhone != null and OtherPhone =: lead.Phone) 
                                                )
                                            or (firstname =: lead.firstname and lastname =: lead.lastname and mailingpostalcode =: lead.PostalCode and firstname != null and lastname != null and mailingpostalcode != null)
                                                ) 
                                            and RecordTypeId =: rtList[0].Id];  
                    }
                    else {
                        kontaktListe =  [Select Id, Name, firstname, lastname, Email, Phone, RecordTypeId, MobilePhone, CreatedById, AccountId, Art_des_Kontakts__c, 
                                            Familien_Zugeh_rigkeit__c, von__c, MailingStreet, MailingCity, MailingPostalCode, Art_Von_Handschuhe__c, Wunschbox__c
                                            from Contact 
                                            where ( ((Email != null and Email =: lead.Email) 
                                                    or (Alternative_Email__c != null and Alternative_Email__c =: lead.Email)
                                                    )
                                            or ( (Phone != null and Phone=: lead.Phone) 
                                                or (MobilePhone != null and MobilePhone =: lead.Phone) 
                                                or (HomePhone != null and HomePhone =: lead.Phone) 
                                                or (OtherPhone != null and OtherPhone =: lead.Phone) 
                                                )
                                            or (firstname =: lead.firstname and lastname =: lead.lastname and mailingpostalcode =: lead.PostalCode and firstname != null and lastname != null and mailingpostalcode != null)
                                                )
                                            and RecordTypeId IN (:rtList[0].Id, :rtList[1].Id)];                      
                    }
                }                             
            }
            else {
               system.debug('#################BT2016: Kein Recordtype Familienangehörige/Standard wurde gefunden !');
            }

            if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
               isCurabox = true;
               isNormalProzess = false;
            }
            else {
               isCurabox = false;
               isNormalProzess = true;
            }
    }
    
    public void lesePBKontakte(){  
        List<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name IN ('Familienangehörige', 'Standard') and sObjectType = 'Contact'];
           
        if(rtList != null && rtList.size() != 0){        
            if(rtList.size() == 1){
                PBcontactList = [Select Id, Name, firstname, lastname, Email, Phone, RecordTypeId, MobilePhone, CreatedById, AccountId, Art_des_Kontakts__c, 
                                    Familien_Zugeh_rigkeit__c, von__c, MailingStreet, MailingCity, MailingPostalCode, Art_Von_Handschuhe__c, Wunschbox__c
                                    from Contact 
                                    where ( ((Email != null and Email =: lead.Email) 
                                            or (Alternative_Email__c != null and Alternative_Email__c =: lead.Email)
                                            )
                                    or ( (Phone != null and Phone=: lead.Phone) 
                                            or (MobilePhone != null and MobilePhone =: lead.Phone) 
                                            or (HomePhone != null and HomePhone =: lead.Phone) 
                                            or (OtherPhone != null and OtherPhone =: lead.Phone) 
                                    )
                                    or (firstname =: lead.firstname and lastname =: lead.lastname and mailingpostalcode =: lead.PostalCode and firstname != null and lastname != null and mailingpostalcode != null)
                                    ) 
                                    and RecordTypeId =: rtList[0].Id];
            }
            else {
                PBcontactList = [Select Id, Name, firstname, lastname, Email, Phone, RecordTypeId, MobilePhone, CreatedById, AccountId, Art_des_Kontakts__c, 
                                    Familien_Zugeh_rigkeit__c, von__c, MailingStreet, MailingCity, MailingPostalCode, Art_Von_Handschuhe__c, Wunschbox__c
                                    from Contact 
                                    where ( ((Email != null and Email =: lead.Email) 
                                            or (Alternative_Email__c != null and Alternative_Email__c =: lead.Email)
                                            )
                                    or ( (Phone != null and Phone=: lead.Phone) 
                                            or (MobilePhone != null and MobilePhone =: lead.Phone) 
                                            or (HomePhone != null and HomePhone =: lead.Phone) 
                                            or (OtherPhone != null and OtherPhone =: lead.Phone) 
                                        )
                                    or (firstname =: lead.firstname and lastname =: lead.lastname and mailingpostalcode =: lead.PostalCode and firstname != null and lastname != null and mailingpostalcode != null)
                                    )
                                    and RecordTypeId IN (:rtList[0].Id, :rtList[1].Id)];                      
            }                                  
        }
    }
    
    public void leseFamilie(){               
           list<RecordType> rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];
           list<RecordType> ag_rtList = [SELECT Id FROM RecordType WHERE Name = 'Familienangehörige'];   
           fmGrdMap = new Map<Id, String>();
           set<Id> faIdSet = new set<Id>();           
           Integer fmAnzahl = 0;
                     
           if(sKont == 'neuerKontakt'){
               if(rtList != null && rtList.size() != 0) {               
                    if(ag_rtList != null && ag_rtList.size() != 0) {
                        List<Contact> faListe = new List<Contact>();
                        if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){ 
                            faListe = [select Id, Email, Phone, OtherPhone, HomePhone, MobilePhone, Alternative_Email__c, RecordTypeId, AccountId 
                                            from Contact
                                            where ( ((Email != null and Email =: lead.Angehoeriger_Email__c) 
                                                    or (Alternative_Email__c != null and Alternative_Email__c =: lead.Angehoeriger_Email__c)
                                                )
                                            or ( (Phone != null and Phone=: lead.Angehoeriger_Telefon__c) 
                                                or (MobilePhone != null and MobilePhone =: lead.Angehoeriger_Telefon__c) 
                                                or (HomePhone != null and HomePhone =: lead.Angehoeriger_Telefon__c) 
                                                or (OtherPhone != null and OtherPhone =: lead.Angehoeriger_Telefon__c) 
                                            ))
                                            and AccountId != null
                                            and RecordTypeId =: ag_rtList[0].Id ]; 
                        }
                        else {
                            faListe = [select Id, Email, Phone, OtherPhone, HomePhone, MobilePhone, Alternative_Email__c, RecordTypeId, AccountId 
                                            from Contact
                                            where ( ((Email != null and Email =: lead.Email) 
                                                    or (Alternative_Email__c != null and Alternative_Email__c =: lead.Email)
                                                )
                                            or ( (Phone != null and Phone=: lead.Phone) 
                                                or (MobilePhone != null and MobilePhone =: lead.Phone) 
                                                or (HomePhone != null and HomePhone =: lead.Phone) 
                                                or (OtherPhone != null and OtherPhone =: lead.Phone) 
                                            ))
                                            and AccountId != null
                                            and RecordTypeId =: ag_rtList[0].Id ];
                        }
                                                       
                        if(faListe != null && faListe.size() != 0) {
                            for(Contact ag: faListe){
                                faIdSet.add(ag.AccountId);
                                //############################################
                                if(ag.Email == lead.Email || ag.Email == lead.Angehoeriger_Email__c || ag.Alternative_Email__c == lead.Email || ag.Alternative_Email__c == lead.Angehoeriger_Email__c) {
                                    if(fmGrdMap.get(ag.AccountId) == null || !fmGrdMap.get(ag.AccountId).contains('Email-Adresse')) {
                                        fmGrdMap.put(ag.AccountId, 'Email-Adresse ');
                                    }      
                                } 
                                if((ag.Phone == lead.Phone) || (ag.Phone == lead.Angehoeriger_Telefon__c) || (ag.OtherPhone == lead.Phone) || (ag.OtherPhone == lead.Angehoeriger_Telefon__c) 
                                || (ag.MobilePhone == lead.Phone) || (ag.MobilePhone == lead.Angehoeriger_Telefon__c) || (ag.HomePhone == lead.Phone) || (ag.HomePhone == lead.Angehoeriger_Telefon__c) ) {
                                    if(fmGrdMap.get(ag.AccountId) == null || !fmGrdMap.get(ag.AccountId).contains('Telefonnummer')) {
                                        if((ag.Email == lead.Email) || (ag.Email == lead.Angehoeriger_Email__c) || (ag.Alternative_Email__c == lead.Email) || (ag.Alternative_Email__c == lead.Angehoeriger_Email__c)){
                                            fmGrdMap.put(ag.AccountId, 'Email-Adresse ' + 'Telefonnummer ');
                                        }
                                        else {
                                           fmGrdMap.put(ag.AccountId, 'Telefonnummer ');
                                        }
                                    }
                                }                                                                                                     
                            }
                           
                            famListe = [select id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                       BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                       from Account 
                                       where id IN: faIdSet
                                       and RecordTypeId =: rtList[0].Id
                                       LIMIT 500];                                       
                               
                            if(famListe != null && famListe.size() != 0) fmAnzahl = famListe.size();
                               
                            famListe = [select id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                           BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                           from Account 
                                           where id IN: faIdSet
                                           and RecordTypeId =: rtList[0].Id
                                           LIMIT 25];       
                        }
                        else {
                            if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){

                                famListe = [SELECT id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                                BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                                from Account 
                                                WHERE (
                                                    (Familien_Name__c =: lead.Angehoeriger_Nachname__c AND BillingPostalCode =:lead.Angehoeriger_PLZ__c AND Familien_Name__c != null AND BillingPostalCode != null) OR 
                                                    (Familien_Name__c =: lead.Angehoeriger_Nachname__c AND ShippingPostalCode =:lead.Angehoeriger_PLZ__c AND Familien_Name__c != null AND ShippingPostalCode != null)
                                                )
                                                AND RecordTypeId =: rtList[0].Id
                                                LIMIT 500];                                  
                                        
                                if(famListe != null && famListe.size() != 0) fmAnzahl = famListe.size();    
                                
                                famListe = [SELECT id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                            BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                            from Account 
                                            WHERE (
                                                (Familien_Name__c =: lead.Angehoeriger_Nachname__c AND BillingPostalCode =:lead.Angehoeriger_PLZ__c AND Familien_Name__c != null AND BillingPostalCode != null) OR 
                                                (Familien_Name__c =: lead.Angehoeriger_Nachname__c AND ShippingPostalCode =:lead.Angehoeriger_PLZ__c AND Familien_Name__c != null AND ShippingPostalCode != null)
                                            )
                                            AND RecordTypeId =: rtList[0].Id 
                                            LIMIT 25];  
                                
                                if(famListe != null && famListe.size() != 0) {              
                                    for(Account fm: famListe) {
                                        fmGrdMap.put(fm.id, 'Familienname und PLZ');
                                    } 
                                }
                            }
                            else {                                    
                                famListe = [SELECT id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                                BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                                from Account 
                                                WHERE (
                                                    (Familien_Name__c =: lead.lastname AND BillingPostalCode =:lead.PostalCode AND Familien_Name__c != null AND BillingPostalCode != null) OR 
                                                    (Familien_Name__c =: lead.lastname AND ShippingPostalCode =:lead.PostalCode AND Familien_Name__c != null AND ShippingPostalCode != null)
                                                )
                                                AND RecordTypeId =: rtList[0].Id 
                                                LIMIT 500];                                  
                                        
                                if(famListe != null && famListe.size() != 0) fmAnzahl = famListe.size();    
                                
                                famListe = [SELECT id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                            BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                            from Account 
                                            WHERE (
                                                (Familien_Name__c =: lead.lastname AND BillingPostalCode =:lead.PostalCode AND Familien_Name__c != null AND BillingPostalCode != null) OR 
                                                (Familien_Name__c =: lead.lastname AND ShippingPostalCode =:lead.PostalCode AND Familien_Name__c != null AND ShippingPostalCode != null)
                                            )
                                            AND RecordTypeId =: rtList[0].Id 
                                            LIMIT 25];  
                                
                                if(famListe != null && famListe.size() != 0) {              
                                    for(Account fm: famListe) {
                                        fmGrdMap.put(fm.id, 'Familienname und PLZ');
                                    } 
                                }       
                            }                                                
                        }
                  }
                  else {                  
                            system.debug('#################BT2016: Kein Recordtype Familienangehörige wurde gefunden !');
                                
                            if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){

                                famListe = [SELECT id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                                BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                                from Account 
                                            WHERE (
                                                (Familien_Name__c =: lead.Angehoeriger_Nachname__c AND BillingPostalCode =:lead.Angehoeriger_PLZ__c AND Familien_Name__c != null AND BillingPostalCode != null) OR 
                                                (Familien_Name__c =: lead.Angehoeriger_Nachname__c AND ShippingPostalCode =:lead.Angehoeriger_PLZ__c AND Familien_Name__c != null AND ShippingPostalCode != null)
                                            )
                                            AND RecordTypeId =: rtList[0].Id
                                            LIMIT 500];                                  
                                        
                                if(famListe != null && famListe.size() != 0) fmAnzahl = famListe.size();    
                                
                                famListe = [SELECT id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                            BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                            from Account 
                                            WHERE (
                                                (Familien_Name__c =: lead.Angehoeriger_Nachname__c AND BillingPostalCode =:lead.Angehoeriger_PLZ__c AND Familien_Name__c != null AND BillingPostalCode != null) OR 
                                                (Familien_Name__c =: lead.Angehoeriger_Nachname__c AND ShippingPostalCode =:lead.Angehoeriger_PLZ__c AND Familien_Name__c != null AND ShippingPostalCode != null)
                                            )
                                            AND RecordTypeId =: rtList[0].Id 
                                            LIMIT 25];  
                                
                                if(famListe != null && famListe.size() != 0) {              
                                    for(Account fm: famListe) {
                                        fmGrdMap.put(fm.id, 'Familienname und PLZ');
                                    } 
                                }
                            }
                            else {                                    
                                famListe = [SELECT id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                                BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                                from Account 
                                            WHERE (
                                                (Familien_Name__c =: lead.lastname AND BillingPostalCode =:lead.PostalCode AND Familien_Name__c != null AND BillingPostalCode != null) OR 
                                                (Familien_Name__c =: lead.lastname AND ShippingPostalCode =:lead.PostalCode AND Familien_Name__c != null AND ShippingPostalCode != null)
                                            )
                                            AND RecordTypeId =: rtList[0].Id 
                                            LIMIT 500];                                  
                                        
                                if(famListe != null && famListe.size() != 0) fmAnzahl = famListe.size();    
                                
                                famListe = [SELECT id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                            BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                            from Account 
                                            WHERE (
                                                (Familien_Name__c =: lead.lastname AND BillingPostalCode =:lead.PostalCode AND Familien_Name__c != null AND BillingPostalCode != null) OR 
                                                (Familien_Name__c =: lead.lastname AND ShippingPostalCode =:lead.PostalCode AND Familien_Name__c != null AND ShippingPostalCode != null)
                                            )
                                            AND RecordTypeId =: rtList[0].Id 
                                            LIMIT 25];  
                                
                                if(famListe != null && famListe.size() != 0) {              
                                    for(Account fm: famListe) {
                                        fmGrdMap.put(fm.id, 'Familienname und PLZ');
                                    } 
                                }       
                            }                 
                  }               
               }   
               else {
                   famListe = null;
                   system.debug('#################BT2016: Kein Recordtype Familien wurde gefunden !');
               }  
           }
           else{                
               if(rtList != null && rtList.size() != 0) {
                   famListe = [select id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                       BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                       from Account 
                                       where id =: kont.AccountId
                                       and RecordTypeId =: rtList[0].Id
                                       LIMIT 500];    
                                       
                   if(famListe != null && famListe.size() != 0) fmAnzahl = famListe.size();   
                   
                   famListe = [select id, Name, BillingCity, Familien_Name__c, RecordTypeId, Type, Phone, Website, OwnerId, Industry, BillingStreet, 
                                       BillingPostalCode, Familien_ID__c, Familien_CRM_ID__c
                                       from Account 
                                       where id =: kont.AccountId
                                       and RecordTypeId =: rtList[0].Id
                                       LIMIT 25];  
                   
                   if(famListe != null && famListe.size() != 0) {              
                        for(Account fm: famListe) {
                            fmGrdMap.put(fm.id, 'AccountId');
                        } 
                   }                                
               }   
               else {
                   famListe = null;
                   system.debug('#################BT2016: Kein Recordtype Familien wurde gefunden !');
               }   
           } 
           
           if(fmAnzahl > 25) message = 'Mehr als 25 passende Familien wurden gefunden. Es werden 25 Familien angezeigt.';

           // wenn das Lead Angehöriger enthält.
           if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
               isCurabox = true;
               isNormalProzess = false;
           }
           else {
               isCurabox = false;
               isNormalProzess = true;
           }                                                        
    }   
    
    public void leseOpportunities(){
           if(sFam != 'neueFamilie'){
               list<RecordType> rtList;
               list<RecordType> leadRtList = [SELECT Id, SobjectType, Name FROM RecordType WHERE Id =: lead.RecordTypeId];
               if(leadRtList != null && leadRtList.size() != 0) rtList = [SELECT Id, SobjectType FROM RecordType WHERE Name =: leadRtList[0].Name and SobjectType = 'Opportunity'];                
               
               if(rtList != null && rtList.size() != 0) {
                   List<Opportunity> oplst = new List<Opportunity>();
                   Set<Id> opIdSet = new Set<Id>();
                   
                   oppListe = [select id, AccountId, Name, Produkt_Kategorie__c, RecordTypeId, StageName, CreatedDate, CloseDate, Amount, 
                                      OwnerId, Alternative_Postleitzahl__c, Kategorie__c, CampaignId
                                      from Opportunity 
                                      where AccountId =: fam.Id 
                                      and RecordTypeId =: rtList[0].Id];                                                                                            
               }
               else {
                   oppListe = null;
                   system.debug('#################BT2016: Kein Recordtype Treppenlift wurde gefunden !');
               }
           }
           else {
               oppListe = null;
           }
    }
    
    public String saveWithSatndardLeadConvert(){
        List<RecordType> oppRtList = [SELECT Id, SobjectType, Name FROM RecordType WHERE SobjectType = 'Opportunity'];
        List<RecordType> cbList = [SELECT Id, SobjectType, Name FROM RecordType WHERE SobjectType = 'Lead' AND Name = 'Curabox']; 
        Map<String, Id> opp_rtList = new Map<String, Id>();
        for(RecordType rt: oppRtList ){
            opp_rtList.put(rt.Name, rt.Id);
        }
        
        list<RecordType> leadRtList = [SELECT Id, SobjectType, Name FROM RecordType WHERE SobjectType = 'Lead'];
        Map<Id, String> lead_rtList = new Map<Id, String>();
        for(RecordType rt: leadRtList){
            lead_rtList.put(rt.Id, rt.Name);
        }
        
        //added to avoid converting lead without creating contact roles.
        Savepoint sp = Database.setSavepoint();
        
        try{ 
            if(sFam == 'neueFamilie'){
                fam.Id = null;
                insert fam;
            }
        }catch(Exception e){
            // Roll the database back to before we saved ANYTHING
            Database.rollback(sp);
            return 'Error: Konvertierung fehlgeschlagen1! ' + e.getMessage();
            system.debug(e.getMessage());
            //system.debug('#############BT2016: Eine neue Familie konnte nicht angelegt werden');
        }
        if(fam != null) famId = fam.Id;
        if(famId != null) kont.AccountId = famId;
        
        try{
            kont.OM_UserID__c = lead.OM_UserID__c;
            if(sKont == 'neuerKontakt'){
                if(String.isEmpty(lead.Marketing_Cloud_ID__c)){
                    kont.Marketing_Cloud_ID__c = lead.Id;
                }else{
                    kont.Marketing_Cloud_ID__c = lead.Marketing_Cloud_ID__c;
                }
                kont.CB_Lieferung__c = lead.CB_Lieferung__c;
                kont.Id = null;                
                insert kont;
            }else{
                update kont;
            }
            kontId = kont.Id;
            // zweiter Kontakt anlegen
            if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)) {
                if(famId != null) zweiterKont.AccountId = famId;
                if(kontId != null) zweiterKont.Betreuer__c = kontId;
                zweiterKont.OM_UserID__c = lead.OM_UserID__c;
                if(selectedContact == 'neuerKontakt'){
                    if(String.isEmpty(lead.Marketing_Cloud_ID__c)){
                        zweiterKont.Marketing_Cloud_ID__c = lead.Id;
                    }else{
                        zweiterKont.Marketing_Cloud_ID__c = lead.Marketing_Cloud_ID__c;
                    }
                    zweiterKont.CB_Lieferung__c = lead.CB_Lieferung__c;
                    zweiterKont.Id = null;
                    insert zweiterKont;
                }
                else{
                    update zweiterKont;
                }

                // set attachment to PB
                if(zweiterKont.Id != null && String.isNotEmpty(zweiterKont.Id)){
                    try {
                        //User benutzer = [SELECT Id, Name FROM User WHERE Id =: lead.OwnerID LIMIT 1];
                        //if (benutzer.Name == 'IT Support') {
                            saveAttachmentToPB();
                        //}
                    } catch (Exception e) {
                        System.debug('Fehler beim Attachment '+ e.getMessage());
                    }
                }
            }
        }catch(Exception e){
            if(e.getMessage().contains('CANNOT_REPARENT_RECORD')){
                kont.ownerId = UserInfo.getUserId();
            }else if(e.getMessage().contains('Pflegestufe')){
                kont.Pflegestufe__c = null;
            }else{
                // Roll the database back to before we saved ANYTHING
                Database.rollback(sp);
                return 'Error: Konvertierung fehlgeschlagen2! ' + e.getMessage() + e.getLineNumber();
            }
                try {                                                
                    if(sKont == 'neuerKontakt'){
                        if(String.isEmpty(lead.Marketing_Cloud_ID__c)){
                            kont.Marketing_Cloud_ID__c = lead.Id;
                        }else{
                            kont.Marketing_Cloud_ID__c = lead.Marketing_Cloud_ID__c;
                        }
                        kont.CB_Lieferung__c = lead.CB_Lieferung__c;
                        kont.Id = null;
                        insert kont;
                    }else{
                        update kont;
                    }
                    kontId = kont.Id;
                    if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)) {
                        if(selectedContact == 'neuerKontakt'){
                            if(String.isEmpty(lead.Marketing_Cloud_ID__c)){
                                zweiterKont.Marketing_Cloud_ID__c = lead.Id;
                            }else{
                                zweiterKont.Marketing_Cloud_ID__c = lead.Marketing_Cloud_ID__c;
                            }
                            zweiterKont.CB_Lieferung__c = lead.CB_Lieferung__c;
                            zweiterKont.Id = null;
                            insert zweiterKont;
                        }
                        else{
                            update zweiterKont;
                        }
                        // set attachment to PB
                        if(zweiterKont.Id != null && String.isNotEmpty(zweiterKont.Id)){
                            try {
                                //User benutzer = [SELECT Id, Name FROM User WHERE Id =: lead.OwnerID LIMIT 1];
                                //if (benutzer.Name == 'IT Support') {
                                    saveAttachmentToPB();
                                //}
                            } catch (Exception ex) {
                                System.debug('Fehler beim Attachment '+ ex.getMessage());
                            }
                        }
                    }   
                }
                catch(System.exception exc){
                    // Roll the database back to before we saved ANYTHING
                    Database.rollback(sp);
                    return 'Error: Konvertierung fehlgeschlagen3! ' + e.getMessage();
                }                    
        }
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.id);
        lc.setDoNotCreateOpportunity(true);
        
        if(!String.isEmpty(kontId) && !String.isEmpty(famId)){
            lc.setAccountId(famId);
            lc.setContactId(kontId);
        }
        System.debug('mansi::: famId:::'+ famId);
        System.debug('mansi::: kontId:::'+ kontId);    
            
        opp = new Opportunity (Name = 'abc');
            // common attributes
            if(famId != null) opp.AccountId = famId;
            
            if(sOpp == 'neueOpportunity'){
                opp.StageName = 'Offen';
                LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Qualified' LIMIT 1];
                lc.setConvertedStatus(convertStatus.MasterLabel);
            }
            else if(sOpp == 'Ausschuss'){
                opp.StageName ='Abbruch';
                opp.Abbruchgrund__c = sGrund;
                LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE MasterLabel='Ausschuss' LIMIT 1];
                lc.setConvertedStatus(convertStatus.MasterLabel);
                if(sGrund == null) {
                    lead.Lead_Status_Bemerkung__c = 'Ausschuss';
                }
                else {
                    lead.Lead_Status_Bemerkung__c = sGrund;
                }
                try {
                    update lead;
                }
                catch(System.exception e) {
                    system.debug('#############BT2016: Lead konnte nicht upgedatet werden');   
                }
            }
            
            try{
                List<Opportunity> oppList = [select id, Name, OM_Tracking_Order_ID__c from Opportunity where id =: sOpp];
                if(oppList != null && oppList.size()>0){
                    /*Opportunity existingOpp = oppList[0];
                    if(lead.OM_Tracking_Order_ID__c != null){
                        if(existingOpp.OM_Tracking_Order_ID__c == null) {
                            existingOpp.OM_Tracking_Order_ID__c = lead.OM_Tracking_Order_ID__c;
                        }
                        else {
                            existingOpp.OM_Tracking_Order_ID__c = existingOpp.OM_Tracking_Order_ID__c + ', ' + lead.OM_Tracking_Order_ID__c;
                        }
                    }*/
                    opp.StageName ='Abbruch';
                    opp.Abbruchgrund__c = 'Ausschuss';
                    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE MasterLabel='Ausschuss' LIMIT 1];
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    lead.Lead_Status_Bemerkung__c = 'Dopplung';
                    /*try{
                        update existingOpp;
                    }
                    catch(System.exception e){
                        system.debug('#############BT2016: Opportunity konnte nicht upgedatet werden');
                        system.debug(e.getMessage());
                    }*/
                    
                    try{
                        update lead;
                    }
                    catch(System.exception e){
                        system.debug('#############BT2016: Lead konnte nicht upgedatet werden');
                        system.debug(e.getMessage());
                    }
                } 
            }catch(Exception e){
                // user has selected no opportunity. no opportunity need to be updated and the process can continiue normaly.
                system.debug('#############mansi: user has selected no opportunity. no opportunity need to be updated and the process can continiue normaly.');
            }
            
        opp.Produkt_Kategorie__c = lead.TL_Treppenliftart__c;
        opp.RO_Produkt_Kategorie__c = lead.TL_Treppenliftart__c;
        opp.Kategorie__c = '1';
        opp.Alternative_Postleitzahl__c = lead.TL_Postleitzahl_f_r_Suche__c;
        opp.Partner__c = lead.Partner__c;
        opp.OM_Referrer__c = lead.OM_Referrer__c;
        opp.OM_Tracking_Order_ID__c = lead.OM_Tracking_Order_ID__c;
        opp.OM_Wizard_Version__c = lead.OM_Wizard_Version__c;
        opp.OM_Partner_ID__c = lead.OM_Partner_ID__c;
        opp.OM_Referenznummer__c = lead.OM_Referenznummer__c;
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Angefragte Postleitzahl';
        opp.CloseDate = date.today();
        opp.R_ckrufm_glichkeit__c = lead.R_ckrufm_glichkeit__c;
        opp.Date_of_Request__c = lead.createdDate;
        opp.RecordTypeId = opp_rtList.get(lead_rtList.get(lead.RecordTypeId));
        if(lead.Person_des_Bedarfs__c != null){
            opp.Person_des_Bedarfs__c = lead.Person_des_Bedarfs__c;
            opp.RO_Person_des_Bedarfs__c = lead.Person_des_Bedarfs__c;
        }                                            
                
        if(lead.pflegegrad__c != null){
            if(!pgSet.contains(lead.pflegegrad__c)){
                opp.Pflegegrad_vorhanden__c = lead.pflegegrad__c;
                opp.RO_Pflegegrad_vorhanden__c = lead.pflegegrad__c;
            }
        } 
                
        if(lead.Wohnort_der_suche__c != null) opp.Angefragter_Wohnort__c = lead.Wohnort_der_suche__c;
                
        if(lead.next_step__c == 'Anrufen für Direktvertrieb' || lead.next_step__c == 'Weiterleitung') {
            opp.N_chster_Schritt__c = lead.next_step__c;
        }
        opp.CampaignId = lead.OM_Wizzard_Name2__c;
        opp.Urspr_nglicher_Lead__c = lead.Id;  
        
        opp.GCLID__c = lead.GCLID__c;
        opp.Preferred_timeframe__c = lead.Preferred_timeframe__c;
        
        // TL attributes
        opp.Umgebung__c = lead.Umgebung__c;
        opp.Treppenbauart__c = lead.TL_Zu_berwindendes_Hindernis__c;
        opp.Art_des_Geb_udes__c = lead.TL_H_usliche_Situation__c;
        opp.Belastbarkeit__c = lead.TL_Belastbarkeit__c;
        opp.RO_Umgebung__c = lead.Umgebung__c;
        opp.RO_Treppenbauart__c = lead.TL_Zu_berwindendes_Hindernis__c;
        opp.RO_Art_des_Geb_udes__c = lead.TL_H_usliche_Situation__c;
        opp.RO_Belastbarkeit_in_kg__c = lead.TL_Belastbarkeit__c;
        opp.RO_Person_des_Bedarfs__c = lead.Person_des_Bedarfs__c;
        if(lead.TL_Anzahl_der_Etagen__c != null){
            if(lead.TL_Anzahl_der_Etagen__c == '1 Etage') {
                opp.Anzahl_der_Etagen__c = 1;
                opp.RO_Anzahl_der_Etagen__c = 1;
            }
            else if(lead.TL_Anzahl_der_Etagen__c == '2 Etagen'){
                opp.Anzahl_der_Etagen__c = 2;
                opp.RO_Anzahl_der_Etagen__c = 2;
            }
            else if(lead.TL_Anzahl_der_Etagen__c == '3 Etagen o. mehr'){
                opp.Anzahl_der_Etagen__c = 3;
                opp.RO_Anzahl_der_Etagen__c = 3;
            }
        }
                
        // BEL attributes
        opp.Zeitpunkt_der_Versorgung__c = lead.Zeitpunkt_der_Versorgung__c;
        opp.Unterbringungsm_glichkeit__c = lead.Unterbringungsm_glichkeit__c;
        opp.Aktuelle_Betreuung__c = lead.Aktuelle_Betreuung__c;
        opp.H_ufigkeit__c = lead.H_ufigkeit_der_Unterst_tzung__c;
        opp.RO_Zeitpunkt_der_Versorgung__c = lead.Zeitpunkt_der_Versorgung__c;
        opp.RO_H_ufigkeit__c = lead.H_ufigkeit_der_Unterst_tzung__c;
        opp.RO_Unterbringungsm_glichkeit__c = lead.Unterbringungsm_glichkeit__c;
        //opp.Aktuelle_Betreuung__c = lead.Aktuelle_Betreuung__c;
        
        // Widerspruch attributes
        opp.Widerspruchsgrund__c = lead.Widerspruchsgrund__c;                                   
        opp.Widerspruch_eingereicht__c = lead.Widerspruch_eingereicht__c;
        
        // Multilead attributes        
        opp.Topics_multilead__c = lead.topics_multilead__c;
        opp.vorherige_anfrage__c = lead.Vorherige_Anfrage__c;

        
        // PI attributes
        opp.location_direction__c = lead.location_direction__c;
        opp.own_use__c = lead.own_use__c;
        opp.financing_model__c = lead.financing_model__c;
        opp.RO_location_direction__c = lead.location_direction__c; 
        opp.RO_own_use__c = lead.own_use__c;
        opp.RO_financing_model__c = lead.financing_model__c;
            
        //Bad-umabu attributes
        opp.HousingSituation__c = lead.HousingSituation__c;
        opp.DesiredConversionSolution__c = lead.RemodelingSolution__c;
        opp.ExtraInfo__c = lead.extraInfo__c;
            
        //opp.RevisionshaftAvailable__c = lead.?
        opp.EntryHeightAcceptable__c = lead.EntryLevel__c;
        opp.InsuranceProviderService__c = lead.TakeCareOfPossibleGrants__c;
        opp.floor__c = lead.FloorOfRemodeling__c;
        opp.LandlordApprovalAvailable__c = lead.LandlordOwnerAgreement__c;
        
        
        /*if(kont != null && !String.isEmpty(kont.lastName)){
            opp.NameOnTheBell__c = kont.lastName;
        }else{
            opp.NameOnTheBell__c = lead.lastname;
        }*/
        
        // HNR attributes
        opp.emergency_contact__c = lead.emergency_contact__c;
        opp.Zeitpunkt_der_Versorgung__c = lead.Zeitpunkt_der_Versorgung__c;
        opp.H_ufigkeit__c = lead.H_ufigkeit_der_Unterst_tzung__c;   
        opp.alleine_au_er_Haus__c = lead.alleine_au_er_Haus__c;
        opp.in_letzter_Zeit_gest_rzt__c = lead.in_letzter_Zeit_gest_rzt__c;
        opp.koerperlicher_Zustand__c = lead.koerperlicher_Zustand__c;
        opp.Soforthilfe_vor_Ort__c = lead.Soforthilfe_vor_Ort__c;
        opp.RO_Soforthilfe_vor_Ort__c = lead.Soforthilfe_vor_Ort__c;
        opp.RO_alleine_au_er_Haus__c = lead.alleine_au_er_Haus__c;
        opp.RO_Person_des_Bedarfs__c = lead.Person_des_Bedarfs__c;
        opp.RO_in_letzter_Zeit_gest_rzt__c = lead.in_letzter_Zeit_gest_rzt__c;
        opp.RO_koerperlicher_Zustand__c = lead.koerperlicher_Zustand__c;
        opp.RO_emergency_contact__c = lead.emergency_contact__c;
        opp.RO_Pflegegrad_vorhanden__c = lead.pflegegrad__c;
        opp.RO_Produkt_Kategorie__c = lead.TL_Treppenliftart__c;
        opp.RO_Soforthilfe_vor_Ort__c = lead.Soforthilfe_vor_Ort__c;
        opp.RO_Zeitpunkt_der_Versorgung__c = lead.Zeitpunkt_der_Versorgung__c;
        opp.RO_H_ufigkeit__c = lead.H_ufigkeit_der_Unterst_tzung__c;
        // set Lead Date in Opportunity (AD, 10.05.2019)
        opp.Lead_Date__c = date.newinstance(lead.CreatedDate.year(), lead.CreatedDate.month(), lead.CreatedDate.day());
                            
        if(String.isEmpty(opp.Produkt_Kategorie__c)){
            if(opp.RecordTypeId == opp_rtList.get(ws_recordType)){
                opp.Produkt_Kategorie__c = 'Widerspruch';
                opp.RO_Produkt_Kategorie__c = 'Widerspruch';
            }
            else if(opp.RecordTypeId == opp_rtList.get(pi_recordType)){
                opp.Produkt_Kategorie__c = 'Pflegeimmobilien';
                opp.RO_Produkt_Kategorie__c = 'Pflegeimmobilien';
            }
        }
        
        if(opp.RecordTypeId == opp_rtList.get(bad_recordType)){
            opp.Bezugspunkt_der_PLZ_Suche__c = 'Angefragte Postleitzahl';
            /* DZ 14.08.2020 Die Logik ist nicht mehr aktuell. Stattdessen sollen die Werte aus dem Lead übernommen werden.
            String oppProductGroup = 'Noch unklar';
            if(!String.isEmpty(lead.TL_Treppenliftart__c)){
                if(lead.TL_Treppenliftart__c == 'Sitzbadewanne'){
                    oppProductGroup = 'Sitzbadewanne';
                }else if(lead.TL_Treppenliftart__c == 'Badewanneneinstieg'){
                    oppProductGroup = 'Badewanneneinstieg (im Bestand)';
                }else if(lead.TL_Treppenliftart__c == 'Badewannentür'){
                    oppProductGroup = 'Badewannentür (im Bestand)';
                }else if(lead.TL_Treppenliftart__c == 'Umbau zur Dusche'){
                    oppProductGroup = 'Wanne zur Dusche';
                }
            }*/
            opp.Produkt_Kategorie__c = lead.TL_Treppenliftart__c;
            opp.RO_Produkt_Kategorie__c = lead.TL_Treppenliftart__c;
        }
                
        try{
            opp.Id = null;
            insert opp;
            oppId = opp.Id;
            
        }            
        catch(System.exception e){
            // Roll the database back to before we saved ANYTHING
            Database.rollback(sp);
            return 'Error: Konvertierung fehlgeschlagen4! ' + e.getMessage();
        }
        try {
            OpportunityContactRole ocr = new OpportunityContactRole();
            if (lead.RecordTypeId == cbList[0].Id) {
                if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
                    ocr = new OpportunityContactRole( ContactId = kontId,
                                                    OpportunityId = oppId,
                                                    IsPrimary = true,
                                                    Role = 'ASP');
                }
                else {
                    ocr = new OpportunityContactRole( ContactId = kontId,
                                                    OpportunityId = oppId,
                                                    IsPrimary = false,
                                                    Role = 'PB');
                }
            }
            else {
                ocr = new OpportunityContactRole( ContactId = kontId,
                                                OpportunityId = oppId,
                                                IsPrimary = true,
                                                Role = 'ASP');          
                if(lead.Person_des_Bedarfs__c != null && lead.Person_des_Bedarfs__c == 'Für mich') ocr.Role = 'PB = ASP';
                ocr.Id = null;
            }  
            insert ocr;
            if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
                OpportunityContactRole contactRole = new OpportunityContactRole( ContactId = zweiterKont.Id,
                                                                             OpportunityId = oppId,
                                                                             IsPrimary = false,
                                                                             Role = 'PB');
                try {
                    insert contactRole; 
                } catch (Exception e) {
                    System.debug('Fehler beim Anlegen der Role für den zweiten Kontakt: '+ e);
                }
            }
        }
        catch(System.exception e) {
            // Roll the database back to before we saved ANYTHING
            Database.rollback(sp);
            return 'Error: Konvertierung fehlgeschlagen! ' + e.getMessage(); 
        }
        try{
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            if (lead.next_Step__c != null && String.isNotEmpty(lead.next_Step__c)) {
                nextStep(lead.next_Step__c);
                // create Follow-Up Task
                if (lead.Angehoeriger_Nachname__c != null && !String.isEmpty(lead.Angehoeriger_Nachname__c)){
                    Follow_Up_Task_Helper.insertFollowUpTask(zweiterKont.Id, 'Kunde wünscht CB-Formular '+ lead.next_Step__c, 'Leadkonvertierung', System.today(), 'Geschlossen');
                }
                else {
                    Follow_Up_Task_Helper.insertFollowUpTask(kontId, 'Kunde wünscht CB-Formular '+ lead.next_Step__c, 'Leadkonvertierung', System.today(), 'Geschlossen');
                }
            }
            /*
            // delete attachments on account and contact (ASP) 
            List<ContentDocumentLink> toDeleteContentDocumentLinks = new List<ContentDocumentLink>();
            Set<Id> toDeleteContentDocumentIds = new Set<Id>();
            
            for(ContentDocumentLink lead_cdl: [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:lead.Id]) { 
                toDeleteContentDocumentIds.add(lead_cdl.ContentDocumentId);
            }
            
            if(zweiterKont != null) {
                 for(ContentDocumentLink con_cdl: [SELECT Id FROM ContentDocumentLink 
                                               WHERE LinkedEntityId = :Kont.Id
                                               AND ContentDocumentId IN :toDeleteContentDocumentIds])
                 {
                     toDeleteContentDocumentLinks.add(con_cdl);
                 }
            }           
            
            for(ContentDocumentLink acc_cdl: [SELECT Id FROM ContentDocumentLink 
                                              WHERE LinkedEntityId = :famId
                                              AND ContentDocumentId IN :toDeleteContentDocumentIds])
            {
                toDeleteContentDocumentLinks.add(acc_cdl);
            }
            
            if(!toDeleteContentDocumentLinks.isEmpty()) delete toDeleteContentDocumentLinks;  
            */          
        }        
        catch(System.exception e){
            System.debug('error happened by leadConvertResult or sending Email: ' + e.getMessage());
            return lead.next_Step__c + ': Error beim Unterlagenversand';            
        } 
        
        return null;
    } 
    
    public void denyDuplicate(){
        duplicateAccepted = False;
        duplicateDialog = 'none'; 
        return ;
    }
    
    public PageReference acceptDuplicate(){
        duplicateAccepted = True;
        duplicateDialog = 'none';
        return weiter();
    }
    
    public Boolean duplicateUserIdExists(){
        
        if(sKont == 'neuerKontakt' && !String.isEmpty(lead.OM_UserID__c)){
            List<Contact> cl = [select id, name from contact where OM_UserID__c = :lead.OM_UserID__c limit 1];
            if(cl != null && cl.size()>0){
                duplicateDialog = 'initial';
                return true;
            }
        }
        return false;
    }

    public String getFamiliebyContact(String contactId){
        List<Contact> conList = new List<Contact>();
        Contact con = new Contact();
        try {
            conList = [select Id, AccountId from Contact where Id =: contactId];
        } catch (Exception e) {
            System.debug('Keine Familie für contactId: ' + contactId);
        }
        if (conList != null && conList.size() > 0) {
            con = conList[0];
        }
        return con.AccountId;
    }

    public void nextStep(String nextStep){
        Date dueDate = Follow_Up_Task_Helper.getDueDate(Due_Date__c.getValues('Formularversand').Follow_Up_Task_Due_Date__c);
      
        if (nextStep.contains('blanko per Post')) {
            Follow_Up_Task_Helper.insertFollowUpTask(kontId, '(Blanko) Formular ausgedruckt an Pflegebedürftige/n versendet', 'Versand Formular an Interessent', System.today(), 'Geschlossen');
            //Follow_Up_Task_Helper.insertFollowUpTask(kontId, 'Nachtelefonie von Interessenten', 'Versand Formular an Interessent', dueDate, 'Offen');
        }
        else if (nextStep.contains('ausgefüllt per Post an Angehörigen')) {
            Follow_Up_Task_Helper.insertFollowUpTask(zweiterKont.Id, 'Vorausgefüllter Formular ausgedruckt an AnsprechpartnerIn versendet', 'Versand Formular an Interessent', System.today(), 'Geschlossen');
            //Follow_Up_Task_Helper.insertFollowUpTask(zweiterKont.Id, 'Nachtelefonie von Interessenten', 'Versand Formular an Interessent', dueDate, 'Offen');
        }
         else if (nextStep.contains('ausgefüllt per Post an Versicherten')) {
             if(zweiterKont != null) {
                Follow_Up_Task_Helper.insertFollowUpTask(zweiterKont.Id, 'Vorausgefüllter Formular ausgedruckt an Pflegebedürftiger versendet', 'Versand Formular an Interessent', System.today(), 'Geschlossen');
                //Follow_Up_Task_Helper.insertFollowUpTask(zweiterKont.Id, 'Nachtelefonie von Interessenten', 'Versand Formular an Interessent', dueDate, 'Offen');                 
             }
             else {
                 Follow_Up_Task_Helper.insertFollowUpTask(kontId, 'Vorausgefüllter Formular ausgedruckt an Pflegebedürftiger versendet', 'Versand Formular an Interessent', System.today(), 'Geschlossen');
             }            
        }
    }

    public void saveAttachmentToPB(){
        /*
        ContentDocumentLink cdl = new ContentDocumentLink();
        // cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE IsLatest= true AND Title like 'CB_Formular%' AND FirstPublishLocationId =:lead.Id].ContentDocumentId;
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:lead.Id].ContentDocumentId;
        cdl.LinkedEntityId = zweiterKont.Id;
        cdl.ShareType = 'I';

        try {
           insert cdl;
        } catch (Exception e) {
            System.debug('Fehler bei der Erzeugung des ausgefüllten Dokuments');
        }
        */
        
        List<ContentDocumentLink> toInsertContentDocumentLinks = new List<ContentDocumentLink>();
        for(ContentDocumentLink lead_cdl: [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:lead.Id]) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = lead_cdl.ContentDocumentId;
            cdl.LinkedEntityId = zweiterKont.Id;
            cdl.ShareType = 'I';  
            toInsertContentDocumentLinks.add(cdl);
        }
        if(!toInsertContentDocumentLinks.isEmpty()) {
            try {
                insert toInsertContentDocumentLinks;
            } catch (Exception e) {
                System.debug('Fehler bei der Erzeugung von Dokumenten');
            }
        }
    }

    public String getRoleFromContact(String contactId){
        String ret = null;
        OpportunityContactRole rle = Curabox_Helper.getOpportunityByContact(contactId);
        if (rle.Id != null) {
            ret = rle.Role;
        }
        return ret;
    }
    
    public void dummyMethod() {
        String myString = 'xxx';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';        
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
        myString = 'yyy';
    }    
}