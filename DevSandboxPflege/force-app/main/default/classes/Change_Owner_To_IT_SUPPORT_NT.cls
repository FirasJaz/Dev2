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
// Beschreibung: Ändern eines Nachtelefonie-Inhabers auf "IT Support"
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/

global with sharing class Change_Owner_To_IT_SUPPORT_NT {

    private Nachtelefonie__c NT;
    private User us;
    
    global Change_Owner_To_IT_SUPPORT_NT(ApexPages.StandardController stdController) {
        this.NT = (Nachtelefonie__c)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference Change_owner() {
        String NTID = ApexPages.currentPage().getParameters().get('id');
        if (NTID == null) {
            // Display the Visualforce page's content if no Id is passed over 
            return null;
        }
        List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        if(user_list != null && user_list.size()>0){
            NT.ownerID = user_list[0].id;
            update NT;
        }
        
        // go back to the original page
        PageReference nextpage = new PageReference('/' + NTID);
        nextPage.setRedirect(true);
        return nextpage;  

  }
            
        }