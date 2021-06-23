//****************************************************************************************************************************
// Created  04.04.2018 von Mz
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
// Description: change the task owner to current user
//                      
//
//
//****************************************************************************************************************************
// Cahnges:
//****************************************************************************************************************************/

global with sharing class Change_Owner_To_CurrentUser_Task {

    private Task ts;
    private User us;
    private static String msgOwnerIsNotIT = 'Dieser Aufgabe ist bereits durch Dich oder einen anderen Nutzer in Bearbeitung.';
    private static String noTask = 'No Tasks exists with specified Id.';
    
    global Change_Owner_To_CurrentUser_Task(ApexPages.StandardController stdController) {
        this.ts = (Task)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference Change_owner() {
        String taskID = ApexPages.currentPage().getParameters().get('id');
        List<Task> taskList= [select Id, ownerId from Task where Id = :taskID limit 1];
        if(taskList!= null && taskList.size()>0){
            this.ts = taskList[0];
            List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
            if(user_list != null && user_list.size()>0){
                if( user_list[0].id == ts.ownerID){
                    ts.ownerID = UserInfo.getUserID();
                    update ts;
                    
                    // go back to the original page
                    PageReference nextpage = new PageReference('/' + taskID );
                    nextPage.setRedirect(true);
                    return nextpage; 
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, msgOwnerIsNotIT ));
                }
            }
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noTask ));
        }
        return null;
   }
            
}