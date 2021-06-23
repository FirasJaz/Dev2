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
// Beschreibung: Ändern eines Opportunity-Inhabers auf aktiven Nutzer
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/

global with sharing class Change_Owner_To_CurrentUser_Op {

    private Opportunity Op;
    private User us;
    private static String msgOwnerIsNotIT = 'Diese Opportunity ist bereits durch Dich oder einen anderen Nutzer in Bearbeitung.';
    private static String noOpp = 'No Opportunities exists with specified Id.';
    
    global Change_Owner_To_CurrentUser_op(ApexPages.StandardController stdController) {
        this.op = (Opportunity)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference Change_owner() {
        String opID = ApexPages.currentPage().getParameters().get('id');
        List<Opportunity> oppList = [select Id, ownerId from Opportunity where Id = :opID limit 1];
        if(oppList != null && oppList.size()>0){
            this.op = oppList[0];
            List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
            if(user_list != null && user_list.size()>0){
                if( user_list[0].id == op.ownerId){
                    op.ownerID = UserInfo.getUserID();
                    update op;
                    
                    // go back to the original page
                    PageReference nextpage = new PageReference('/' + opID );
                    nextPage.setRedirect(true);
                    return nextpage; 
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, msgOwnerIsNotIT ));
                }
            }
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noOpp ));
        }
        return null;
    }
            
}