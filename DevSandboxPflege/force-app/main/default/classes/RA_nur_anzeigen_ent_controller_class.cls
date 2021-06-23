//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//      Autor:          WDS
//      Stand:          06.12.2012
//      Version:        0.1
//      geändert:       
//      Beschreibung:   controller für RA_nur_anzeigen_ent.page 
//                                              
//
// 
//
// 
// wds       am 06.12.2012  deployed
// wds       am 11.10.2013  ACR 169 Fehler wenn Anrede = leer behoben
//
// wds       am 15.06.2014  Weitere Layoutanpassunge: Firmeninfo geholt
// wds       am 19.06.2014  Lieferadresse geholt wg. Mail von SB
// wds/ms    am 03.03.2015  Anpassungen an den Prozess von pflege.de
//
// AM       am 11.03.2015 Kein Task wenn Parameter task=notask (d.h. task wird beim mail-versand erzeugt)
// AM       am 25.03.2015 Open task für die Gruppe 'Nachtelefonie'
// WDS      am 29.04.2015 Anschreiben soll an Kunde oder Angehöriger gehen
// 04.05.2015 von AM:   Sollte keine StandardLieferadresse gekennzeichtet wird die Strasse aus Hauptanschrift genommen. 
// 07.08.2015 von wds   Ort aus Anschrift beim Betreuer übernehmen! Fehler: er nimmt dem Ort vom Kunden!
// 02.09.2015 von AM:   Einbau recordtype für Task       
// 03.09.2015 von BT    Einbau Task Nachtelefonie Inko-Formular
// 10.11.2015 von MZ    formatPLZ and addr.Anredeformelsetzen replaced by ksgFunctions.formatPLZ and ksgFunctions.addr.Anredeformelsetzen
// 11.01.2016 von BT    Einbau Tasks 'Formular vorausgefüllt gedruckt'
// 19.01.2016 von AM    #97879944 Einbau CC
// 10.02.2016 von AM    #97879944 Erweiterung der kdAddr um kdnachname, kdvorname
// 24.03.2016 von BT    Löschen von CC
// 31.05.2016 von AM    Task werden doppelt angelegt. Das passiert nur bei MS Edfe / IE. Die beide browsers senden beim Verarbeiten
//                      von VF_Page "action" den zweiten kompletten request der Seite. 
//                      Lösung: beim task Anlegen wird zunächst geprüft ob innerhalb von 5 sek (?) den gleichen 
//                      tas bereits existiert. Wenn ja soll keine gleiche tasks geschriben werden.
// 05.10.2016 von BT    Es wird keine "Nachtelefonie von Interessenten" mehr eingerichtet, wenn sowohl Kunde als auch Angehöriger 
//                                                                      keine Telefonnummer hintergelegt haben.
// 25.10.2016 von wds   Erweiterung um Mobilfunknr bzgl NT-Anlage
// 03.07.2018 MS  #1576 Added property AGB used in VF-Page Anschreiben_Formular_Neu
// 27.10.2018 MS  #1753 Added property gesetzlich, used in VF-Page Curabox_Empfangsschreiben
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public with sharing class RA_nur_anzeigen_ent_controller_class {
    private Id Kunde_id, KK_id;
    private final Kunde__c Kunde;
    private final Anschrift__c Anschrift;
    private final Account KK;
    public id KdID = null;
    private static set<String> ids = new set<String>{};
    public string Anredeformel {get; set;}
    public string Anrede = ' ';
    public string PLZ_Ort = '';
    public CompanyInfo__c FirmenInfo {get; set;}
    
    public string AGB {get; set;}

    private string retPage = ApexPages.currentPage().getParameters().get('retURL');
    private ID rcpt = ApexPages.currentPage().getParameters().get('rcpt');
    public string notask = ApexPages.currentPage().getParameters().get('task');

    public string subject {get; set;}
    public string empfaenger {get; set;}   
    
    // ms 27.10.18
    public boolean gesetzlich {get; set;}
 
    public ksgFunctions.addr kdAddr = new ksgFunctions.addr();

    public ksgFunctions.addr kdAddrD = new ksgFunctions.addr();
    
    public RA_nur_anzeigen_ent_controller_class(integer dummy) {
    }

    public RA_nur_anzeigen_ent_controller_class() {
            this(ApexPages.currentPage().getParameters().get('id'));
    }
        
    public RA_nur_anzeigen_ent_controller_class(String Kunde_id) { 
    
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
        sObjSH = Kunde__c.sObjectType.getDescribe();
        string kunKeyPrefix = sObjSH.getKeyPrefix(); 
        
        String strurl = ApexPages.currentPage().getUrl();
        KdID = id.valueOf(Kunde_id);
            
        if(strurl.contains('Anschreiben_Formular_Neu')) 
            subject = 'Formular';
        if(strurl.contains('Anschreiben_formular_inko_neu')) 
            subject = 'Formular_inko';
        if(strurl.contains('RA_nur_anzeigen_ent') || strurl.contains('Curabox_Empfangsschreiben')) //ms 27.10.18, RA_nur_anzeigen_ent-part actually obsolet (?)
            subject = 'Eingangsbestätigung';    
        if(strurl.contains('Anschreiben_CB_Assistent')) 
            subject = 'Formular vorausgefüllt';        
        
        
        system.debug ('#######################alex200 subject=' + subject);
        system.debug ('#######################alex101 conKeyPrefix=' + rcpt);
        system.debug ('#######################alex101 string.valueOf(rcpt).substring(0, 3)=' + string.valueOf(rcpt).substring(0, 3));
        
        
        Kunde = [SELECT Name, Anrede__c, Vorname__c, Name__c, 
                        Versichertennummer__c, 
                        Krankenkasse__c, komb_Adresse__c, komb_name__c,
                        Ort__c, PLZ__c, Stra_e__c, Hausnummer__c,
                        Kundennummer__c, Kundennummer_abena__c, Krankenkasse__r.Name,
                 		Krankenkasse__r.Kanal_Unterpunkt__c //ms 27.10.18
                    FROM Kunde__c 
                    WHERE ID = :Kunde_id];
        Anrede = Kunde.Anrede__c;
        System.debug ('Kundeninfos name:   '+kunde.name);
        System.debug ('Kundeninfos name__c:   '+kunde.name__c);
        kdAddr.kdvorname = Kunde.Vorname__c;
        kdAddr.kdnachname = Kunde.Name__c;
        
        // ms 27.10.18, assuming that if Krankenkasse is not privat, it is gesetzlich
        if(Kunde.Krankenkasse__r.Kanal_Unterpunkt__c == 'privat'){
            gesetzlich = false;
        } else {
            gesetzlich = true;
        }
            
        if(string.valueOf(rcpt).substring(0, 3) == accKeyPrefix) {
            system.debug ('#######################alex100 accKeyPrefix=' + rcpt);
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
            system.debug ('#######################alex101 conKeyPrefix=' + rcpt);
            Contact con = [SELECT Name, lastname, firstname, Salutation FROM Contact WHERE ID = :rcpt LIMIT 1];
            if(con != null) {
                kdAddr.vorname_name = con.Name;
                system.debug ('#######################alex301 con.Name=' + con.Name);
                list <Anschrift__c> ansch = [SELECT Stra_e__c, PLZ__c, Ort__c, Anrede__c
                                        FROM Anschrift__c
                                        WHERE Kunde__c = :Kunde_id 
                                    //    AND Name = :con.Name
                                        AND Art_der_Anschrift__c IN  ('Betreuer', 'Angehöriger')
                                        LIMIT 1];
                if((ansch != null) && (ansch.size() > 0)){
                    kdAddr.strasse = ansch[0].Stra_e__c;
                    kdAddr.plz_ort = ansch[0].PLZ__c + ' ' + Ansch[0].Ort__c;
                    kdaddr.anrede = ansch[0].Anrede__c;
                    kdAddr.vorname_name = (con.firstname + ' ' + con.lastname).trim();
                    kdAddr.nachname = con.lastname;
                }
                if(kdaddr.anrede == null){
                    kdaddr.anrede = con.Salutation;
                }
            }
            empfaenger = 'Angehöriger';
           
            
        }

        if(string.valueOf(rcpt).substring(0, 3) == kunKeyPrefix) {
            system.debug ('#######################alex102 kunKeyPrefix=' + rcpt);
            kdAddr.anrede = Kunde.Anrede__c;
            kdAddr.vorname_name = (Kunde.vorname__c + ' ' + Kunde.Name__c).trim();
            kdAddr.strasse = Kunde.Stra_e__c;
            kdAddr.plz_ort = ksgFunctions.formatPLZ(Kunde.PLZ__c) + ' ' + Kunde.Ort__c;
            kdAddr.nachname = Kunde.Name__c;
            empfaenger = 'Kunde';
        }
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

        
        Anredeformel = kdAddr.Anredeformelsetzen(); 
        system.debug('#########################alex001 CC=' + kdAddrD);
        // ende CC      

        
        list<Anschrift__c>  kdAnsch = [SELECT Stra_e__c
                                        FROM Anschrift__c 
                                        WHERE Kunde__c = :Kunde_id 
                                        AND Standardlieferanschrift__c=:true LIMIT 1] ;     
        if((kdAnsch != null) && (kdAnsch.size() > 0)) {     
            Anschrift = kdAnsch[0];
        }
        else {
            Anschrift = new Anschrift__c(Stra_e__c = kdAddr.strasse); 
        }
        
        

        
        if (subject == 'Formular_inko' ) {
        FirmenInfo = CompanyInfo__c.getValues('Inko');}
        Else {
        FirmenInfo = CompanyInfo__c.getValues('Default');}
        if (FirmenInfo != null) {
            if(FirmenInfo.GF__c.contains(', ')){
                String[] GF = FirmenInfo.GF__c.split(', ',2);
                FirmenInfo.GF__c = GF[0] + '<br />'+GF[1];
            }
        }
        // addTask();
    }
    
    public void addTask(){
        id rtid = null;  
        id rtid_inko = null;                              
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'PG54'];
        list<RecordType> rtInkoList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'INKO'];
        
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        
        if((rtInkoList != null) && (rtInkoList.size() > 0)) {
            rtId_inko = rtInkoList[0].id;
        }    
             
        system.debug('#########################alex210 subject=' + subject + ' notask=' + notask);
        // TaskStatus ts = [SELECT MasterLabel FROM TaskStatus WHERE IsClosed = true];
        
        // Prüfung wegen MS Edge / MS IE
        list<task> existTask = [SELECT id, createddate FROM task 
                                    WHERE ActivityDate = :Date.today()
                                    AND Priority = 'Normal'
                                    AND Status = 'Geschlossen'
                                    AND Subject = :subject + ' gedruckt'
                                    AND WhatId = :KdId
                                    AND RecordTypeId IN ( :rtid, :rtId_inko)
                                    ORDER BY createddate DESC
                                    LIMIT 1];
        if((existTask != null) && (existTask.size() > 0)) {
            if(existTask[0].createddate.addSeconds(5) > datetime.now()) notask = 'notask';
        }       
        
        
        
        if(notask != 'notask') {                     
          //if(subject == 'Formular' || subject.contains('Formular')) {
          if(subject == 'Formular' || subject == 'Formular vorausgefüllt') { 
             task newTask = new Task(ActivityDate = Date.today(),
                                    Description =  subject + ' gedruckt. Empfänger ' + empfaenger,      
                                    Priority = 'Normal',
                                    Status = 'Geschlossen',
                                    Subject = subject + ' gedruckt',            
                                    WhatId = KdId,
                                    RecordTypeId = rtid,
                                    IsReminderSet = false
                                       );
             // Insert the new Task
             system.debug('#########################alex211 task=' + newTask);
             try {
                insert newTask;
             }
             catch (system.exception e) {
                system.debug('#########################alex212 insert task error=' + e);
                
             }
             
             List<Kunde__c> kdList = [select id, 
                                             Telefon__c,
                                             Mobil__c,
                                             Betreuer__c, 
                                             Betreuer__r.Phone,
                                             Betreuer__r.mobilePhone
                                      from Kunde__c
                                      where id =: KdID
                                      limit 1];
             if( kdList[0].Telefon__c != null || 
                 kdList[0].mobil__c != null  || 
                 kdList[0].Betreuer__r.Phone != null ||  
                 kdList[0].Betreuer__r.mobilephone != null) {
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
             
            if(subject == 'Formular_inko') { 
             task newTask = new Task(ActivityDate = Date.today(),
                                    Description =  subject + ' gedruckt. Empfänger ' + empfaenger,      
                                    Priority = 'Normal',
                                    Status = 'Geschlossen',
                                    Subject = subject + ' gedruckt',            
                                    WhatId = KdId,
                                    RecordTypeId = rtid_inko,
                                    IsReminderSet = false
                                       );
             // Insert the new Task
             system.debug('#########################alex211 task=' + newTask);
             try {
                insert newTask;
             }
             catch (system.exception e) {
                system.debug('#########################alex212 insert task error=' + e);
                
             }
                id grID = UserInfo.getUserId(); 
                list<Group> grList = [SELECT id FROM Group WHERE Name = 'INKO' LIMIT 1];
                if((grList != null) && (grList.size() > 0)) {   
                    grID = grList[0].id;
                }
                list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                                FROM GroupMember WHERE GroupId = : grID];
                list<task> tsList = new list<task>();
                if((gmList != null) && (gmList.size() > 0)) { 
                    for(GroupMember GM : gmList) {
                        Task t = new Task(ActivityDate = Date.today().addDays(7),
                                            Subject='Nachtelefonie Inko-Formular',
                                            WhatId = KdID,
                                            OwnerId = GM.UserOrGroupId,
                                            IsReminderSet = true,
                                            ReminderDateTime = System.now()+7,                                     
                                            Description = 'Nachtelefonie Inko-Formular',  
                                            RecordTypeId = rtid_inko,
                                            Status='Open');
                        tsList.add(t);
                    }
                }
                else {
                        Task t = new Task(ActivityDate = Date.today().addDays(7),
                                            Subject='Nachtelefonie Inko-Formular',
                                            WhatId = KdID,
                                            OwnerId = UserInfo.getUserId(),
                                            IsReminderSet = true,
                                            ReminderDateTime = System.now()+7,                                     
                                            Description = 'Nachtelefonie Inko-Formular',         
                                            RecordTypeId = rtid_inko,
                                            Status='Open');
                        tsList.add(t);                  
                }
                insert tsList;       
             } 
        }
    }
        
    public Kunde__c getKunde()
    {
    system.debug ('## wds Kunde: ' + Kunde);
        return Kunde;
    }
    public Anschrift__c getAnschrift()
    {       
        return Anschrift;
    } 
    
    public Account getKK() 
    {
        system.debug ('## wds Krankenkasse: ' + KK);
        return KK;
    }  
    
    public String getAnredeformel()
    {
    system.debug ('Anredeformel ' + Anredeformel);
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
}