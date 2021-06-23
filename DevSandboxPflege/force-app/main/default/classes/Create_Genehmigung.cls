/****************************************************************************************************************************
// Created 08.05.2019 von  AD
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
//
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Create_Genehmigung {
    
    // Initialisieren des Genehmigung Objekts
    public static Curabox_Genehmigung__c newGenehmigung(String contactId, String paragraph, String documentId){
        Curabox_Genehmigung__c genehmigung = new Curabox_Genehmigung__c();
        genehmigung.Contact__c = contactId;
        genehmigung.Status__c = 'Antragsversand';
        genehmigung.Nach_Paragraph__c = paragraph;
        genehmigung.attachmentId__c = documentId;
        return genehmigung;
    }

    // this function is called in Formular_Erhalten class to use in lightning component
    public static string createGenehmigung(String contactId, String paragraph, String documentId){
        Date dueDate = Follow_Up_Task_Helper.getDueDate(Due_Date__c.getValues('Antrag an PK').Follow_Up_Task_Due_Date__c);
        String returnString = '';
        String genehmigungId = '';
        if (!String.isEmpty(contactId) && !String.isEmpty(paragraph)) {
            if (paragraph == '5X') {
                // Product group 54
                String genehmigung54 = insertGenehmigung(contactId, '54', documentId);
                if (genehmigung54 != null && !String.isEmpty(genehmigung54)) {
                    azhWebClient.sendKostenvoranschlagData(genehmigung54);
                    returnString ='OK';
                }
                else {
                    returnString = 'Fehler beim Erzeugen der Genehmigung';
                }
                // Product group 51
                String genehmigung51 = insertGenehmigung(contactId, '51', documentId);
                if (genehmigung51 != null && !String.isEmpty(genehmigung51)) {
                    azhWebClient.sendKostenvoranschlagData(genehmigung51);
                    returnString ='OK';
                }
                else {
                    returnString = 'Fehler beim Erzeugen der Genehmigung';
                }
                // create Follow-Up Task
                if (returnString == 'OK') {
                    Follow_Up_Task_Helper.insertFollowUpTask(contactId, 'Antrag an PK übermittelt', 'KV an Krankenkasse übermittelt', System.today(), 'Geschlossen');
                    Follow_Up_Task_Helper.insertFollowUpTask(contactId, 'Nachfassen bei PK wg. offener KÜ', 'KV an Krankenkasse übermittelt', dueDate, 'Geschlossen');
                }
            }
            else {
                genehmigungId = insertGenehmigung(contactId, paragraph, documentId);
                if (genehmigungId != null && !String.isEmpty(genehmigungId)) {
                    azhWebClient.sendKostenvoranschlagData(genehmigungId);
                    returnString ='OK';
                }
                else {
                    returnString = 'Fehler beim Erzeugen der Genehmigung';
                }
                // create Follow-Up Task
                if (returnString == 'OK') {
                    Follow_Up_Task_Helper.insertFollowUpTask(contactId, 'Antrag an PK übermittelt', 'KV an Krankenkasse übermittelt', System.today(), 'Geschlossen');
                    Follow_Up_Task_Helper.insertFollowUpTask(contactId, 'Nachfassen bei PK wg. offener KÜ', 'KV an Krankenkasse übermittelt', dueDate, 'Geschlossen');
                }
            }
        }
        else {
            returnString = 'Fehler beim Erzeugen der Genehmigung';
        }
        return returnString;
    }

    @AuraEnabled
    public static string sentToAZH(String genehmigungId){
        String returnString = '';
        try {
            azhWebClient.sendKostenvoranschlagData(genehmigungId);
        } catch (Exception e) {
            returnString = null;
            System.debug(e);
        }
        return returnString;
    }

    //
    public static String insertGenehmigung(String contactId, String paragraph, String documentId){
        Curabox_Genehmigung__c genehmigung = newGenehmigung(contactId, paragraph, documentId);
        Savepoint sp = Database.setSavepoint();
        try {
            insert genehmigung;
        } catch (Exception e) {
            System.debug('Beim Anlegen der Genehmigung ist folgende Fehler aufgetreten: '+e);
        }
        List<Product_Group__c> PgList = getProductGroupList(paragraph);
        if (genehmigung.Id != null && !String.isEmpty(genehmigung.Id)) {
            if (PgList != null && PgList.size()> 0) {    
                List<Curabox_Genehmigungsposition__c> gPositions = Create_Genehmigung_Positionen.createPositions(genehmigung, PgList);
                try {
                    insert gPositions;
                } catch (Exception e) {
                    System.debug('Beim Anlegen der Genehmigungspositionen ist folgende Fehler aufgetreten: '+e);
                }
            }
            else {
                Database.rollback(sp); 
            }
        }
        return genehmigung.Id;
    }

    // get all product group element to create Genehmigung position objects.
    public static List<Product_Group__c> getProductGroupList(String paragraph){
        List<Product_Group__c> pgList = new List<Product_Group__c>();
        if (paragraph != '5X') {
            try {
                pgList = [Select Id, Name from Product_Group__c Where Positionsnummer__c =:paragraph];
            } catch (Exception e) {
                System.debug(e);
            }
        }
        return pgList;
    }

    // method to navigate to aproval object
    public static Curabox_Genehmigung__c getGenehmigung(String contactId, String paragraph){
        List<Curabox_Genehmigung__c> genehmigungList = new List<Curabox_Genehmigung__c>();
        Curabox_Genehmigung__c genehmigung = new Curabox_Genehmigung__c();
        try {
            genehmigungList = [Select Id, Name from Curabox_Genehmigung__c where Contact__c =:contactId AND Nach_Paragraph__c=:paragraph
                                order by CreatedDate Desc];
            if (genehmigungList != null && genehmigungList.size() > 0) {
                genehmigung = genehmigungList[0];   
            }
        } catch (Exception e) {
            System.debug(e);
        }
        return genehmigung;
    }

}