public class apos_loeschen_class
{
	public static void apos_loeschen_void (List<Auftragsposition__c> apos)
	{
		List<Lieferscheinposition__c> zu_loeschen = new List<Lieferscheinposition__c>{};
		List<Lieferscheinposition__c> akt_Lpos = new List<Lieferscheinposition__c>{};
		
		for (Auftragsposition__c ap : apos)
		{
			If (Ap.Genehmigungsstatus__c != 'genehmigt' && 
				Ap.Genehmigungsstatus__c != 'abgelehnt' &&
				Ap.Genehmigungsstatus__c != 'abgelaufen' ){
				akt_lpos = [Select Id from Lieferscheinposition__c where Auftragsposition__c =: Ap.ID];
				zu_loeschen.addall(akt_lpos);
			}else{
				string ae = 'Diese Auftragsposition hat den Status ' + Ap.Genehmigungsstatus__c + ' und kann deshalb nicht gelöscht werden!';
				ap.adderror(ae);			
			}	
		}
		try
		{
			delete zu_loeschen;
		}
		catch (system.dmlexception d)
		{
			system.debug ('Da ist was beim loeschen der LPos schief gegeangen: ' + zu_loeschen);
		}
	}
}