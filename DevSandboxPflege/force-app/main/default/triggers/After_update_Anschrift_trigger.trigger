trigger After_update_Anschrift_trigger on Anschrift__c (after update) {
if(Adressverwaltung_class.AdressenUpdated == false)
{
   // Adressverwaltung_class.update_adressen(trigger.old, trigger.new);
   // Adressverwaltung_class.AdressenUpdated = true;
  }
}