/****************************************************************************************************************************
// Created 24.07.2019 von  AD
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
//
//****************************************************************************************************************************
//
// Description:       
// This class generate contacts data from clients
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global class Curabox_Generate_Contact_From_Client implements Database.Batchable<sObject>, Database.Stateful {

    public static List<Delivery_Line__c> deliveryLineList {get; set;}
    public static List<Contact_Status__c> contactStatusList {get; set;}
    public static List<Follow_up_Task__c> followUpTaskList {get; set;}
    public static List<Task> taskList {get; set;}
    public static List<Curabox_Genehmigungsposition__c> curaboxGenehmigungPositionList {get; set;}
    public static Map<String, Product__c> productMap {get; set;}
    public static Map<String, curabox__c> curaboxMap {get; set;}
    public static Map<String, Product_Group__c> productGroupMap {get; set;}
    global String failedKundeList = '';
    global Integer successCounter = 0;
    public static String recordType = '';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Anrede__c, Vorname__c, Name__c, e_mail__c, Geburtsdatum__c, Geburtsdatum_text__c, Kundennummer__c, Suchfeld_Kundennr__c, Telefon__c, Mobil__c, Ort__c, PLZ__c, PLZA__c, ' +
                    'Stra_e__c, Hausnummer__c, Fax__c, Beihilfeberechtigt__c, Versichertennummer__c, Krankenkasse__c, IK_Nummer_des_Tr_gers__c, Pflegegrad__c, Versichertenstatus__c, ' +
                    'Betreuer__c, Pflegedienst__c, Status__c, Vorherige_Anfrage__c, Tracking_Order_ID__c, Antrag_bewilligt_abgelehnt_am__c, Abbestellungsdatum__c, Pflegestufe__c, ' + 
                    'Zuzahlungsbefreit_Nein__c, Status_PG51__c, Status_PG54__c, Ursprungsanfrage__c, Lead__c, Next_step__c, Wunschbox__r.Name, AGB_alt__c, AGB_neu__c, Notizen__c,' +
                    'bevorzugter_Art_f_r_Einmalhandsch__r.Name, isToContactConverted__c, createdDate, Email_Opt_Out__c, Pflegegrad_seit__c, OM_UserID__c, aktueller_OP__c ' +
            ' FROM Kunde__c WHERE isToContactConverted__c != true'
        );
    }

    global void execute(Database.BatchableContext bc, List<Kunde__c> kundenList){
        deliveryLineList = new List<Delivery_Line__c>();
        contactStatusList = new List<Contact_Status__c>();
        followUpTaskList = new List<Follow_up_Task__c>();
        taskList = new List<Task>();
        getAllCuraboxes();
        getAllProduct();
        getAllProductGroup();
        curaboxGenehmigungPositionList = new List<Curabox_Genehmigungsposition__c>();
        if (kundenList != null && kundenList.size() > 0) {
            for (Kunde__c kunde : kundenList) {
                convertClientToContact(kunde);
            }
            // insert Bedarfe
            if (deliveryLineList != null && deliveryLineList.size() > 0) {
                try {
                    insert deliveryLineList; 
                } catch (Exception e) {
                    System.debug('Fehler beim Anlegen der Bedarfe: ' + e);
                }
            }
            // insert Genehmigungspositionen
            if (curaboxGenehmigungPositionList != null && curaboxGenehmigungPositionList.size() > 0) {
                try {
                    insert curaboxGenehmigungPositionList;
                } catch (Exception e) {
                    System.debug('Fehler bei den Genehmigungspositionen: '+ e);
                }
            }
            // insert contact status
            if (contactStatusList != null && contactStatusList.size() > 0) {
                try {
                    insert contactStatusList;
                } catch (Exception e) {
                    System.debug('Contact status error: '+ e);
                }  
            }
            // insert Follow-Up Tasks
            if (followUpTaskList != null && followUpTaskList.size() > 0) {
                try {
                    insert followUpTaskList;
                } catch (Exception e) {
                    System.debug('Follow-Up Task: ' +e);
                }   
            }
        }
    }

    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
            // send email to system admin
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setSaveAsActivity(true);
        mail.setSubject('Datenübernahmeprogramm ist gelaufen. Anzahl der konvertierten Kunden: '+ successCounter);
        mail.setPlainTextBody(failedKundeList);
        mail.setHtmlBody(failedKundeList);
        String email = 'kontakt@klosesrockepartner.de';
        String[] toAddress = new String[] {email};
        mail.setToAddresses(toAddress);
       
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
        } catch (Exception e) {
            System.debug('Datenübernahme Error: ' + e.getMessage());
        }       
    }

    public void convertClientToContact(Kunde__c client){
        Account familie = createNewFamilie(client);
        Savepoint sp = Database.setSavepoint();
        if (familie.Id != null && String.isNotEmpty(familie.Id)) {
            familie = familie;
        }
        else{
            try {
                insert familie;
            } catch (Exception e) {
                failedKundeList = failedKundeList + client.Id +' '+e.getMessage()+ ';  ';
                Database.rollback(sp);
                System.debug('Fehler beim Insert Familie: ' + client.Id);
            }
        }
        if (familie.Id != null && !String.isEmpty(familie.Id)) {
            System.debug('#####################  Fam Alex D ######################');
            Contact contact = createNewContact(client, familie);
            try {
                insert contact;
            } catch (Exception e) {
                failedKundeList = failedKundeList + client.Id +' '+e.getMessage()+ ';  ';
                Database.rollback(sp);
                System.debug('Contact:' +e);
            }
            // insert Opportunity
            if (contact.Id != null && String.isNotEmpty(contact.Id)) {
                String contactId = contact.Id;
                System.debug('#####################  Con Alex D ######################');
                try {
                    updateFamilieASP(contact);
                } catch (Exception e) {
                    failedKundeList = failedKundeList + client.Id +' '+e.getMessage()+ ';  ';
                    Database.rollback(sp);
                    System.debug('Update ASP: ' +e);
                }
                // create Opportunity
                String oppStatus = checkOpportunity(client);
                if (oppStatus != null && String.isNotEmpty(oppStatus)) {
                    Opportunity opportunity = createNewOpportunity(contact, oppStatus, client);
                    try {
                        insert opportunity;
                    } catch (Exception e) {
                        failedKundeList = failedKundeList + client.Id +' '+e.getMessage()+ ';  ';
                        Database.rollback(sp);
                        System.debug('opportunity: ' +e);
                    }
                    // insert Contact Role
                    if (opportunity.Id != null && !String.isEmpty(opportunity.Id)) {
                        System.debug('#####################  Role Alex D ######################');
                        Boolean isOrder = createOrders(contactId, client, opportunity, sp);
                        if (isOrder != true) {
                            failedKundeList = failedKundeList + client.Id + 'Auftrag;  ';
                            Database.rollback(sp);
                        }
                        Boolean isGenehmigung = createGenehmigungen(contactId, client, sp);
                        if (isGenehmigung != true) {
                            failedKundeList = failedKundeList + client.Id + 'Genehmigung;  ';
                            Database.rollback(sp);
                        }
                        List<OpportunityContactRole> roleList = newContactRole(contact, opportunity);
                        try {
                            insert roleList;
                            updateClientAfterConvert(client);
                            successCounter = successCounter + 1;
                        } catch (Exception e) {
                            failedKundeList = failedKundeList + client.Id +' '+e.getMessage()+ ';  ';
                            Database.rollback(sp);
                            System.debug('ContactRole: ' +e.getCause());
                        }
                        // insert Follow-Up-Tasks and Tasks
                        List<Task> clientTaskList = getTaskByClient(client);
                        if (clientTaskList != null && clientTaskList.size()>0) {
                            for (Task task : clientTaskList) {
                                followUpTaskList.add(createFollowUpTask(contactId, task, opportunity));
                            }
                        }
                    }
                }
                // insert Kundenstatus
                List<Kundenstatus__c> kStatusList = getContactStatusList(client);
                if (kStatusList != null && kStatusList.size() > 0) {
                    for (Kundenstatus__c kStatus : kStatusList) {
                        contactStatusList.add(newContactStatus(contactId, kStatus));
                    }
                }
            }
            else {
                System.debug('No contact was created: '+client);
                Database.rollback(sp);
            }
        }else {
            Database.rollback(sp);
        }
    }

    public static String checkOpportunity(Kunde__c client){
        String oppStatus = '';
        if  (   (client.Status_PG54__c == 'Kunde' || client.Status_PG51__c == 'Kunde') || 
                (client.Status_PG54__c == 'Kündigung' || client.Status_PG51__c == 'Kündigung') ||
                (client.Status_PG54__c == 'Kandidat' || client.Status_PG51__c == 'Kandidat')
            ) {
            oppStatus = 'Closed Won';
        }
        else if (   (client.Status_PG54__c == 'Interessent' && client.Status_PG51__c == 'Interessent') ||
                    (client.Status_PG54__c == 'Interessent' && client.Status_PG51__c == 'Vorgang geschlossen') ||
                    (client.Status_PG54__c == 'Vorgang geschlossen' && client.Status_PG51__c == 'Interessent') ||
                    (client.Status_PG54__c == 'Interessent' && client.Status_PG51__c == null) ||
                    (client.Status_PG54__c == null && client.Status_PG51__c == 'Interessent')
                ) {
            oppStatus = 'Open';
        }
        else if (   (client.Status_PG54__c == 'Vorgang geschlossen' && client.Status_PG51__c == 'Vorgang geschlossen') ||
                    (client.Status_PG54__c == 'Vorgang geschlossen' && client.Status_PG51__c == 'Formular unerwünscht') ||    
                    (client.Status_PG54__c == 'Vorgang geschlossen' && client.Status_PG51__c == null) ||
                    (client.Status_PG54__c == null && client.Status_PG51__c == 'Vorgang geschlossen') 
                ) {
            oppStatus = 'Closed Lost';
        }
        else if (   (client.Status_PG54__c == 'Formular unerwünscht' && client.Status_PG51__c == 'Formular unerwünscht') ||
                    (client.Status_PG54__c == 'Formular unerwünscht' && client.Status_PG51__c == 'Vorgang geschlossen') ||    
                    (client.Status_PG54__c == 'Formular unerwünscht' && client.Status_PG51__c == null) ||
                    (client.Status_PG54__c == null && client.Status_PG51__c == 'Formular unerwünscht') 
                ) {
            oppStatus = 'Closed Lost';
        }
        else {
            oppStatus = null;
        }

        return oppStatus;
    }

    public static Contact createNewContact(Kunde__c client, Account familie){
        Contact contact = new Contact();
        List<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name ='Familienangehörige' and sObjectType = 'Contact'];
        recordType = rtList[0].Id;
        contact.RecordTypeId = rtList[0].Id;
        contact.Salutation = client.Anrede__c;
        contact.FirstName = client.Vorname__c;
        contact.LastName = client.Name__c;
        contact.Email = client.e_mail__c;
        contact.HasOptedOutOfEmail = client.Email_Opt_Out__c;
        contact.OM_UserID__c = client.OM_UserID__c;
        contact.Fax = client.Fax__c;
        contact.businessCreatedDate__c = client.CreatedDate;
        if(client.Geburtsdatum_text__c != null && String.isNotEmpty(client.Geburtsdatum_text__c)){
            try {
                String[] str = client.Geburtsdatum_text__c.replace('.', '-').split('-', 3);
                Integer tag = Integer.valueOf(str[0]);
                Integer monat =Integer.valueOf(str[1]);
                Integer jahr = Integer.valueOf(str[2]);
                if (jahr > 1919) {
                    contact.Birthdate = Date.newInstance(jahr, monat, tag);
                    contact.Geburtsjahr__c = jahr;
                }
            } catch (Exception e) {
                System.debug('Birthday error: ' + e.getMessage());
            }
        }
        else if (client.Geburtsdatum__c != null) {
            contact.Birthdate = client.Geburtsdatum__c;
        }
        // kunde referenz
        contact.Kundennummer__c = client.Kundennummer__c;
        contact.Kunde_Id__c = client.Id;
        contact.AGB_neu__c = client.AGB_neu__c;
        contact.AGB_alt__c = client.AGB_alt__c;
        contact.Suchfeld_KundenNr__c = client.Suchfeld_Kundennr__c;
        // Familie zuweisen
        contact.AccountId = familie.Id;
        // Kontaktdaten
        contact.Art_des_Kontakts__c = 'Pflegebedürftige(r)';
        contact.Phone = client.Telefon__c;
        contact.MobilePhone = client.Mobil__c;
        contact.MailingCity = client.Ort__c;
        contact.MailingPostalCode = String.valueOf(client.PLZA__c);
        contact.MailingStreet = client.Stra_e__c;
        // Versichertendaten
        contact.Beihilfeberechtigt__c = client.Beihilfeberechtigt__c;
        contact.Pflegestufe__c = client.Pflegestufe__c;
        if(client.Pflegegrad_seit__c != null && String.isNotEmpty(client.Pflegegrad_seit__c)) contact.Pflegegrad_seit__c = client.Pflegegrad_seit__c;
        if (client.Versichertennummer__c != null && String.isNotEmpty(client.Versichertennummer__c)) contact.Versicherungsnummer__c = client.Versichertennummer__c;
        if (client.Krankenkasse__c != null && String.isNotEmpty(client.Krankenkasse__c)) contact.Kranken_Pflegekasse__c = client.Krankenkasse__c;
        if (client.IK_Nummer_des_Tr_gers__c != null) contact.IK_Nummer_des_Tr_gers__c = String.valueOf(client.IK_Nummer_des_Tr_gers__c);
        if (client.Pflegegrad__c != null && String.isNotEmpty(client.Pflegegrad__c)) contact.Pflegegrad__c = client.Pflegegrad__c;
        if (client.Versichertenstatus__c != null && String.isNotEmpty(client.Versichertenstatus__c)) contact.Versichertenstatus__c = client.Versichertenstatus__c;
        //
        if (client.Betreuer__c != null && String.isNotEmpty(client.Betreuer__c)) contact.Betreuer__c = client.Betreuer__c;
        if (client.Pflegedienst__c != null && String.isNotEmpty(client.Pflegedienst__c)) contact.Pflegedienst__c = client.Pflegedienst__c;
        if (client.Status__c != null && String.isNotEmpty(client.Status__c)) contact.Status__c = client.Status__c;
        if (client.Vorherige_Anfrage__c != null && String.isNotEmpty(client.Vorherige_Anfrage__c)) contact.Vorherige_Anfrage__c = client.Vorherige_Anfrage__c;
        if (client.Tracking_Order_ID__c != null && String.isNotEmpty(client.Tracking_Order_ID__c)) contact.Tracking_Order_ID__c = client.Tracking_Order_ID__c;
        if (client.Antrag_bewilligt_abgelehnt_am__c != null) contact.XXX_Antrag_bewilligt_abgelehnt_am__c = client.Antrag_bewilligt_abgelehnt_am__c;
        if (client.Abbestellungsdatum__c != null) contact.XXX_K_ndigung_am__c = client.Abbestellungsdatum__c;
        if (client.Zuzahlungsbefreit_Nein__c != null) contact.Zuzahlungsbefreit_Nein__c = client.Zuzahlungsbefreit_Nein__c;
        if (client.Status_PG51__c != null && String.isNotEmpty(client.Status_PG51__c)) contact.Status_PG51__c = client.Status_PG51__c;
        if (client.Status_PG54__c != null && String.isNotEmpty(client.Status_PG54__c)) contact.Status_PG54__c = client.Status_PG54__c;
        // Kampagne zuweisen
        if (client.Ursprungsanfrage__c != null && String.isNotEmpty(client.Ursprungsanfrage__c)) contact.Ursprungsanfrage__c = client.Ursprungsanfrage__c;
        //
        if (client.Lead__c != null && String.isNotEmpty(client.Lead__c)) contact.Lead__c = client.Lead__c;
        if (client.Next_step__c != null && String.isNotEmpty(client.Next_step__c)) contact.N_chster_Schritt__c = client.Next_step__c;
        // Wunschbox
        if (client.Wunschbox__r.Name != null && String.isNotEmpty(client.Wunschbox__r.Name)) {
            curabox__c curabox = curaboxMap.get(client.Wunschbox__r.Name);
            if (curabox.Id != null && String.isNotEmpty(curabox.Id)) {
                contact.Wunschbox__c = curabox.Id;
            }
        }
        // Wunschhandschuhe
        if (client.bevorzugter_Art_f_r_Einmalhandsch__r.Name != null && String.isNotEmpty(client.bevorzugter_Art_f_r_Einmalhandsch__r.Name)) {
            Product__c product = productMap.get(client.bevorzugter_Art_f_r_Einmalhandsch__r.Name);
            if (product.Id != null && String.isNotEmpty(product.Id)) {
                contact.Art_Von_Handschuhe__c = product.Id;
            }
        }
        //
        contact.Description = client.Notizen__c;

        return contact;
    }

    public static Contact_Status__c newContactStatus(String contactId, Kundenstatus__c kStatus){
        Contact_Status__c conStatus = new Contact_Status__c();
        conStatus.Contact__c = contactId;
        conStatus.Ursprungsanfrage__c = kStatus.Ursprungsanfrage__c;
        if(kStatus.Antrag_bewilligt_abgelehnt_am__c != null) conStatus.Antrag_bewilligt_abgelehnt_am__c = kStatus.Antrag_bewilligt_abgelehnt_am__c;
        if(kStatus.Antrag_eingegangen_am__c != null) conStatus.Antrag_eingegangen_am__c = kStatus.Antrag_eingegangen_am__c;
        if(kStatus.CRM_Ticket_ID__c != null) conStatus.CRM_Ticket_ID__c = kStatus.CRM_Ticket_ID__c;
        if(kStatus.K_ndigungsbemerkung__c != null) conStatus.K_ndigungsbemerkung__c = kStatus.K_ndigungsbemerkung__c;
        if(kStatus.K_ndigungsdatum__c != null) conStatus.K_ndigungsdatum__c = kStatus.K_ndigungsdatum__c;
        if(kStatus.K_ndigungsgrund__c != null) conStatus.K_ndigungsgrund__c = kStatus.K_ndigungsgrund__c;
        if(kStatus.Anzahl_Erinnerung_Email__c != null) conStatus.Number_Reminder_Email__c = kStatus.Anzahl_Erinnerung_Email__c;
        if(kStatus.Partner_ID__c != null) conStatus.Partner_ID__c = kStatus.Partner_ID__c;
        if(kStatus.Produktgruppe__c != null) conStatus.Productgroup__c = kStatus.Produktgruppe__c;
        if(kStatus.Referrer__c != null) conStatus.Referrer__c = kStatus.Referrer__c;
        if(kStatus.Status__c != null) conStatus.Status__c = kStatus.Status__c;
        if(kStatus.Tracking_Order_ID__c != null) conStatus.Tracking_Order_ID__c = kStatus.Tracking_Order_ID__c;
        if(kStatus.Wizard_Version__c != null) conStatus.Wizard_Version__c = kStatus.Wizard_Version__c;

        return conStatus;
    }

    public static Follow_up_Task__c createFollowUpTask(String contactId, Task task, Opportunity opp){
        Follow_up_Task__c fUpTask = new Follow_up_Task__c();
        fUpTask.Contact__c = contactId;
        String description = String.valueOf(task.Description);
        if (description != null && String.isNotEmpty(description)) {
            if (description.length() < 131070) {
                fUpTask.Description__c = task.Description;
            }
            else {
                fUpTask.Description__c = task.Description.Substring(0, 131070);
            }
        }
        fUpTask.Due_Date__c = task.ActivityDate;
        //fUpTask.OwnerId = task.OwnerId;
        fUpTask.Status__c = task.Status;
        fUpTask.Subject__c = task.Subject;
        fUpTask.Opportunity__c = opp.Id;

        return fUpTask;
    }

    public static Account createNewFamilie(Kunde__c client){
        List<RecordType> recordTypeList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];
        Account familie = new Account();
        if(recordTypeList != null && recordTypeList.size() > 0) { 
            familie.RecordTypeId = recordTypeList[0].Id;
            if (client.Betreuer__c != null && String.isNotEmpty(client.Betreuer__c)){
                Contact asp = getAspByClient(client.Betreuer__c);
                if (asp.Account != null && asp.Account.Name != 'ASP für Kunden') {
                    familie = getGlobalFamilie(asp);
                }
                else {
                    familie.Name = asp.LastName;
                    familie.Familien_Name__c = asp.LastName;
                    familie.businessCreatedDate__c = asp.CreatedDate;   
                }
            }
            else{
                familie.Name = client.Name__c;
                familie.Familien_Name__c = client.Name__c;
                familie.businessCreatedDate__c = client.CreatedDate;
            }
        }
        else {
            system.debug('Es wurde kein Recordtype für Familien gefunden!');
        }
        return familie;                             
    }

    public static Opportunity createNewOpportunity(Contact contact, String oppStatus, Kunde__c client){
        Opportunity opportunity = new Opportunity();
        List<RecordType> recordTypList = [SELECT Id, sObjectType FROM RecordType WHERE Name = 'Curabox' and sObjectType = 'Opportunity'];
        opportunity.StageName = oppStatus;
        opportunity.Amount = client.aktueller_OP__c;
        opportunity.AccountId = contact.AccountId;
        opportunity.Business_CreatedDate__c = client.CreatedDate;
        opportunity.CloseDate = Date.newInstance(client.CreatedDate.year(), client.CreatedDate.month(), client.CreatedDate.day());
        opportunity.Name = 'kunde_uebernahme';
        if (contact.Ursprungsanfrage__c != null && !String.isEmpty(contact.Ursprungsanfrage__c)) {
            opportunity.CampaignId = contact.Ursprungsanfrage__c;
        }
        if (oppStatus == 'Closed Won') {
            opportunity.Amount = 900;
            opportunity.plannedAmount__c = 900;
        }
        opportunity.RecordTypeId = recordTypList[0].Id;
        opportunity.Urspr_nglicher_Lead__c = contact.Lead__c;

        return opportunity;
    }

    public static List<OpportunityContactRole> newContactRole(Contact contact, Opportunity opportunity){
        List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();
        OpportunityContactRole oppContactRolePB = new OpportunityContactRole();
        oppContactRolePB.Role = 'PB';
        oppContactRolePB.ContactId = contact.Id;
        oppContactRolePB.OpportunityId = opportunity.Id;
        if (contact.Betreuer__c != null && String.isNotEmpty(contact.Betreuer__c)) {
            OpportunityContactRole oppContactRoleAsp = new OpportunityContactRole();
            oppContactRoleAsp.Role = 'ASP';
            oppContactRoleAsp.IsPrimary = true;
            oppContactRoleAsp.ContactId = contact.Betreuer__c;
            oppContactRoleAsp.OpportunityId = opportunity.Id;
            oppContactRoleList.add(oppContactRoleAsp);
        }
        else {
            oppContactRolePB.IsPrimary = true;
        }
        oppContactRoleList.add(oppContactRolePB);
        return oppContactRoleList;
    }
    
    public static Boolean createOrders(String contactId, Kunde__c client, Opportunity opp, Savepoint sp){
        List<Auftrag__c> auftragList = getOrdersByClient(client);
        List<Order__c> orderList = new List<Order__c>();
        List<Order_Line__c> orderLineList = new List<Order_Line__c>();
        Set<Id> oldOrderIds = new Set<Id>();
        Set<Id> oldOrderLinesIds = new Set<Id>();
        Boolean isOk = true;
        if (auftragList != null && auftragList.size() > 0) {
            for (Auftrag__c auftrag : auftragList) {
                orderList.add(newOrder(contactId, auftrag, opp));
            }
            try {
                insert orderList;
            } catch (Exception e) {
                isOk = false;
                System.debug('Fehler beim Anlegen der Orders: ' + orderList);
                Database.rollback(sp);
            }
            // collect the old order Ids to get their lines
            if (orderList != null && orderList.size() > 0) {
                for (Order__c order  : orderList) {
                    oldOrderIds.add(order.Old_Order_Id__c);
                }
                //
                List<Auftragsposition__c> positionList = getOrderLines(oldOrderIds);
                for (Order__c order  : orderList) {
                    for (Auftragsposition__c aufPos : positionList) {
                        if (order.Old_Order_Id__c == aufPos.Auftrag__c) {
                            orderLineList.add(createOrderLines(order, aufPos));
                        }
                    }
                }
                // insert order lines
                if (orderLineList != null && orderLineList.size() > 0) {
                    try {
                        insert orderLineList;
                    } catch (Exception e) {
                        isOk = false;
                        System.debug('Fehler beim Anlegen der Order Lines: ' + e);
                        Database.rollback(sp);
                    }
                    //
                    for (Order_Line__c oLine : orderLineList) {
                        oldOrderLinesIds.add(oLine.Old_Order_Line_Id__c);
                    }
                    List<Lieferscheinposition__c> bedarfList = getDeliveryLines(oldOrderLinesIds, 'Bedarf');
                    if (bedarfList != null && bedarfList.size() > 0) {
                        for (Lieferscheinposition__c liePos : bedarfList) {
                            for (Order_Line__c line : orderLineList) {
                                if (liePos.Auftragsposition__c == line.Old_Order_Line_Id__c) {
                                    deliveryLineList.add(newDeliveryLine(contactId, line, liePos));
                                }
                            }
                        }
                    }
                }
            }
        }
        return isOk;
    }

    public static Order_Line__c createOrderLines(Order__c order, Auftragsposition__c position){
        return newOrderLine(order, position);   
    }

    public static Boolean createGenehmigungen(String contactId, Kunde__c client, Savepoint sp){
        Boolean isOk = true;
        List<Genehmigung__c> geneList = getGenehmigung(client);
        Set<Id> geneIds = new Set<Id>();
        if (geneList != null && geneList.size() > 0) {
            List<Curabox_Genehmigung__c> curaboxGeneList = new List<Curabox_Genehmigung__c>();
            for (Genehmigung__c genemigung : geneList) {
                curaboxGeneList.add(newGenehmigung(contactId, genemigung));
            }
            try {
                insert curaboxGeneList;
            } catch (Exception e) {
                isOk = false;
                System.debug('Fehler bei den Genehmigungen: '+ curaboxGeneList);
                Database.rollback(sp);
            }
            // get the old genehmigung Ids
            if (curaboxGeneList != null && curaboxGeneList.size() > 0) {
                for (Curabox_Genehmigung__c cbGene : curaboxGeneList) {
                    geneIds.add(cbGene.Old_Genehmigung_Id__c);
                }
                curaboxGenehmigungPositionList.addAll(createGenehmigungPosition(curaboxGeneList, geneIds));
            }
        }
        return isOk;
    }

    public static List<Curabox_Genehmigungsposition__c>  createGenehmigungPosition(List<Curabox_Genehmigung__c> genehmigungList, Set<Id> olsIds){
        List<Curabox_Genehmigungsposition__c> CBgPositionList = new List<Curabox_Genehmigungsposition__c>();
        List<Genehmigungsposition__c> gPositionList = getGenehmigungspositionen(olsIds);
        if (gPositionList != null && gPositionList.size() > 0) {
            for (Curabox_Genehmigung__c cbgene : genehmigungList) {
                for (Genehmigungsposition__c gPosition : gPositionList) {
                    if (cbgene.Old_Genehmigung_Id__c == gPosition.Genehmigung__c) {
                        CBgPositionList.add(newGenehmigungPosition(cbgene, gPosition));
                    }
                }  
            }
        }
        return CBgPositionList;
    }

    public static Order__c newOrder(String contactId, Auftrag__c auftrag, Opportunity opp){
        Date today = System.today();
        Order__c order = new Order__c();
        order.Opportunity__c = opp.Id;
        order.Contact__c = contactId;
        order.Delivery_frequency__c = auftrag.Lieferzeitraum__c;
        if (auftrag.Liefertag__c != null) {
            order.Liefertag__c = Date.newInstance(today.year(), today.month(),Integer.valueOf(auftrag.Liefertag__c));
        }
        else {
            order.Liefertag__c = Date.newInstance(today.year(), today.month(),today.day());
        }
        order.Description__c = auftrag.Bezeichnung__c;
        order.Genehmigt_von__c = auftrag.genehmigt_ab__c;
        order.Genehmigt_bis__c = auftrag.genehmigt_bis__c;
        order.Unbefristet_genehmigt__c = auftrag.Unbefristet_genehmigt__c;
        order.Recipe__c = auftrag.Rezept__c;
        //
        if(auftrag.Bezeichnung__c != null){
            if (auftrag.Bezeichnung__c.contains('CB')) {
                order.Nach_Paragraph__c = '54';
            }
            else {
                order.Nach_Paragraph__c = '51';
            }
        }
        // set order status
        if (auftrag.Genehmigungsstatus__c != null && String.isNotEmpty(auftrag.Genehmigungsstatus__c)) {
            if(auftrag.Genehmigungsstatus__c == 'genehmigt') {
                order.Status__c = 'aktiv';
            }
            else if((auftrag.Genehmigungsstatus__c == 'abgelaufen') || (auftrag.Genehmigungsstatus__c == 'abbestellt')){
                order.Status__c = 'beendet';
            }
            else if(auftrag.Genehmigungsstatus__c == 'angehalten') {
                order.Status__c = 'pausiert';
            }  
        }
        // set old order id
        order.Old_Order_Id__c = auftrag.Id;
        return order;
    }

    public static Order_Line__c newOrderLine(Order__c order, Auftragsposition__c position){
        Order_Line__c line = new Order_Line__c();
        line.Order__c = order.Id;
        if (productMap.get(position.Artikel__r.Name) != null) {
            line.Product__c = productMap.get(position.Artikel__r.Name).Id;
        }
        line.Gen_Menge_Stk_Mon__c = position.Gen_Menge_Stk_Mon__c;
        line.Price__c = position.Preis__c;
        line.Lieferstatus__c = position.Lieferstatus__c;
        line.Old_Order_Line_Id__c = position.Id;
        return line; 
    }

    public static Delivery_Line__c newDeliveryLine(String contactId, Order_Line__c oLine, Lieferscheinposition__c position){
        Delivery_Line__c dLine = new Delivery_Line__c();
        dLine.Contact__c = contactId;
        dLine.Delivery_date__c = position.Lieferdatum__c;
        dLine.Delivery_status__c = position.Status__c;
        dLine.Order_line__c = oLine.Id;
        if (productMap.get(position.Artikel__r.Name) != null) {
            dLine.Product__c = productMap.get(position.Artikel__r.Name).Id;
        }
        dLine.Quantity__c = position.Menge__c;
        dLine.VZ_bis__c = position.VZ_bis__c;
        dLine.VZ_von__c = position.VZ_von__c;
        dLine.Abrechnungsstatus_Krankenkasse__c = position.Abrechnungsstatus_Krankenkasse__c;
        if(position.Lieferscheinposition_text__c != null && String.isNotEmpty(position.Lieferscheinposition_text__c)) dLine.Delivery_line_text__c = position.Lieferscheinposition_text__c;
        if(position.Lieferscheinposition_zahl__c != null) dLine.Delivery_line_number__c = position.Lieferscheinposition_zahl__c;

        return dLine;
    }

    public static Curabox_Genehmigung__c newGenehmigung(String contactId, Genehmigung__c gene){
        Curabox_Genehmigung__c cGenehmigung = new Curabox_Genehmigung__c();
        cGenehmigung.Contact__c = contactId;
        cGenehmigung.Old_Genehmigung_Id__c = gene.Id;
        cGenehmigung.Business_CreatedDate__c = gene.CreatedDate;
        cGenehmigung.Nach_Paragraph__c = gene.Nach_Paragraph__c;
        cGenehmigung.Status__c = gene.Status__c; 
        cGenehmigung.unbefristet_genehmigt__c = gene.unbefristet_genehmigt__c;
        cGenehmigung.Antrag_versandt_am__c = gene.Antrag_versandt_am__c;
        if(gene.genehmigt_ab__c != null) cGenehmigung.genehmigt_ab__c = gene.genehmigt_ab__c;
        if(gene.genehmigt_bis__c != null) cGenehmigung.genehmigt_bis__c = gene.genehmigt_bis__c;
        if(gene.Genehmigungsnummer__c != null && String.isNotEmpty(gene.Genehmigungsnummer__c)) cGenehmigung.Genehmigungsnummer__c = gene.Genehmigungsnummer__c;
        if(gene.Antrag_beantwortet_am__c != null) cGenehmigung.Antrag_beantwortet_am__c = gene.Antrag_beantwortet_am__c;
        if(gene.Antrag_eingegangen_am__c != null) cGenehmigung.Antrag_eingegangen_am__c = gene.Antrag_eingegangen_am__c;
        if(gene.attachmentID__c != null) cGenehmigung.attachmentId__c = gene.attachmentID__c;
        cGenehmigung.KV_status__c = 'closed';

        return cGenehmigung;
    }

    public static Curabox_Genehmigungsposition__c newGenehmigungPosition(Curabox_Genehmigung__c cbGene, Genehmigungsposition__c genePosition){
        Curabox_Genehmigungsposition__c cbGenePosition = new Curabox_Genehmigungsposition__c();
        cbGenePosition.Genehmigung__c = cbGene.Id;
        cbGenePosition.Ant_Menge_Stk__c = genePosition.Ant_Menge_Stk_Mon__c;
        if (productGroupMap.get(genePosition.Artikelgruppe__r.Name) != null) {
            cbGenePosition.Product_Group__c = productGroupMap.get(genePosition.Artikelgruppe__r.Name).Id;   
        }
        if(genePosition.Gen_Menge_Stk_Mon__c != null) cbGenePosition.Gen_Menge_Stk__c = genePosition.Gen_Menge_Stk_Mon__c;
        if(genePosition.genehmigt_ab__c != null) cbGenePosition.genehmigt_ab__c = genePosition.genehmigt_ab__c;
        if(genePosition.genehmigt_bis__c != null) cbGenePosition.genehmigt_bis__c = genePosition.genehmigt_bis__c;
        cbGenePosition.unbefristet_genehmigt__c = genePosition.unbefristet_genehmigt__c;

        return cbGenePosition;
    }

    /**
     * Getters methods
     */
    public static List<Auftrag__c> getOrdersByClient(Kunde__c client){
        List<Auftrag__c> orderList = new List<Auftrag__c>();
        try {
            orderList = [SELECT Id, Name, Bezeichnung__c, genehmigt_ab__c, genehmigt_bis__c,  Unbefristet_genehmigt__c, 
                                Rezept__c, Lieferzeitraum__c, Liefertag__c, Genehmigungsstatus__c FROM Auftrag__c WHERE Kunde__c =:client.Id];
        } catch (Exception e) {
            System.debug('Keine Aufträge für diesen Kunde gefunden');
        }
        return orderList;
    }

    public static List<Auftragsposition__c> getOrderLines(Set<Id> orderIds){
        List<Auftragsposition__c> positionList = new List<Auftragsposition__c>();
        try {
            positionList = [SELECT Id, Name, Gen_Menge_Stk_Mon__c, Preis__c, Lieferstatus__c, Artikel__r.Name, Auftrag__c FROM Auftragsposition__c WHERE Auftrag__c IN:orderIds];
        } catch (Exception e) {
            System.debug('Keine Auftragspositionen gefunden');
        }
        return positionList;
    }

    public static List<Task> getTaskByClient(Kunde__c client){
        List<Task> tList = new List<Task>();
        try {
            tList = [SELECT Id, OwnerId, Subject, Description, whatid, WhoId, ActivityDate, Status FROM Task WHERE whatid =: client.Id ALL ROWS];
        } catch (Exception e) {
            System.debug('Keine Tasks für diesen Kunde gefunden');
        }
        return tList;
    }

    public static List<Kundenstatus__c> getContactStatusList(Kunde__c client){
        List<Kundenstatus__c> kStatusList = new List<Kundenstatus__c>();
        try {
            kStatusList = [SELECT Id, Status__c, Ursprungsanfrage__c, Antrag_bewilligt_abgelehnt_am__c, Antrag_eingegangen_am__c, CRM_Ticket_ID__c, K_ndigungsbemerkung__c, 
                                  Wizard_Version__c, K_ndigungsdatum__c, K_ndigungsgrund__c, Anzahl_Erinnerung_Email__c, Partner_ID__c, Produktgruppe__c,Referrer__c, Tracking_Order_ID__c 
                           FROM Kundenstatus__c WHERE Kunde__c =: client.Id AND Produktgruppe__c IN ('PG54', 'PG51')];
        } catch (Exception e) {
            System.debug('Keine Kundenstatus für diesen Kunde gefunden ' + e);
        }
        return kStatusList;
    }

    public static List<Lieferscheinposition__c> getDeliveryLines(Set<Id> auposIds, String status){
        List<Lieferscheinposition__c> dLineList = new List<Lieferscheinposition__c>();
        try {
            dLineList = [SELECT Id, Name, Lieferdatum__c, Status__c, Artikel__r.Name, Menge__c, VZ_bis__c, VZ_von__c, Auftragsposition__c, 
                            Abrechnungsstatus_Krankenkasse__c, Lieferscheinposition_text__c, Lieferscheinposition_zahl__c
                        FROM Lieferscheinposition__c WHERE Auftragsposition__c IN: auposIds AND Status__c =:status]; 
        } catch (Exception e) {
            System.debug('Fehler bei der Lieferscheinpositionen für die Auftragspositionen: '+ auposIds);
        }
        return dLineList;
    }

    public static List<Genehmigung__c> getGenehmigung(Kunde__c client){
        List<Genehmigung__c> gList = new List<Genehmigung__c>();
        try {
            gList = [SELECT Id, Name, Nach_Paragraph__c, Status__c, unbefristet_genehmigt__c, Antrag_versandt_am__c, genehmigt_ab__c, genehmigt_bis__c,
                            Genehmigungsnummer__c, Antrag_beantwortet_am__c, Antrag_eingegangen_am__c, attachmentID__c, CreatedDate
                    FROM Genehmigung__c WHERE Kunde__c =: client.Id];
        } catch (Exception e) {
            System.debug('Fehler bei den Genehmigung für den Kunde: ' + client.Id);
        }
        return gList;
    }

    public static List<Genehmigungsposition__c> getGenehmigungspositionen(Set<Id> olsIds){
        List<Genehmigungsposition__c> cbGenePositionList = new List<Genehmigungsposition__c>();
        try {
            cbGenePositionList = [SELECT Id, Name, Gen_Menge_Stk_Mon__c, Ant_Menge_Stk_Mon__c, genehmigt_ab__c, genehmigt_bis__c, unbefristet_genehmigt__c, Artikelgruppe__r.Name,Genehmigung__c 
                                  FROM Genehmigungsposition__c WHERE Genehmigung__c IN: olsIds];
        } catch (Exception e) {
            System.debug('Fehler bei den Genehmigungspositionen: '+ e.getMessage());
        }
        return cbGenePositionList;
    }

    public void getAllProduct(){
        productMap = new Map<String, Product__c>();
        for(Product__c product : [SELECT Id, Name FROM Product__c]){
            productMap.put(product.Name, product);
        }
    }

    public void getAllCuraboxes(){
        curaboxMap = new Map<String, curabox__c>();
        for(curabox__c curabox : [SELECT Id, Name FROM curabox__c]){
            curaboxMap.put(curabox.Name, curabox);
        }
    }

    public void getAllProductGroup(){
        productGroupMap = new Map<String, Product_Group__c>();
        for(Product_Group__c pg : [SELECT Id, Name FROM Product_Group__c]){
            productGroupMap.put(pg.Name, pg);
        }
    }

    public static Contact getAspByClient(String contactId){
        Contact contact = new Contact();
        try {
            contact = [SELECT Id, FirstName, LastName, AccountId, Account.Name, createdDate FROM Contact WHERE Id =: contactId LIMIT 1];
        } catch (Exception e) {
            System.debug('Kein ASP für den Kunde: ' + contactId);
        }
        return contact;
    }

    public static void updateFamilieASP(Contact contact){
        if (contact.Betreuer__c != null && String.isNotEmpty(contact.Betreuer__c)) {
            Contact asp = getAspByClient(contact.Betreuer__c);
            if (asp.Account.Name == 'ASP für Kunden') {
                try {
                    asp.AccountId = contact.AccountId;
                    asp.RecordTypeId = recordType;
                    update asp;
                } catch (Exception e) {
                    System.debug('Update ASP Familie: '+ e); 
                }   
            }
        }
    }

    public static Account getGlobalFamilie(Contact asp){
        Account fam = new Account();
        try {
            fam = [SELECT Id, Name FROM Account WHERE Id =: asp.AccountId LIMIT 1];
        } catch (Exception e) {
            System.debug(e);
        }
        return fam;
    }

    public static void updateClientAfterConvert(Kunde__c client){
        client.isToContactConverted__c = true;
        try {
            update client;
        } catch (Exception e) {
            System.debug('Fehler beim update des Kundes');
        }
    }
}