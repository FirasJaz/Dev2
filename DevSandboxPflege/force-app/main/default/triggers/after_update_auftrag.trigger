///////////////////////////////////////////////////////////////////////////////////////////////
//
//		erstellt am 23.10.2012 sorgt dafür dass bei Fallpauschalen die Häkchen des Auftrags auf die
//								Auftragspositionen übernommen wird
//		deployed am 25.10.2012
//		geaendert am 20.12.2012 am 29.4.2012 deployed
//
///////////////////////////////////////////////////////////////////////////////////////////////
trigger after_update_auftrag on Auftrag__c (after update) {
	map<Id, Auftrag__c> AuMap = new map<Id, Auftrag__c>{};
	Boolean error = False;
	for (id aktid : Trigger.oldmap.keySet()){
		if (Trigger.newmap.get(aktid).Fallpauschale__c != null){
			boolean Dok_alt = Trigger.oldmap.get(aktid).Dokumentation__c;
			boolean Dok_neu = Trigger.newmap.get(aktid).Dokumentation__c;
			boolean Rez_alt = Trigger.oldmap.get(aktid).Rezept__c;
			boolean Rez_neu = Trigger.newmap.get(aktid).Rezept__c;
			boolean Ant_alt = Trigger.oldmap.get(aktid).R_ckantwort__c;
			boolean Ant_neu = Trigger.newmap.get(aktid).R_ckantwort__c;
			boolean Gen_alt = Trigger.oldmap.get(aktid).Originalgenehmigung__c;
			boolean Gen_neu = Trigger.newmap.get(aktid).Originalgenehmigung__c;
			if (Dok_alt != Dok_neu || Rez_alt != Rez_neu || Ant_alt != Ant_neu || Gen_alt != Gen_Neu){
				AuMap.put(aktid, Trigger.newmap.get(aktid));
			}
		}
	}
	if ( AUMap.size() != 0){
		error = auftrag_class.Auftrag_update_Laufzettel(AuMap);
	}
	if (error){
		System.debug('############## after_update_Auftrag: Fehler! sieher Fehler aus Auftrag_class');
	}
}