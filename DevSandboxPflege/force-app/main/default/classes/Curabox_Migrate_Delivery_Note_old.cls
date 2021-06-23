/****************************************************************************************************************************
// Created 17.10.2019 von  BT/WDS
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
// This class generate delivery Note data from clients to contacts for all old Lieferscheine
//
//****************************************************************************************************************************
// Changes: 
// 01.11.2019    BT        Only customers who have been converted are considered
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public class Curabox_Migrate_Delivery_Note_old implements Database.Batchable<sObject>, Database.Stateful {
    
    public static Map<String, Product__c> productMap {get; set;}
    public static Map<String, contact_address__c> adressMap {get; set;}
    public static List<Lieferscheinposition__c> lineList {get; set;}
    public static List<Delivery_Line__c> deliveryLineList {get; set;}
    public static Set<id> lieferbestSet {get; set;}
    public static map<string, string> dhlCode {get; set;}
    public static list<string> errorList = new list<string>();
    public static integer totalDN = 0;
    public integer total = 0;

    public String query = 'SELECT Id, Name, Ausgeliefert_am__c, Lieferdatum__c, Lieferadresse__c, Abgerechnet_am__c, Status__c, Stornierung__c, reasonos_for_rescission__c, ' +
                                'Unterschrift__c, Versandpartner__c, Kunde_Zuzahlung_befreit__c, Status_DHL__c, Sendungsnummer_DHL__c, ' +
                                'Liefernotiz__c, Liefertext__c, Lieferschein_text__c, Lieferschein_gedruckt__c, Lieferanschrift__c, Kunde__c, ' +
                                'Lieferschein_logik__c from lieferschein__c where lieferschein_logik__c = false ' +
                                'and id not in (select lieferschein__c from Lieferscheinposition__c where status__c = \'jetzt liefern\') ';

    public Curabox_Migrate_Delivery_Note_old() {
        totalDN = 0;
    }

    public Curabox_Migrate_Delivery_Note_old (boolean all) {
        totalDN = 0;
    } 


    public Database.QueryLocator start(Database.BatchableContext bc) {
        totalDN = 0;
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Lieferschein__c> lieferscheine){
        getAllProduct();
        
        deliveryLineList = new List<Delivery_Line__c>();
        lineList = new List<Lieferscheinposition__c>();
        migrateDeliveryNote(lieferscheine);
        if (deliveryLineList != null && deliveryLineList.size() > 0) {
            try {
                insert deliveryLineList;
                update lineList;
            } catch (Exception e) {
                System.debug('Fehler beim inserieren der Lieferscheinpositionen: '+ e);    
            }
        }
        else {
            System.debug('### ksg message: Für folgende Lieferscheine wurden keine Lieferscheinpositionen gefunden: ' + lieferscheine);
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

    public static void migrateDeliveryNote(List<Lieferschein__c> lieferscheine){
        Savepoint sp = Database.setSavepoint();
        List<Delivery_Note__c> allNoteList = new List<Delivery_Note__c>();
        set<Id> kundeIds = new Set<Id>();
        set<Id> lieferscheinIds = new set<Id>();
        lieferbestSet = new set<id>();
        dhlCode = new map<string, string>();
        
        lieferscheinIds = getLieferscheineIds(lieferscheine);
        List<Lieferbest_tigung__c> lieferBes = getLieferbestaetigungen(lieferscheinIds);
        
        if (lieferscheine != null && lieferscheine.size() > 0) {
        
            if(lieferBes != null && lieferBes.size() > 0) {
                for (Lieferbest_tigung__c bes : lieferBes) {                   
                    // AM 
                    if(bes.abena_empfang__c) {
                        lieferbestSet.add(bes.Lieferschein__c);
                    }
                    if(bes.statusMsgId__c != null) {
                        dhlCode.put(bes.Lieferschein__r.name, bes.statusMsgId__c);
                    }
                }
            }
            
            
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
                    Database.SaveResult[] srList = Database.insert(allNoteList, false);
                    
                    for(Database.saveResult sr: srList) {
                        if (sr.isSuccess()) {
                            system.debug('#### ok ' + sr.getId());
                        }
                        else {
                            for(Database.Error err : sr.getErrors()) {
                                errorList.add('Error! On insert delivery note' + err.getMessage());
                            }
                        }
                    }
                    
                    Database.SaveResult[] srList2 = Database.update(lieferscheine, false);
                    
                    for(Database.saveResult sr: srList2) {
                        if (sr.isSuccess()) {
                            system.debug('#### ok ' + sr.getId());
                        }
                        else {
                            for(Database.Error err : sr.getErrors()) {
                                errorList.add('Error! On update lieferschein' + err.getMessage());
                            }
                        }
                    }
                    totalDN += allNoteList.size();                   
                } catch (Exception e) {
                    Database.rollback(sp);
                    System.debug(e);
                    errorList.add('error on insert DN. error=' + e.getLineNumber() + ' ' + e.getMessage());
                }
                // add positions
                lineList = getDeliveryLines(lieferscheinIds);
                // get order lines
                Map<Id, Id> oldToNewOrderLines = getNewOrderLines(lineList);
                Delivery_Line__c dl;
                for (Delivery_Note__c note : allNoteList) {
                    for (Lieferscheinposition__c position : lineList) {
                        if (note.old_LS_Name__c == position.Lieferschein__r.Name) {
                            dl = newDeliveryLine(note.Contact__c, position, note);
                            if(position.Auftragsposition__c != null) dl.Order_line__c = oldToNewOrderlines.get(position.Auftragsposition__c);
                            deliveryLineList.add(dl);
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
        note = setDeliveryAddress(schein, note);

        return note;
    }

    public static List<Lieferscheinposition__c> getDeliveryLines(set<id> lieferscheinIds){
        List<Lieferscheinposition__c> dLineList = new List<Lieferscheinposition__c>();
        try {
            dLineList = [SELECT Id, Name, Lieferdatum__c, Status__c, Artikel__r.Name, Menge__c, VZ_bis__c, VZ_von__c, Auftragsposition__c, 
                            Abrechnungsstatus_Krankenkasse__c, Lieferscheinposition_text__c, Lieferscheinposition_zahl__c, Lieferschein__r.Name
                        FROM Lieferscheinposition__c WHERE Lieferschein__c in: lieferscheinIds];
                        
            for(Lieferscheinposition__c lpos: dlineList) {
               lpos.Lieferscheinposition_text__c = 'converted';
            }                                   
        } catch (Exception e) {
            System.debug('Fehler bei den Lieferscheinpositionen für die Lieferscheine: '+ lieferscheinIds);
            errorList.add('error on create DL. ' +  lieferscheinIds + ' error=' + e.getLineNumber() + ' ' + e.getMessage());
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
    
    public static Map<Id, Id> getNewOrderLines(List<Lieferscheinposition__c> lpList) {
        Set<Id> oldOrderLineIds = new Set<Id>();
        Map<Id, Id> oldToNewMap = new Map<Id, Id>();
        
        for(Lieferscheinposition__c lp: lpList) {
            if(lp.Auftragsposition__c != null) oldOrderLineIds.add(lp.Auftragsposition__c);
        }
        
        for(Order_Line__c orderLine: [select id, Old_Order_Line_Id__c from Order_Line__c where Old_Order_Line_Id__c in: oldOrderLineIds]) {
            oldToNewMap.put(orderline.Old_Order_Line_Id__c, orderLine.id);
        }
        
        return oldToNewMap;
    }
    
    public static List<Lieferbest_tigung__c> getLieferbestaetigungen(set<id> lieferscheinIds) {
        return [SELECT Lieferschein__c, Lieferschein__r.name, abena_empfang__c, statusMsgId__c 
                    FROM Lieferbest_tigung__c
                    WHERE Lieferschein__c IN :lieferscheinIds];
    }
    
    public static set<Id> getLieferscheineIds(List<Lieferschein__c> lieferscheine) {
        set<Id> lieferscheinIds = new set<Id>();
        
        for(Lieferschein__c ls: lieferscheine) {
            lieferscheinIds.add(ls.Id);
        }
        
        return lieferscheinIds;
    }
    
    public static Delivery_note__c setDeliveryAddress(Lieferschein__c lieferschein, Delivery_note__c deliveryNote){
        if(lieferschein.Lieferadresse__c != null && lieferschein.Lieferadresse__c != '') {
            Integer index = lieferschein.Lieferadresse__c.lastIndexOf(', ');                                   
            
            if(index == -1) {
                deliveryNote.Street__c = lieferschein.Lieferadresse__c;
            }
            else {
                deliveryNote.Street__c = lieferschein.Lieferadresse__c.substring(0, index);
                
                String postalCode_city = lieferschein.Lieferadresse__c.substring(index+2, lieferschein.Lieferadresse__c.length());
                Integer firstIndex = postalCode_city.indexOf(' ');
                
                if(firstIndex == -1) {
                    deliveryNote.City__c = postalCode_city;
                }
                else {
                    deliveryNote.PostalCode__c = postalCode_City.substring(0, firstIndex);
                    deliveryNote.City__c = postalCode_City.substring(firstIndex+1, postalCode_City.length());
                }                
            }     
        }
        else {
            deliveryNote.Street__c = null;            
            deliveryNote.City__c = null;
            deliveryNote.PostalCode__c = null;
        }    
        
        return deliveryNote;
    }
}