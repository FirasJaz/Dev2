//****************************************************************************************************************************
// Erstellt tt.mm.yyyy von YY
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// möglichst konkrete Beschreibung der Funktion der Klasse!
//
//
//****************************************************************************************************************************
//Änderungen:
//
// 26.08.2015 von wds: Taskgenerieren für Inko-Versorgung
// 28.08.2015 von wds: #012160852 Gratisprodukt in Gratisprobe geändert
// 01.09.2015 von wds: Recordtype eingebaut
//****************************************************************************************************************************


trigger After_insert_Kunde_trigger on Kunde__c (after insert) {
    Adressverwaltung_class.insert_neue_kunden(trigger.new);
    Statusverwaltung_Kunde_class.insert_neuen_kundenstatus(trigger.new);
    
    for (Kunde__c KD : Trigger.new){
    
    id grID = UserInfo.getUserId(); 
              list<Group> grList = [SELECT id FROM Group WHERE Name = 'Inko' LIMIT 1];
              if((grList != null) && (grList.size() > 0)) {   
                  grID = grList[0].id;
              }
              list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                          FROM GroupMember WHERE GroupId = : grID];
              list<task> tsList = new list<task>();
                if((gmList != null) && (gmList.size() > 0)) { 
                    for(GroupMember GM : gmList) {
                    
        if(KD.Produktgruppe__c.contains('Inko' )){
            id rtid = null;
            list<RecordType> rtList = [SELECT Id, Name FROM RecordType WHERE sObjectType='Task' AND Name = :'Inko'];
            if((rtList != null) && (rtList.size() > 0)) {
                rtid = rtList[0].id;
            } 
              
            if(Kd.next_step__c == 'Gratisprobe'){
             
                task newTaskM = new Task(ActivityDate = Date.today()+7,
                                    Recordtypeid = rtid,
                                    Description = 'xxx',
                                    Priority = 'Normal',
                                    Status = 'offen',
                                    Subject = 'Nachtelefonie Inko-Muster',            
                                    WhatId = Kd.ID,
                                    OwnerId = GM.UserOrGroupId,
                                    IsReminderSet = false
                                       );
                insert newTaskM;             }
                
             else{
             
                 if(kd.next_step__c == 'Beratung' || kd.next_step__c == 'Rezept'){
                 
                     task newTaskB = new Task(ActivityDate = Date.today()+1,
                                         Recordtypeid = rtid,
                                         Description = 'xxx',
                                         Priority = 'Normal',
                                         Status = 'offen',
                                         Subject = 'Inko Beratungsgespräch',            
                                         WhatId = Kd.ID,
                                         OwnerId = GM.UserOrGroupId,
                                         IsReminderSet = false);
                 
             // Insert the new Task
                     insert newTaskB;}
                     }
       } 
    }
}
}

}