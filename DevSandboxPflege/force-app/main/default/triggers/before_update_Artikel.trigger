trigger before_update_Artikel on Artikel__c (before update) {
    Preislisteneintrag.update_Artikel(trigger.old, trigger.new);
    Update_PZN_suche_class.Update_PZN_suche(trigger.old,trigger.new);
}