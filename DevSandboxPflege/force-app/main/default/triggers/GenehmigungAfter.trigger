trigger GenehmigungAfter on Genehmigung__c (after update) {
    map<id,Genehmigung__c> toProcessMap = new map<id, genehmigung__c>{};
    set<Id> lsIdSet = new set<Id>();
    set<Id> kdIdSet = new set<Id>();
    for (Genehmigung__c g : trigger.new){
        if (g.status__c == 'Bewilligung' || g.status__c == 'Teilbewilligung'){
            if (!toProcessMap.containskey(g.id)){
                toProcessMap.put(g.id, g);
            }
            if((trigger.oldMap.get(g.id).Status__c != 'Bewilligung') && (trigger.oldMap.get(g.id).Status__c != 'Teilbewilligung')) {
                kdIdSet.add(g.Kunde__c);
            }           
            
        }
        if(g.Status__c == 'Ablehnung') {
            lsIdSet.add(g.id);
            if(trigger.oldMap.get(g.id).Status__c != 'Ablehnung') {
                kdIdSet.add(g.Kunde__c);
            }           
        }
    }
    if (toProcessMap.size() != 0){
        Genehmigung.updAllLSPos(toProcessMap);
    }
    
    if(lsIdSet.size() > 0) {
        List<Lieferschein__c> LsList = [SELECT id, Status__c FROM Lieferschein__c WHERE Genehmigung__c IN : lsIdSet];
        if((lsIdSet != null) && (lsIdSet.size() > 0)) {
            for(Lieferschein__c LS : LsList) {
                LS.Status__c = 'abgelehnt';
            }
            try {
                update LsList;
            }
            catch(system.exception e) {
            
            }
        }
    }
    
    if(kdIdSet.size() > 0) {
        list<Kunde__c> kdList = [SELECT id, Antrag_bewilligt_abgelehnt_am__c FROM Kunde__c WHERE id IN : kdIdSet];
        if((kdList != null) && (kdList.size() > 0)) {
            for(Kunde__c kd : kdList) {
                kd.Antrag_bewilligt_abgelehnt_am__c = date.today();
            }
            try {
                update kdList;
            }
            catch (System.Exception e) {
                
            }
        }
    }
}