/****************************************************************************************************************************
// Erstellt xx.xx.2019 von AD
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: ?????
//****************************************************************************************************************************
//
// Beschreibung: ?????
//                      
//              
//
//****************************************************************************************************************************
// Test:  
//*****************************************************************************************************************************
// Änderungen:   
// 07.10.2019 AM erstellen contentDocumentLink zu Genehmigung nach dem upload "Genenehmigung_PG5xx"
// 11.10.2019 AM 168701815 - Kundenstatus - Formular erhalten. Es darf automatisch nur von "Interessent" auf "Vorgang geschlossen" geändert werden.  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class Formular_Erhalten {
  
  /*
  *  This method rename the file that was uploaded
  */
   @AuraEnabled  
   public static List<ContentDocument> UpdateFiles(string documentId,string title,string recordId){
      ContentDocument cd = [select id,title from ContentDocument where Id=:documentId]; // Getting files from Parent record 
      cd.Title = title;  // Changing file Title with user entered title
      try{  
        update cd;  // Update ContentDocument (File)
        // AM 07.10.2019
        if(title.containsIgnoreCase('Genehmigung_PG')) {
          // wir brauchen GenId
          String pg = title.replace('Genehmigung_PG', '');
          Curabox_Genehmigung__c gn = Create_Genehmigung.getGenehmigung(recordId, pg);
         
          if(gn !=null) {           
            contentDocumentLink cdl= new contentDocumentLink(ShareType='I', Visibility='AllUsers', LinkedEntityId=gn.id, contentDocumentId=cd.id);
            Database.SaveResult sr = Database.insert(cdl, false); 
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('contentDocumentLink fields that affected this error: ' + err.getFields());
                }
            }
          }
        }
        // AM 07.10.2019
      }  
      catch(DMLException e){  
        system.debug('Exception has occurred! ' +e.getMessage());  
      }  
      List<ContentDocument> DocumentList = new List<ContentDocument>();  
      Set<Id> documentIds = new Set<Id>();  
      List<ContentDocumentLink> cdl=[select id,LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId=:recordId];  
      for(ContentDocumentLink cdLink:cdl){  
        documentIds.add(cdLink.ContentDocumentId);  
      }      
      DocumentList = [select Id,Title,FileType,ContentSize,Description from ContentDocument where id IN: documentIds]; 
      // close opportunity before create order
      Create_Order.closeOpportunity(recordId, 'Closed Won');
      return DocumentList;  // Return list of files on parent record
   }

  // create a new aproval
  @AuraEnabled
  public static string newGenehmigung(String contactId, String paragraph, String documentId){
    String str = '';
    String pg = '';
    if (paragraph == '51') {
      pg = 'PG54';
    }
    else if(paragraph == '54'){
      pg = 'PG51';
    }
    //
    Boolean status = contactStatusHelper.setAntragEingegangen(contactId, 'PG'+paragraph);
    if (status == true) {
      str = Create_Genehmigung.createGenehmigung(contactId, paragraph, documentId);
      Follow_Up_Task_Helper.updateFollowUpTask(contactId, 'Versand Formular an Interessent', 'Geschlossen');
      if (String.isNotEmpty(pg)) {
        updateContactStatus(contactId, pg);
      }
    }
    else {
      str = 'Fehler beim Kundenstatus';
    }
    return str;
  }
  //
  public static void updateContactStatus(String contactId, String pg){
    Contact_Status__c cs = new Contact_Status__c();
    try {
      cs = [SELECT Id, Status__c FROM Contact_Status__c WHERE Contact__c =:contactId AND ProductGroup__c =:pg ORDER BY CreatedDate DESC LIMIT 1];
    } catch (Exception e) {
      System.debug(e);
    }
    if ((cs != null) && (cs.Status__c == 'Interessent')){
      cs.Status__c = 'Vorgang geschlossen';
      try {
        update cs;
      } catch (Exception ex) {
        System.debug(ex);
      }
    }
  }
    @AuraEnabled
   public static Map<string,boolean> isTerminated(string contactId) {
        string PG51 = 'PG51';
        string PG54 = 'PG54';
        Map<String, Boolean> returnMap = new Map<String, Boolean>();
        returnMap.put(PG54, false);
        returnMap.put(PG51, false);
        List<Contact_Status__c> statusPG51 = [SELECT Status__c FROM Contact_Status__c where Contact__c =:contactId and Productgroup__c =:PG51];
        List<Contact_Status__c> statusPG54 = [SELECT Status__c FROM Contact_Status__c where Contact__c =:contactId and Productgroup__c =:PG54];
        if (statusPG54.size() != 0 ){
            if (statusPG54.get(0).Status__c == 'Kündigung') {
                returnMap.put(PG54, true);
            }
        }
        if (statusPG51.size() != 0 ){
            if (statusPG51.get(0).Status__c == 'Kündigung') {
                returnMap.put(PG51, true);
            }
        }
    return returnMap;
    }
  // navigate to aproval object
  @AuraEnabled
  public static String goToGenehmigung(String contactId, String paragraph){
    Follow_Up_Task_Helper.updateFollowUpTask(contactId, 'KV an Krankenkasse übermittelt', 'Geschlossen');
    return Create_Genehmigung.getGenehmigung(contactId, paragraph).Id;
  }
  
  //
  @AuraEnabled
  public static string getWunschCB(String contactId){
    return Product_List.getWunschCurabox(contactId);
  }

  @AuraEnabled
  public static string getContactRole(String contactId){
    String role = null;
    if(Curabox_Helper.getOpportunityByContact(contactId) != null){
      role = Curabox_Helper.getOpportunityByContact(contactId).Role;
    }
    return role;
  }

  // go to create order if contact has pflegegrad and Insurance is cooperativ.
  @AuraEnabled
  public static Boolean checkIfCreateOrder(String contactId){
    Boolean returnValue = false;
    if (checkPflegegradByContact(contactId) && checkInsuranceCooperativ(contactId)) {
      returnValue = true;
    }
    return returnValue;
  }

  /**
  *  check if contact has pflegegrad
  */
  public static Boolean checkPflegegradByContact(String contactId){
      Contact contact = Curabox_Helper.getContactById(contactId);
      Boolean returnValue = false;
      if (contact.Pflegegrad__c != null && !String.isEmpty(contact.Pflegegrad__c)) {
          returnValue = true;
      }
      return returnValue;
  }

  /**
  *  check if the Insurance is cooperativ
  */
  public static Boolean checkInsuranceCooperativ(String contactId){
      Contact contact = Curabox_Helper.getContactById(contactId);
      Account account = new Account();
      List<Account> accountList = new List<Account>();
      try{ 
          accountList = [select Id, Kooperativ__c from Account where Id =: contact.Kranken_Pflegekasse__c];
          if(accountList != null && accountList.size() > 0){
              account = accountList[0];
          }     
      }      
      catch(Exception e){
          System.debug(e);
      }
      return account.Kooperativ__c;
  }

}