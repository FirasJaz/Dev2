//****************************************************************************************************************************
// Erstellt 29.06.2016 von TK
//          Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//          Nordkanalstrasse 58
//          20097 Hamburg 
//          Tel.:  04064917161
//          Fax.:  04064917162
//          Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung: Ändern eines Nachtelefonie-Inhabers auf aktiven Nutzer
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/

global with sharing class Change_Owner_To_CurrentUser_NT {

    private Nachtelefonie__c NT;
    private User us;
    private static String msgOwnerIsNotIT = 'Diese Nachtelefonie ist bereits durch Dich oder einen anderen Nutzer in Bearbeitung.';
    private static String noNT = 'No Nachtelefonies exists with specified Id.';
    
    global Change_Owner_To_CurrentUser_NT(ApexPages.StandardController stdController) {
        this.NT = (Nachtelefonie__c)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference Change_owner() {
        String NTID = ApexPages.currentPage().getParameters().get('id');
        List<Nachtelefonie__c> ntList = [select Id, ownerId from Nachtelefonie__c where Id = :NTID limit 1];
        if(ntList != null && ntList .size()>0){
            this.NT = ntList [0];
            List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
            if(user_list != null && user_list.size()>0){
                if( user_list[0].id == NT.ownerId){
                    NT.ownerID = UserInfo.getUserID();
                    update NT;
                    
                    // go back to the original page
                    PageReference nextpage = new PageReference('/' + NTID );
                    nextPage.setRedirect(true);
                    return nextpage; 
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, msgOwnerIsNotIT ));
                }
            }
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noNT ));
        }
        return null;
  }
            
        }