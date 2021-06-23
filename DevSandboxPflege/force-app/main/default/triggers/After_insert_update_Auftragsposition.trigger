///////////////////////////////////////////////////////////////////////////////////////////////
//
//		erstellt am 23.10.2012 sorgt dafür dass bei Fallpauschalen die Häkchen des Auftrags auf die
//								Auftragspositionen übernommen wird
//		deployed am 25.10.2012
//		geaendert am 20.12.2012 am 29.4.2012 deployed
///////////////////////////////////////////////////////////////////////////////////////////////
trigger After_insert_update_Auftragsposition on Auftragsposition__c (after insert, after update) {
	Boolean error = False;
	if (trigger.isinsert){
		error = Auftrag_Class.APos_insert(Trigger.new);
		if (error){
			System.debug('############## after_insert_update_apos: Fehler! sieher Fehler aus Auftrag_class');
		}
	}
	else if (trigger.isupdate){
		error = Auftrag_Class.APos_Update_Laufzettel(Trigger.newmap);
		if (error){
			System.debug('############## after_insert_update_apos: Fehler! sieher Fehler aus Auftrag_class');
		}
	}
}