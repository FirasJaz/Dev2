@isTest(SeeAllData = true)
private class task_after_update_test {
    static testMethod void myUnitTest() {
        test.starttest();
        Account KK = new Account();
        KK.Industry = 'Krankenkassen';
        KK.Name = 'TestKK';
        KK.type = 'Test';
        insert KK;
    
        Kunde__c kd = new Kunde__c (Krankenkasse__c = kk.id, Name__c = 'TestKunde', Produktgruppe__c='PG54');
        insert kd;
        
        Kundenstatus__c ks1 = new Kundenstatus__c( Kunde__c = kd.id,
                                                   Status__c = 'Kandidat',
                                                   Produktgruppe__c = 'Inko');
                                                                        
        
        insert ks1;
        Kundenstatus__c ks3 = new Kundenstatus__c( Kunde__c = kd.id,
                                                   Status__c = 'Kandidat',
                                                   Produktgruppe__c = 'PG54');
                                                                        
        
        insert ks3;
        Kundenstatus__c ks4 = new Kundenstatus__c( Kunde__c = kd.id,
                                                   Status__c = 'Kandidat',
                                                   Produktgruppe__c = 'PG51');

        list<RecordType> rtList = [SELECT Id, Name FROM RecordType WHERE sObjectType='task'];

        system.debug('############################alex100 rtList=' + rtList);
        
        
        id rtID = null;
        for(RecordType rtIDS : rtList) {
            if(rtIDS.Name == 'PG54') {
                rtID = rtIDS.id;
                break;
            }
        }
        system.debug('############################alex101 rtID=' + rtID);
        
        id grID = UserInfo.getUserId(); 
        list<Group> grList = [SELECT id FROM Group WHERE Name = 'Nachtelefonie' LIMIT 1];
        if((grList != null) && (grList.size() > 0)) {   
            grID = grList[0].id;
        }       
        list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                        FROM GroupMember WHERE GroupId = : grID];
        list<task> tsList = new list<task>();
        set<id> gmSet = new set<id>();
        if((gmList != null) && (gmList.size() > 0)) { 
            for(GroupMember GM : gmList) {
                Task t = new Task(ActivityDate = Date.today().addDays(21),
                                    Subject='Nachtelefonie von Interessenten',
                                    WhatId = Kd.ID,
                                    RecordTypeId = rtID,
                                    OwnerId = GM.UserOrGroupId,
                                    IsReminderSet = true,
                                    ReminderDateTime = System.now()+20,  
                                    Grund_des_Abbruchs__c = null,                                   
                                    Description = 'Nachtelefonie von Interessenten',                                        
                                    Status='Open');
                tsList.add(t);
                gmSet.add(GM.UserOrGroupId);
            }
            insert tsList; 
        }    
        test.stoptest();
        list<task> tsiList = [SELECT id, Status, RecordTypeId FROM task WHERE OwnerId IN :gmSet AND WhatId = :Kd.ID]; 
        
        
        if((tsiList != null) && (tsiList.size() > 0)) { 
            task tsu = tsiList[0];
            tsu.Status = 'Wiedervorlage';
            
            tsu.Grund_des_Abbruchs__c = 'Kunde nicht erreicht (1Tag)';
            tsu.RecordTypeId = rtID;
            update tsu;   
            /*
            tsu.Grund_des_Abbruchs__c = 'Noch kein Bedarf (3 Monate)';
            update tsu;                
            tsu.Grund_des_Abbruchs__c = 'Neues Formular verschickt (3 Tage)';
            update tsu;  
            tsu.Grund_des_Abbruchs__c = 'Kunde schickt Antrag los (7 Tage)';
            update tsu; 
            tsu.Grund_des_Abbruchs__c = 'Beim Kunden in Klärung (7 Tage)';
            update tsu;            
            tsu.Grund_des_Abbruchs__c = 'Neues Formular verschickt (3 Tage)';
            update tsu;     
            tsu.Grund_des_Abbruchs__c = 'Formular ist beim Kunden angekommen (2 Wochen)';
            update tsu;       
            */     
            tsu.Status = 'Geschlossen';
            update tsu;
            tsu.Status = 'Open';
            update tsu;
            tsu.Status = 'Abbruch';
            update tsu;
        }
        task_after_update.setLeereZeilen();
    }
}