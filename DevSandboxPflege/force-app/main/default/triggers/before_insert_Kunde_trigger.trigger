trigger before_insert_Kunde_trigger on Kunde__c (before insert) {
    Adressverwaltung_class.neueKundennummer(trigger.new);
}