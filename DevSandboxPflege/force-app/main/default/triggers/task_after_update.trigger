trigger task_after_update on Task (after update) {
   List<Id> PGKdIdlist = new List<Id>();  
   List<Id> InkoKdIdlist = new List<Id>();
   RecordType PG54ReTyp =[Select Id, SobjectType, Name From RecordType WHERE Name = 'PG54'  AND SobjectType ='Task' LIMIT 1];
   RecordType PG51ReTyp =[Select Id, SobjectType, Name From RecordType WHERE Name = 'PG51'  AND SobjectType ='Task' LIMIT 1];
   RecordType InkoReTyp =[Select Id, SobjectType, Name From RecordType WHERE Name = 'Inko'  AND SobjectType ='Task' LIMIT 1];
   
   task_after_update.taskLoeschen(trigger.oldMap, trigger.newMap);
       
   for(Task tsk : Trigger.new) {
        if((tsk.isClosed == true) && (tsk.Status == 'Abbruch'))
        {
            if((tsk.RecordTypeId == PG54ReTyp.Id) || (tsk.RecordTypeId == PG51ReTyp.Id) )
            {
                PGKdIdlist.add(tsk.WhatId);
            }
            
            if(tsk.RecordTypeId == InkoReTyp.Id)
            {
                InkoKdIdlist.add(tsk.WhatId);
            }
        }
    }
    
    List<Kundenstatus__c> PGkslist = [SELECT Id, Kunde__c, Status__c, Produktgruppe__c FROM Kundenstatus__c WHERE Kunde__c IN :PGKdIdlist AND Produktgruppe__c IN ('PG51','PG54')]; 
    
    if((!PGkslist.isEmpty()) && (PGkslist.size() > 0)) {                        
        for(Kundenstatus__c ks: PGkslist) {                       
                ks.Status__c = 'Vorgang geschlossen';                                               
        }    
        
        try {
            update PGkslist;
        }
        catch(system.exception e) {
                    system.debug('######################### error update PGkslist' + e);
        }                 
    } 
    
    List<Kundenstatus__c> Inkokslist = [SELECT Id, Kunde__c, Status__c, Produktgruppe__c FROM Kundenstatus__c WHERE Kunde__c IN :InkoKdIdlist AND Produktgruppe__c = 'Inko']; 
    
    if((!Inkokslist.isEmpty()) && (Inkokslist.size() > 0)) {                        
        for(Kundenstatus__c ks: Inkokslist) {                       
                ks.Status__c = 'Vorgang geschlossen';                                               
        }    
        
        try {
            update Inkokslist;
        }
        catch(system.exception e) {
                    system.debug('######################### error update Inkokslist' + e);
        }                 
    } 
    

}