trigger Before_update_Kunde_trigger on Kunde__c (before update) {
    Adressverwaltung_class.update_kunden(trigger.old, trigger.new);
    
    // for (Kunde__c KD : Trigger.new) {
        // if ((trigger.OldMap.get(KD.id).status__c == 'Interessent') && 
            // (Kd.status__c == 'Kandidat' || Kd.status__c == 'Kunde' )) {
                // kd.Antrag_eingegangen_am__c = date.today();
        // }
    // }
    
    
}