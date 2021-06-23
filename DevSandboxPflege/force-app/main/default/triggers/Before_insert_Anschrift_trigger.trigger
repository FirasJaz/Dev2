trigger Before_insert_Anschrift_trigger on Anschrift__c (before insert) {
    Adressverwaltung_class.insert_neue_adressen(trigger.new);
}