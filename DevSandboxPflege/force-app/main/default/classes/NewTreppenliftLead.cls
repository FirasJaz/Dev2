/****************************************************************************************************************************
//  Erstellt 13.09.2016 von MZ
//  Klose und Srocke Gesellschaft fÃ¼r kreative KonfliktlÃ¶sungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:
// New Treppenlift Lead
//
//****************************************************************************************************************************
//Änderungen:
//****************************************************************************************************************************
*/
global with sharing class NewTreppenliftLead{
    
     public string message {get; set;}
     public string message_layout;
     public string modalDialogLayout {get; set;}
     public Lead formObj {get; set;}
        
     global NewTreppenliftLead(ApexPages.StandardController controller) {
           
     }
           
     global NewTreppenliftLead() {
         formObj = new Lead();
         formObj.Company = 'Treppenlift';
         formObj.Status = 'Open';
         
         List<RecordType> rtList = [select Id, Name, DeveloperName, SObjectType from RecordType where Name = 'Treppenlift' and SobjectType = 'Lead' limit 1];
         if(rtList !=null && rtList.size() > 0){
             formObj.RecordTypeId= rtList[0].Id;
         }else{
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No recordtType "Treppenlift" found for SobjectType "Lead"!'));
         }
         
     }
    
     
     
     public string getMessage_layout(){
        if(message == null){
            return 'none';
        }
        else {
            return 'initial';
        }
    } 
    
    public PageReference zuLeads(){
        //List<ListView> listViewList = [select Id, Name, SobjectType, DeveloperName from ListView where DeveloperName = 'Treppenlift_eingang' and SobjectType = 'Lead' limit 1 ];
        //if(listViewList != null && listViewList.size()>0){
            PageReference PageRef = new PageReference('/00Q/o');
            PageRef.setRedirect(true);
            return PageRef;
        //}
        //return null;
    } 
    
    public PageReference speichern(){  
        
        insert formObj;
        
        if(formObj.Id != null){
            PageReference PageRef = new PageReference('/' + formObj.Id);
            PageRef.setRedirect(true);
                      
            return PageRef;
        }
        return null;
    }   
     
}