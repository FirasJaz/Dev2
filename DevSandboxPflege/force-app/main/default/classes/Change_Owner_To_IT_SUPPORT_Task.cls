//****************************************************************************************************************************
// Created  04.04.2018 von MZ
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
// Description: Chaanges the owner of the task back to "IT Support"
//
//
//****************************************************************************************************************************
// Changes:
//****************************************************************************************************************************/

global with sharing class Change_Owner_To_IT_SUPPORT_Task {

    private Task ts;
    private User us;
    
    global Change_Owner_To_IT_SUPPORT_Task(ApexPages.StandardController stdController) {
        this.ts = (Task)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference Change_owner() {
        String taskID = ApexPages.currentPage().getParameters().get('id');
        if (taskID == null) {
            // Display the Visualforce page's content if no Id is passed over 
            return null;
        }
        List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        if(user_list != null && user_list.size()>0){
            ts.ownerID = user_list[0].id;
            update ts;
        }
        
        // go back to the original page
        PageReference nextpage = new PageReference('/' +taskID);
        nextPage.setRedirect(true);
        return nextpage; 
   }

}