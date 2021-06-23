public class curabox_tool_orders implements Database.Batchable<sObject>, Database.Stateful {
    
    public Database.querylocator start(Database.BatchableContext BC) {
        string query = 'select id, contact__c, product__c, order_line__c  from delivery_line__c where order_line__c = null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        set<id> ctSet = new Set<id>();
        List<delivery_line__c> dlList = (List<delivery_line__c>)scope;
        for(delivery_line__c dl : dlList) {
            ctSet.add(dl.contact__c);
        }
        List<Order__c> odList = [SELECT id, Contact__c from Order__c WHERE Status__c = 'aktiv' AND contact__c IN : ctSet];
        if((odList != null) && (odList.size() > 0)) {
            set<id> odSet = new Set<id>();
            for(Order__c od : odList) {
                odSet.add(od.id);
            }
            map<string, id> olMap = new map<string, id>();
            List<Order_Line__c> olList = [SELECT id, product__c, order__r.contact__c from order_line__c where order__c IN : odSet];
            if((olList != null) && (olList.size() > 0)) {
                for(order_line__c ol : olList) {
                    olMap.put(string.valueOf(ol.order__r.contact__c) + string.valueOf(ol.product__c), ol.id);  
                }                            
            }
            for(delivery_line__c dl : dlList) {
                string key = string.valueOf(dl.contact__c) + string.valueOf(dl.product__c);
                if(olMap.containsKey(key)) {
                    dl.order_line__c = olMap.get(key);
                }
            }           
            update dlList;
        }
    }

    public void finish(Database.BatchableContext bc){     
    } 
}