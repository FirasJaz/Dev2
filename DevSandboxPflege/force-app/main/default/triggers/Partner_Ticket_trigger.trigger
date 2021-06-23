trigger Partner_Ticket_trigger on Partner_Ticket__c  (after delete, after insert, after undelete, after update) {
    set<id> ppSet = new set<id>();
    
    if((trigger.isInsert) || (trigger.isUndelete)) {
        for (Partner_Ticket__c a : trigger.New) ppSet.add(a.Partner_Produkt__c);
    }

    if(trigger.isDelete) {
        for (Partner_Ticket__c a : trigger.Old) ppSet.add(a.Partner_Produkt__c);
    }

    if(trigger.isUpdate) {
        for (Partner_Ticket__c a : trigger.New) {
            if(a.Ticket_vom_Partner_storniert__c == true) ppSet.add(a.Partner_Produkt__c);
        }
    }
    try {
        if(!ppSet.isEmpty()) {
            set<id> ugedatetSet = new set<id>();
            set<id> ugedatetSet_per_day = new set<id>();
            set<id> ugedatetSet_per_month = new set<id>();
            
            List<Partner_Produkte__c> ppList = [SELECT id, Kontingent_Auslastung__c, Kontingent_Auslastung_pro_Tag__c, Kontingent_Auslastung_pro_Monat__c FROM Partner_Produkte__c WHERE id IN : ppSet];
            
            map<id, Partner_Produkte__c> ppMap = new map<id, Partner_Produkte__c>();
            Set<id> accSet = new Set<Id>();
            map<id, Account> accMap = new map<id, Account>();
            
            if((ppList != null) && (ppList.size()>0)) 
                for(Partner_Produkte__c pp : ppList) ppMap.put(pp.id, pp);

            list<AggregateResult> ptList = [SELECT Partner_Produkt__c, COUNT(id) cnt 
                    FROM Partner_Ticket__c 
                    WHERE Partner_Produkt__c IN : ppSet
                    AND CreatedDate = THIS_WEEK
                    AND Ticket_vom_Partner_storniert__c = false
                    GROUP BY Partner_Produkt__c];
                    
            list<AggregateResult> ptList_day = [SELECT Partner_Produkt__c, COUNT(id) cnt 
                    FROM Partner_Ticket__c 
                    WHERE Partner_Produkt__c IN : ppSet
                    AND CreatedDate = TODAY
                    AND Ticket_vom_Partner_storniert__c = false
                    GROUP BY Partner_Produkt__c];
            
            list<AggregateResult> ptList_month = [SELECT Partner_Produkt__c, COUNT(id) cnt 
                    FROM Partner_Ticket__c 
                    WHERE Partner_Produkt__c IN : ppSet
                    AND CreatedDate = THIS_MONTH
                    AND Ticket_vom_Partner_storniert__c = false
                    GROUP BY Partner_Produkt__c];

            if((ptList != null) && (ptList.size()>0)) {
                
                for(AggregateResult ar : ptList) {
                    integer Kontingent_Auslastung = (integer)ar.get('cnt');
                    id ppid = (id)ar.get('Partner_Produkt__c');
                    if(ppMap.ContainsKey(ppid)) {
                        Partner_Produkte__c pp = ppMap.get(ppid);
                        pp.Kontingent_Auslastung__c = decimal.valueOf(Kontingent_Auslastung);
                        ppMap.put(ppid, pp);
                        ugedatetSet.add(ppid);
                    }
                }
            }
            
            if((ptList_day != null) && (ptList_day.size()>0)) {
                for(AggregateResult ar : ptList_day) {
                    integer Kontingent_Auslastung_per_day = (integer)ar.get('cnt');
                    id ppid = (id)ar.get('Partner_Produkt__c');
                    if(ppMap.ContainsKey(ppid)) {
                        Partner_Produkte__c pp = ppMap.get(ppid);
                        pp.Kontingent_Auslastung_pro_Tag__c = decimal.valueOf(Kontingent_Auslastung_per_day);
                        ppMap.put(ppid, pp);
                        ugedatetSet_per_day.add(ppid);
                    }
                }
             }
                
             if((ptList_month != null) && (ptList_month.size()>0)) {
                for(AggregateResult ar : ptList_month) {
                    integer Kontingent_Auslastung_per_month = (integer)ar.get('cnt');
                    id ppid = (id)ar.get('Partner_Produkt__c');
                    if(ppMap.ContainsKey(ppid)) {
                        Partner_Produkte__c pp = ppMap.get(ppid);
                        pp.Kontingent_Auslastung_pro_Monat__c = decimal.valueOf(Kontingent_Auslastung_per_month);
                        ppMap.put(ppid, pp);
                        ugedatetSet_per_month.add(ppid);
                    }
                }
            }

            for(Partner_Produkte__c pp : ppMap.values()) {
                if(!ugedatetSet.contains(pp.id)) {
                    pp.Kontingent_Auslastung__c = 0;
                    ppMap.put(pp.id, pp);
                }
                if(!ugedatetSet_per_day.contains(pp.id)) {
                    pp.Kontingent_Auslastung_pro_Tag__c = 0;
                    ppMap.put(pp.id, pp);
                }
                if(!ugedatetSet_per_month.contains(pp.id)) {
                    pp.Kontingent_Auslastung_pro_Monat__c = 0;
                    ppMap.put(pp.id, pp);
                }
            }

            try {
                update ppMap.values();
            }
            catch(System.Exception e) {}
            
        }
    }
    catch (System.Exception e) {}

}