/****************************************************************************************************************************
// Created 06.08.2019 von  AD
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
// This class generate delivery Note data from clients to contacts
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public class Curabox_Migrate_Delivery_Note implements Database.Batchable<sObject>, Database.Stateful {
    
    public static Map<String, Product__c> productMap {get; set;}
    public static Map<String, contact_address__c> adressMap {get; set;}
    public static List<Delivery_Line__c> deliveryLineList {get; set;}
    public static Set<id> lieferbestSet {get; set;}
    public static map<string, string> dhlCode {get; set;}
    public static list<string> errorList = new list<string>();
    public static integer totalDN = 0;

    public String query = 'SELECT Lieferschein__c, Lieferschein__r.name, abena_empfang__c, statusMsgId__c FROM Lieferbest_tigung__c ' +
            'WHERE an_abena_versendet__c = true ' +
            'AND rechnung__c = null AND createddate > 2019-05-01T01:01:01Z ' +
            'AND Lieferschein__c IN (SELECT Lieferschein__c  FROM Lieferscheinposition__c WHERE Abrechnungsstatus_Krankenkasse__c = \'nicht abrechenbar\') ' + 
            ' AND Lieferschein__r.Lieferschein_logik__c = false';

    public String queryAll = 'SELECT Lieferschein__c, Lieferschein__r.name,  abena_empfang__c, statusMsgId__c FROM Lieferbest_tigung__c ' +
            'WHERE Lieferschein__r.Lieferschein_logik__c = false AND createddate > 2018-01-01T01:01:01Z ';

    public Curabox_Migrate_Delivery_Note() {
        totalDN = 0;
    }

    public Curabox_Migrate_Delivery_Note (boolean all) {
        totalDN = 0;
    } 


    public Database.QueryLocator start(Database.BatchableContext bc) {
        totalDN = 0;
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Lieferbest_tigung__c> lieferBestaetigung){
        getAllProduct();
        
        
        deliveryLineList = new List<Delivery_Line__c>();
        migrateDeliveryNote(lieferBestaetigung);
        if (deliveryLineList != null && deliveryLineList.size() > 0) {
            try {
                insert deliveryLineList;
            } catch (Exception e) {
                System.debug('Fehler beim inserieren der Lieferscheinpositionen: '+ e);    
            }
        }
    }

    public void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
            // send email to system admin

        String subject = string.valueOf(totalDN) + ' Lieferscheine wurden übernommen';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setSaveAsActivity(true);
        mail.setSubject(subject);
        string PlainTextBody = 'Lieferscheine wurden übernommen.<br/>';
            if(errorList.size() > 0) {
                subject += ' Es gab Fehler';
                for(string line : errorList) {
                    String v1 = '\r\n' + '</br>';
                    PlainTextBody += line + v1;
                }
            }
            else {
                PlainTextBody += 'keine Fehler. \r\n';
            }        
        mail.setHtmlBody(PlainTextBody);
        mail.setPlainTextBody(PlainTextBody);
        String email = 'kontakt@klosesrockepartner.de';
        String[] toAddress = new String[] {email};
        mail.setToAddresses(toAddress);
       
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
        } catch (Exception e) {
        	System.debug('Datenübernahme Error: ' + e.getMessage());
        }       
    }

    public static void migrateDeliveryNote(List<Lieferbest_tigung__c> lieferBes){
        Savepoint sp = Database.setSavepoint();
        List<Delivery_Note__c> allNoteList = new List<Delivery_Note__c>();
        List<String> lsNames = new List<String>();
        set<Id> kundeIds = new Set<Id>();
        lieferbestSet = new set<id>();
        dhlCode = new map<string, string>();

        if (lieferBes != null && lieferBes.size() > 0) {
            for (Lieferbest_tigung__c bes : lieferBes) {
                lsNames.add(bes.Lieferschein__r.name);
                // AM 
                if(bes.abena_empfang__c) {
                    lieferbestSet.add(bes.Lieferschein__c);
                }
                if(bes.statusMsgId__c != null) {
                    dhlCode.put(bes.Lieferschein__r.name, bes.statusMsgId__c);
                }
            }
            List<Lieferschein__c> lieferscheine = getDeliveryNotes(lsNames);
            if (lieferscheine != null && lieferscheine.size() > 0) {
                for (Lieferschein__c schein : lieferscheine) {
                    kundeIds.add(schein.Kunde__c);
                }
                List<Contact> contactList = getContacts(kundeIds);
                set<id> addrSet = new set<id>();
                for (Contact contact : contactList) {
                    addrSet.add(contact.id);
                }
                getAddresses(addrSet);
                for (Contact contact : contactList) {
                    for (Lieferschein__c schein : lieferscheine) {
                        if (contact.Kunde_Id__c == schein.Kunde__c) {
                            allNoteList.add(newDeliveryNote(contact, schein));
                            schein.Lieferschein_logik__c = true;
                        }
                    }
                }
                // insert Delivery notes
                try {
                    insert allNoteList; 
                    update lieferscheine;
                    totalDN += allNoteList.size();
                } catch (Exception e) {
                    Database.rollback(sp);
                    System.debug(e);
                    errorList.add('error on insert DN. error=' + e.getLineNumber() + ' ' + e.getMessage());
                }
                // add positions
                List<Lieferscheinposition__c> lineList = getDeliveryLines(lsNames);
                for (Delivery_Note__c note : allNoteList) {
                    for (Lieferscheinposition__c position : lineList) {
                        if (note.old_LS_Name__c == position.Lieferschein__r.Name) {
                            deliveryLineList.add(newDeliveryLine(note.Contact__c, position, note));
                        }
                    }
                }
            }
        }   
    }

    public static Delivery_Line__c newDeliveryLine(Id contactId, Lieferscheinposition__c position, Delivery_Note__c note){
        Delivery_Line__c dLine = new Delivery_Line__c();
        dLine.Contact__c = contactId;
        dLine.Delivery_note__c = note.Id;
        dLine.Delivery_date__c = position.Lieferdatum__c;
        dLine.Delivery_status__c = position.Status__c;
        dLine.Product__c = productMap.get(position.Artikel__r.Name).Id;
        dLine.Quantity__c = position.Menge__c;
        dLine.VZ_bis__c = position.VZ_bis__c;
        dLine.VZ_von__c = position.VZ_von__c;
        dLine.Abrechnungsstatus_Krankenkasse__c = position.Abrechnungsstatus_Krankenkasse__c;
        if(position.Lieferscheinposition_text__c != null && String.isNotEmpty(position.Lieferscheinposition_text__c)) dLine.Delivery_line_text__c = position.Lieferscheinposition_text__c;
        if(position.Lieferscheinposition_zahl__c != null) dLine.Delivery_line_number__c = position.Lieferscheinposition_zahl__c;

        return dLine;
    }

    public static Delivery_Note__c newDeliveryNote(Contact con, Lieferschein__c schein){
        Delivery_Note__c note = new Delivery_Note__c();
        // AM
        note.xml_send__c = true;
        note.xml_confirmed__c = lieferbestSet.contains(schein.id);
        note.pod_recieved__c = schein.Unterschrift__c;
        if(dhlCode.containsKey(schein.Name)) {
            note.DHL_shipping_number__c = dhlCode.get(schein.Name);
        }

        note.Contact__c = con.Id;
        note.old_LS_Name__c = schein.Name;
        note.Delivered_on__c = schein.Ausgeliefert_am__c;
        note.Delivery_date__c = schein.Lieferdatum__c;
        note.Status__c = schein.Status__c;
        note.rescission__c = schein.Stornierung__c;
        note.rescission_reasons__c = schein.reasonos_for_rescission__c;
        note.Signature__c = schein.Unterschrift__c;
        note.Shipping_partner__c = schein.Versandpartner__c;
        note.Kunde_Zuzahlung_befreit__c = schein.Kunde_Zuzahlung_befreit__c;
        if(schein.Abgerechnet_am__c != null) note.Billing_on__c = schein.Abgerechnet_am__c;
        if(schein.Status_DHL__c != null && String.isNotEmpty(schein.Status_DHL__c)) note.Status_DHL__c = schein.Status_DHL__c;
        if(schein.Sendungsnummer_DHL__c != null && String.isNotEmpty(schein.Sendungsnummer_DHL__c)) note.DHL_shipping_number__c = schein.Sendungsnummer_DHL__c;
        if(schein.Liefernotiz__c != null && String.isNotEmpty(schein.Liefernotiz__c)) note.delivery_notice__c = schein.Liefernotiz__c;
        if(schein.Liefertext__c != null && String.isNotEmpty(schein.Liefertext__c)) note.Delivery_text__c = schein.Liefertext__c;
        if(schein.Lieferschein_text__c != null && String.isNotEmpty(schein.Lieferschein_text__c)) note.Delivery_note_text__c = schein.Lieferschein_text__c;
        note.Delivery_note_printed__c = schein.Lieferschein_gedruckt__c;
        if (adressMap.get(con.Id) != null) {
            note.DeliveryAddress__c = adressMap.get(con.Id).Id;
        }

        return note;
    }

    public static List<Lieferschein__c> getDeliveryNotes(List<String> lsNames){
        List<Lieferschein__c> dNoteList = new List<Lieferschein__c>();
        try {
            dNoteList = [SELECT Id, Name, Ausgeliefert_am__c, Lieferdatum__c, Abgerechnet_am__c, Status__c, Stornierung__c, reasonos_for_rescission__c,
                                Unterschrift__c, Versandpartner__c, Kunde_Zuzahlung_befreit__c, Status_DHL__c, Sendungsnummer_DHL__c,
                                Liefernotiz__c, Liefertext__c, Lieferschein_text__c, Lieferschein_gedruckt__c, Lieferanschrift__c, Kunde__c, Lieferschein_logik__c
                                FROM Lieferschein__c WHERE Name IN: lsNames];
        } catch (Exception e) {
            System.debug('Fehler bei den Lieferscheine für den Kunde: '+ lsNames);
            errorList.add('error on create DN. ' +  lsNames + ' error=' + e.getLineNumber() + ' ' + e.getMessage());
        }
        return dNoteList;
    }

    public static List<Lieferscheinposition__c> getDeliveryLines(List<String> lsNames){
        List<Lieferscheinposition__c> dLineList = new List<Lieferscheinposition__c>();
        try {
            dLineList = [SELECT Id, Name, Lieferdatum__c, Status__c, Artikel__r.Name, Menge__c, VZ_bis__c, VZ_von__c, Auftragsposition__c, 
                            Abrechnungsstatus_Krankenkasse__c, Lieferscheinposition_text__c, Lieferscheinposition_zahl__c, Lieferschein__r.Name
                        FROM Lieferscheinposition__c WHERE Lieferschein__r.Name =: lsNames];
        } catch (Exception e) {
            System.debug('Fehler bei den Lieferscheinpositionen für die Lieferscheine: '+ lsNames);
            errorList.add('error on create DL. ' +  lsNames + ' error=' + e.getLineNumber() + ' ' + e.getMessage());
        }
        return dLineList;
    }

    public static List<Contact> getContacts(Set<Id> kundeIds){
        List<Contact> contactList = new List<Contact>();
        try {
            contactList = [SELECT Id, Name, Kunde_Id__c FROM Contact WHERE Kunde_Id__c IN: kundeIds];
        } catch (Exception e) {
            System.debug(e);
            errorList.add('error on get contact. error=' + e.getLineNumber() + ' ' + e.getMessage());
        }
        return contactList;
    }

    public void getAllProduct(){
        productMap = new Map<String, Product__c>();
        for(Product__c product : [SELECT Id, Name FROM Product__c]){
            productMap.put(product.Name, product);
        }
    }

    public static void getAddresses(set<id> contIdSet) {
        adressMap = new Map<String, contact_address__c>();
        for(contact_address__c address : [SELECT Id, Contact__c FROM contact_address__c WHERE Standard_shipping_address__c = true AND Contact__c IN :contIdSet]){
            adressMap.put(address.Contact__c, address);
        }
    }


}