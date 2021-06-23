@isTest
public class Lead_to_Opportunity_Auto_test {

    static testMethod void  testConversion() {
    
        Campaign camp = new Campaign(name ='testKSGcontroller');
        insert camp;
        
        boolean doppelt = false;
        id rtid = null;       
        id ownerid = UserInfo.getUserId();
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Notrufsysteme'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        
        lead l = new lead(Company='Notrufsysteme', Status='Open');
        l.RecordTypeId = rtid;  
        l.OwnerID = ownerid;
        l.OM_created_at__c = '2017-01-19T11:17:31+01:00';
        l.OM_Tracking_Order_ID__c = '8b7c8e7632116168ffb-197e6980fc19';
        l.TL_Treppenliftart__c = 'Mobile Notruflösung';
        l.OM_Referrer__c = 'http://service-neu.pflege.localhost/24h-pflege';
        l.TL_Postleitzahl_f_r_Suche__c = '22222';
        l.Wohnort_der_Suche__c = 'Hamburg';
        l.Person_des_Bedarfs__c = 'Für mich';
        l.Pflegegrad__c = 'Pflegegrad beantragt';
        l.Zeitpunkt_der_Versorgung__c = 'Schnellstmöglich';
        l.emergency_contact__c = 'Notrufzentrale';
        l.Email = 'test@test.de';
        l.Firstname = 'test';
        l.Lastname = 'test';
        l.Salutation = 'Frau';
        // check dulicate
        list<lead> doppList = [SELECT id FROM lead WHERE OM_Tracking_Order_ID__c = :l.OM_Tracking_Order_ID__c];
        if((doppList != null) && (doppList.size() > 0) ) doppelt = true;        
        // Ursprungsanfrage2
        List<Campaign> cmplist = [select id, name from Campaign where name =: 'testKSGcontroller' LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) {
            l.OM_Wizzard_Name2__c = cmplist[0].Id;      
        }
        if(!doppelt) {
            try {
                insert l;
                Lead_to_Opportunity_Auto.convertLeadToOpportunity(l);
            }catch(Exception e){
            }
        }
        
    }
    
    static testMethod void  testConversion_existing() {
    
        Campaign camp = new Campaign(name ='testKSGcontroller');
        insert camp;
        
        Contact c1 =  new Contact(firstname='test', lastname ='test', email= 'test@test.de');
        insert c1;
        
        Contact c2 =  new Contact(firstname='test', lastname ='test', email= 'test@test.de');
        insert c2;
        
        boolean doppelt = false;
        id rtid = null;       
        id ownerid = UserInfo.getUserId();
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name = 'Notrufsysteme'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        
        lead l = new lead(Company='Notrufsysteme', Status='Open');
        l.RecordTypeId = rtid;  
        l.OwnerID = ownerid;
        l.OM_created_at__c = '2017-01-19T11:17:31+01:00';
        l.OM_Tracking_Order_ID__c = '8b7c8e7632116168ffb-197e6980fc19';
        l.TL_Treppenliftart__c = 'Mobile Notruflösung';
        l.OM_Referrer__c = 'http://service-neu.pflege.localhost/24h-pflege';
        l.TL_Postleitzahl_f_r_Suche__c = '22222';
        l.Wohnort_der_Suche__c = 'Hamburg';
        l.Person_des_Bedarfs__c = 'Für mich';
        l.Pflegegrad__c = 'Pflegegrad beantragt';
        l.Zeitpunkt_der_Versorgung__c = 'Schnellstmöglich';
        l.emergency_contact__c = 'Notrufzentrale';
        l.Email = 'test@test.de';
        l.Firstname = 'test';
        l.Lastname = 'test';
        l.Salutation = 'Frau';
        // check dulicate
        list<lead> doppList = [SELECT id FROM lead WHERE OM_Tracking_Order_ID__c = :l.OM_Tracking_Order_ID__c];
        if((doppList != null) && (doppList.size() > 0) ) doppelt = true;        
        // Ursprungsanfrage2
        List<Campaign> cmplist = [select id, name from Campaign where name =: 'testKSGcontroller' LIMIT 1];        
        if(cmplist != null && cmplist.size() != 0) {
            l.OM_Wizzard_Name2__c = cmplist[0].Id;      
        }
        if(!doppelt) {
            try {
                insert l;
                Lead_to_Opportunity_Auto.convertLeadToOpportunity(l);
            }catch(Exception e){
            }
        }
        
    }
}