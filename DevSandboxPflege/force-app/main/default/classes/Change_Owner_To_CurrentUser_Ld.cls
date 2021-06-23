//****************************************************************************************************************************
// Erstellt 22.06.2016 von AM
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
// Beschreibung: Ändern eines Lead-Inhabers auf aktiven Nutzer
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/

global with sharing class Change_Owner_To_CurrentUser_Ld {

    private Lead ld;
    private User us;
    private static String msgOwnerIsNotIT = 'Dieser Lead ist bereits durch Dich oder einen anderen Nutzer in Bearbeitung.';
    private static String noLD = 'No Leads exists with specified Id.';
    
    global Change_Owner_To_CurrentUser_Ld(ApexPages.StandardController stdController) {
        this.ld = (Lead)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference Change_owner() {
        String ldID = ApexPages.currentPage().getParameters().get('id');
        List<Lead> ldList= [select Id, ownerId from Lead where Id = :ldID limit 1];
        if(ldList != null && ldList.size()>0){
            this.ld = ldList[0];
            List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
            if(user_list != null && user_list.size()>0){
                if( user_list[0].id == ld.ownerID){
                    ld.ownerID = UserInfo.getUserID();
                    update ld;
                    
                    // go back to the original page
                    PageReference nextpage = new PageReference('/' + ldID );
                    nextPage.setRedirect(true);
                    return nextpage; 
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, msgOwnerIsNotIT ));
                }
            }
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noLD ));
        }
        return null;
   }
            
}