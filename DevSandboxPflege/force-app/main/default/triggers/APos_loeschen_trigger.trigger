trigger APos_loeschen_trigger on Auftragsposition__c (before delete) 
{
    apos_loeschen_class.apos_loeschen_void (Trigger.old);   
}