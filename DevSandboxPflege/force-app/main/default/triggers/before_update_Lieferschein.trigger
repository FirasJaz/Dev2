trigger before_update_Lieferschein on Lieferschein__c (before update) {
  Lieferscheinupdateunterschrift.updateLS(trigger.old, trigger.new);
}