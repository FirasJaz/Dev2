///////////////////////////////////////////////////////////////////////////////////////////////
//
//      erstellt am 04.09.2015 sorgt dafür dass der Erstkontakt gefüllt wird
//
// geänder durch wds 07.09.2015 Erweitert um setzen Aufgabe 'NAchtelefonie Muster' wenn diese noch 
//                              nicht erstellt (bei manuelelr Auftragsanlage)
//
///////////////////////////////////////////////////////////////////////////////////////////////
trigger After_insert_Auftrag on Auftrag__c (after insert) {
  
    public Kundenstatus__c KDst {get; set;}
//    public task ts {get; set;}  
    public list<task> ts1List = new list<task>();
    
    for (Auftrag__c AU : Trigger.new) {
    
        if (AU.Bezeichnung__c == 'Muster-Artikel') {
            try {
                        
                KDst = [SELECT Erstkontakt_hartmann__c FROM Kundenstatus__c WHERE Kunde__c = :AU.kunde__c and Produktgruppe__c = 'Inko'];
             
                if (kdst.Erstkontakt_Hartmann__c == Null){
                    kdst.Erstkontakt_Hartmann__c = date.today();
                    update kdst;
                }
             
                list<task> Tslist = [select subject from Task where Whatid =: Au.Kunde__C];
                boolean NT = false;
                for(task ts : tsList) {
                    if (ts.subject == ('Nachtelefonie Inko-Muster')){
                         nt = true;
                    }
                }   
                     
                if (nt == false) {
                    id rtid = null;
                    list<RecordType> rtList = [SELECT Id, Name FROM RecordType WHERE sObjectType='Task' AND Name = :'Inko'];
                      
                    if((rtList != null) && (rtList.size() > 0)) {
                           rtid = rtList[0].id;
                    }
                      
                    id grID = UserInfo.getUserId(); 
                    list<Group> grList = [SELECT id FROM Group WHERE Name = 'Inko' LIMIT 1];                      
                    if((grList != null) && (grList.size() > 0)) {   
                          grID = grList[0].id;
                    } 
                    list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                              FROM GroupMember WHERE GroupId = : grID];
                    // list<task> ts1List = new list<task>();
                    if((gmList != null) && (gmList.size() > 0)) { 
                          for(GroupMember GM : gmList) {             
                              task newTaskM = new Task(ActivityDate = Date.today()+7,
                                                    Recordtypeid = rtid,
                                                    Description = 'xxx',
                                                    Priority = 'Normal',
                                                    Status = 'offen',
                                                    Subject = 'Nachtelefonie Inko-Muster',            
                                                    WhatId = au.kunde__c,
                                                    OwnerId = GM.UserOrGroupId,
                                                    IsReminderSet = false
                                                    );
                              // insert newTaskM;
                              ts1List.add(newTaskM);
                          } 
                      }  
                }
                    
            }
            catch(System.Exception e) {
                            
            }              
        } 
    }
    if(!ts1List.isEmpty()) {
        try {
            insert ts1List;
        }
        catch (System.Exception e) {
            
        }
    }
    
}