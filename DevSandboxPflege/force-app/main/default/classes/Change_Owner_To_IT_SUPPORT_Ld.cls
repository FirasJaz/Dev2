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
// Beschreibung: Ändern eines Lead-Inhabers auf "IT Support"
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/

global with sharing class Change_Owner_To_IT_SUPPORT_Ld {

    private Lead ld;
    private User us;
    
    global Change_Owner_To_IT_SUPPORT_Ld(ApexPages.StandardController stdController) {
        this.ld = (Lead)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference Change_owner() {
        String ldID = ApexPages.currentPage().getParameters().get('id');
        if (ldID == null) {
            // Display the Visualforce page's content if no Id is passed over 
            return null;
        }
        List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        if(user_list != null && user_list.size()>0){
            ld.ownerID = user_list[0].id;
            update ld;
        }
        
        // go back to the original page
        PageReference nextpage = new PageReference('/' + ldID);
        nextPage.setRedirect(true);
        return nextpage;  

  }
            
        }