//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//      Autor:          HK
//      Stand:          25.7.2011
//      Version:        0.1
//      geändert:       HK
//      Beschreibung:   Dieser Trigger sorgt dafür, dass bei geänderten Abrechnungszeiträumen einer Lieferscheinposition, 
//                      alle folgenden Bedarfe entsprechend geändert werden
//
//  erstellt am 25.7.2011 am 23.8.2011 deployed!
//                  -   Abrechnungszeiträume müssen ohne Lücke sein!
//  geändert am 18.10.2011 diese Änderung wird nicht deployed! zumindest nicht so!!!!!!
//                  -   das Ganze Thema Abrechnungszeiten hat keine Relevanz mehr, weil nur noch jeweils ein Bedarf erstellt wird!
//                  - stattdessen muss jetzt etwas getan werden, falls die Unterschrift gesetzt oder entfernt wird -> 
//                          Krankenkassenabrechnungskennzeichen entsprechend setzen
//  ACHTUNG: das geht so nicht, da wir den Record beim updateTrigge gelockt haben, können wir das Abrechnungsfeld nicht beschreiben. 
//              DESHALB WIRD DER TRIGGER AUF INAKTIV GESETZT. Stattdessen muss das Abrechenbarfeld ein Salesforce Formelfeld sein!
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


trigger after_update_Lieferposition_trigger on Lieferscheinposition__c (after update) {
    Map<ID,Lieferscheinposition__c> TriggerOldMap = new Map<ID,Lieferscheinposition__c>{};
    Map<ID,Lieferscheinposition__c> TriggerNewMap = new Map<ID,Lieferscheinposition__c>{};
    Set<ID> LPIdSet = new Set<Id>();
    List<Lieferscheinposition__c> LPList = new List<Lieferscheinposition__c>{};

    For (Lieferscheinposition__c P : Trigger.old) {
        TriggerOldMap.put(P.ID,P);
    }
    For (Lieferscheinposition__c P : Trigger.new) {
        TriggerNewMap.put(P.ID,P);
    }

    LPIdSet = TriggerOldMap.keyset();
    For (ID aktID : LPIDSet){
        if (TriggerOldMap.get(aktID).Unterschrift__c != TriggerNewMap.get(aktID).Unterschrift__c){
            LPList.add(TriggerNewMap.get(aktID));
        }
    }
    
    System.debug ('after_update_Lieferposition_trigger hat folgende zu ändernde LiPos gefunden ' + LPList);
    
    Boolean error = Lieferscheinclass.updateabrechenbareLPs(LPList);
    if ( !error ) {
        system.debug('################## Das hat funktioniert ') ;
    }
    else {
        system.debug('################## Das hat nicht funktioniert ') ;
    }

//  -   geändert am 18.10.2011 !!!! wird nicht mehr gebraucht (s.o.)

//    Set<ID> APIDs = new Set<ID>();
//    Integer laenge = oldLPs.size();
//    For (Integer i = 0; i < laenge; i++){
//        if ( oldLPs[i].AZ_bis__c != newLPs[i].AZ_bis__c){
//            if (!APIDs.contains(oldLPs[i].Auftragsposition__c)){
//                APIDs.add(oldLPs[i].Auftragsposition__c);
//            }
//        }
//    }
//    
//    System.debug ('after_update_Lieferposition_trigger aufgerufen mit ' + APIDs);
//    For (ID AP : APIDs){
//        tempList = Lieferscheinclass.Abrechnugszeiten_anpassen(AP);
//        LpList.addAll(tempList);
//    }
//    
//    System.debug ('after_update_Lieferposition_trigger hat folgende zu ändernde LiPos ' + LPList);
//    if ( LPList != null && LPList.size() != 0){
//        try {
//            update LPList;
//        }
//        catch (system.dmlexception d){
//                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
//                    'Einige Lieferscheinpositionen konnten nicht angepasst werden! ' + d);
//                ApexPages.addMessage(myMsg);
//        }
//    }
}