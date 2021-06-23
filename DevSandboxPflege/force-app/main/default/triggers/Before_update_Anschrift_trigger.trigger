trigger Before_update_Anschrift_trigger on Anschrift__c (before update) {
    Adressverwaltung_class.update_adressen(trigger.old, trigger.new);
}