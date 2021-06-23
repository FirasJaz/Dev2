//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//      Autor:          HK
//      esrtellt:           12.9.2011
//      Version:        0.1
//      geändert:       HK
//      Beschreibung:   update Trigger für die Unterschriften an den Lieferscheinen -> sorgt für Unterschriften bei allen Lieferpos
//
//  erstellt am 12.9.2011 nam 12.9.2011 deployed
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
trigger after_update_lieferschein_trigger on Lieferschein__c (after update) {
    List<Lieferschein__c> newLS = Trigger.new;
    List<Lieferschein__c> oldLS = Trigger.old;
    Boolean error = Lieferscheinclass.updateUnterschriftenLiPos(newLS, oldLS);
    if ( !error ) {
        system.debug('################## Das hat funktioniert ') ;
    }
    else {
        system.debug('################## Das hat nicht funktioniert ') ;
    }
}