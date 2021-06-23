/****************************************************************************************************************************
// Erstellt 15.10.2016 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//    notice that public string values are used in trigger "sendEmailOnAbbruchgerundEdit" and "AbbruchOnAbbruchgerundEdit"
//****************************************************************************************************************************
// Änderungen:
//  13.06.2017    MZ    change the opportunity status to Erfolg
//  12.06.2018	  MZ	00001549 - if Bad-umbau, opportunity status should not change.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global with sharing class Nachtelefonie_Erreicht {

    private Nachtelefonie__c n;
    private static String ownerError = 'Zur Weiterverarbeitung musst du Inhaber des Datensatzes sein';
    
    global Nachtelefonie_Erreicht(ApexPages.StandardController stdController) {
        this.n = (Nachtelefonie__c)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference erreicht() {
        
        String nId = ApexPages.currentPage().getParameters().get('id');
        
        if (nId == null) {
            // Display the Visualforce page's content if no Id is passed over 
            return null;
        }
        if(isOwner(nId)){
        List<Nachtelefonie__c> n_list = [select id, Status__c, opportunity__c from Nachtelefonie__c where id = :nId  limit 1];
        if(n_list != null && n_list.size()>0){
            n = n_list[0];
            n.Status__c = 'Geschlossen'; 
            update n;
        
            List<Opportunity> opp_list = [select id, OwnerID, stageName, recordType.Name from Opportunity where Id = :n.opportunity__c limit 1];
            if(opp_list != null && opp_list.size()>0){
                Opportunity opp = opp_list[0];
                Opp.OwnerID = UserInfo.getUserID();
                if(opp.recordType.Name != PLZTool_Basis.rtBadumbau ){
                    Opp.stageName = 'Erfolg';
                }
                update opp;
            }
        
            // go back to the original page
            PageReference nextpage = new PageReference('/' + n.opportunity__c);
            nextPage.setRedirect(true);
            return nextpage;              
        }
        }
        // Display the Visualforce page's content if no Id is passed over 
        return null;
 
  }
  
  public boolean isOwner(Id nachtelefonieId){
        Nachtelefonie__c nc = new Nachtelefonie__c();
        List<Nachtelefonie__c> ncList =  [select Id, Owner.Id from Nachtelefonie__c where id = :nachtelefonieId limit 1];
        if(ncList != null && ncList.size()>0){
            nc = ncList [0];
            if(nc.Owner.Id != UserInfo.getUserId()){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ownerError ));
                return False;
            }
        }
        return True;
    }         
}