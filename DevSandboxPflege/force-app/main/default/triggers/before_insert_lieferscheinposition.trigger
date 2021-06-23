trigger before_insert_lieferscheinposition on Lieferscheinposition__c (before insert) {
    List<Lieferscheinposition__c> updateList = new List<Lieferscheinposition__c>();
    List<Artikel__c> artList = [select id, a_pac_apo_EAN_UPC__c from Artikel__c where a_pac_apo_EAN_UPC__c =: decimal.valueOf('4031678000234') limit 1];    
    Set<Id> APIdset = new Set<Id>();
    Map<Id, Lieferscheinposition__c> LsPosMap = new Map<Id, Lieferscheinposition__c>();
    
    for(Lieferscheinposition__c lsPos: trigger.new)
    {
        if(lsPos.Auftragsposition__c != null) {
           APIdset.add(lsPos.Auftragsposition__c);
           LsPosMap.put(lsPos.Auftragsposition__c, lsPos);
        }  
    }
        
    List<Auftragsposition__c> APlist = [Select Id, Auftrag__c, Auftrag__r.Auftrag_text__c from Auftragsposition__c where Id IN: APIdset and Auftrag__r.Auftrag_text__c IN ('Muster-Artikel', 'Shop')];
    
    for(Auftragsposition__c AP: APlist) 
    {
        if(AP.Auftrag__r.Auftrag_text__c == 'Muster-Artikel') LsPosMap.get(Ap.id).Abrechnungsstatus_Krankenkasse__c = 'Kostenfreie Lieferung';
        if(AP.Auftrag__r.Auftrag_text__c == 'Shop') LsPosMap.get(Ap.id).Abrechnungsstatus_Krankenkasse__c = 'Abgerechnet über Magento';
        
        updateList.add(LsPosMap.get(Ap.id));
    }
     
    for(Lieferscheinposition__c lsPos: trigger.new)
    {
        if(artList != null && artList.size() > 0)
        {
            if(lsPos.Artikel__c != null) {
                if(lsPos.Artikel__c == artList[0].id) 
                {
                    lsPos.Abrechnungsstatus_Krankenkasse__c = 'Kostenfreie Lieferung';
                    updateList.add(lsPos);
                }
            }
        }
        
    }
    
    
    try{
        update updateList;
    }
    catch(System.Exception e)
    {
        System.debug('##############bt2016 : Lieferscheinpositionen konnten nicht upgedatet werden.');
    }
   
}