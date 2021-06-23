trigger after_update_delivery_note on Delivery_Note__c (after update) {
    Set<Id> ContIdset = new Set<Id>();
    Set<Id> dnSet = new Set<Id>();
    Set<Id> gn51Set = new Set<Id>();
    Set<Id> gn54Set = new Set<Id>();
    Map<Id, Contact> ContMap = new Map<Id, Contact>();

    for (Delivery_Note__c dn: Trigger.new) {
        if(dn.pod_recieved__c == true && trigger.OldMap.get(dn.id).pod_recieved__c == false) {
            ContIdset.add(dn.Contact__c);
            dnSet.add(dn.id);
        }
    } 

    if(!dnSet.isEmpty()) {
        List<Curabox_Genehmigung__c> gnList = [SELECT id, Nach_Paragraph__c, Contact__c 
                                                FROM Curabox_Genehmigung__c 
                                                WHERE Contact__c IN : ContIdset 
                                                AND Status__c = 'Bewilligung'];
        if((gnList != null) && (gnList.size() > 0)) {
            for(Curabox_Genehmigung__c gn : gnList) {
                if((gn.Nach_Paragraph__c == '54') || (gn.Nach_Paragraph__c == '5X')) gn54Set.add(gn.Contact__c);
                if((gn.Nach_Paragraph__c == '51') || (gn.Nach_Paragraph__c == '5X')) gn51Set.add(gn.Contact__c);
            }
        }
        List<Delivery_Line__c> dlList = [SELECT id, Contact__c, Abrechnungsstatus_Krankenkasse__c, Delivery_note__r.Delivery_text__c 
                                            FROM Delivery_Line__c 
                                            WHERE Delivery_Note__c IN :dnSet
                                            AND Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar'];
        if((dlList != null) && (dlList.size() > 0)) {
            for(Delivery_Line__c dl : dlList) {
                if(dl.Delivery_Note__r.Delivery_text__c == 'KUWV') {
                    if(gn51Set.contains(dl.Contact__c)) {
                        dl.Abrechnungsstatus_Krankenkasse__c ='abrechenbar';
                    }
                }
                else {
                    if(gn54Set.contains(dl.Contact__c)) {
                        dl.Abrechnungsstatus_Krankenkasse__c ='abrechenbar';
                    }
                }
            }
            Database.SaveResult[]  sruList = Database.update(dlList, false);
        }
    }
}