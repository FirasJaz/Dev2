@IsTest
private class SunacareMail_test {
	private static Date d = Date.today().addMonths(36);
	private static String emailText = 'partnerid:PID2102002	rcc_gewuenschterbetreuungsbeginn:{{allg.betreuungsbeginn}}	rcc_einsatzort:{{allg.einsatzort}}	rcc_hauswirtschaftlichegrundversorgung:{{hilfe.hwgv}}	rcc_einkaufen:{{hilfe.einkaufen}}	rcc_begleitungzumarzt:true	rcc_hilfebeigrundundintimpflege:{{hilfe.guipflege}}	rcc_hilfebeitoilettengang:{{hilfe.toilette}}	rcc_naechtlicheinsaetze:{{hilfe.naechtlich}}	rcc_geschlechtpflegekraft:{{anf.geschlecht}}	rcc_deutschkenntnisse:{{anf.deutsch}}	rcc_fuehrerschein:121070000	rcc_rachgewohnheiten:121070002	rcc_anzahlzubetreuendekunde:{{pb.anzahl}}	rcc_weitereimhaushaltlebendeperson:0	rcc_geschlechtkunde1:{{pb1.geschlecht}}	rcc_gewichtkunde1:{{pb1.gewicht}}	rcc_pflegestufekunde:{{pb1.pflegestufe}}	rcc_mobilitaetkunde1:{{pb1.mobilitaet}}	rcc_demenzkunde1:{{pb1.demenz}}	rcc_geschlechtkunde2:	rcc_gewichtkunde2:	rcc_pflegestufekunde2:	rcc_mobilitaetkunde2:	rcc_demenzkunde2:	emailadress1:{{c.email}}	rcc_anrede:{{c.anrede}}	firstname:{{c.firstname}}	lastname:{{c.lastname}}	telephone1:{{c.telefon}}';

	@TestSetup static void setupCreateOpp() {
		Opportunity opp = new Opportunity();
		OpportunityContactRole ocr = new OpportunityContactRole();
		Account a = new Account(Name = 'Test');
		insert a;
		Strukturierte_Partner_Emails__c sc =
				new Strukturierte_Partner_Emails__c(Name = 'Test Sunacare', Email_Subject__c = 'SCLEAD-PID2102002',
						Inhalt_der_Email__c = emailText);
		Contact c =
				new Contact( AccountId = a.Id, LastName = 'TestLastName', FirstName = 'TestFirstName', Salutation = 'Herr',
						Email = 'mail@example.org', Phone = '0123456789', Pflegegrad__c = 'Pflegegrad beantragt');
		insert c;
		opp.Zeitpunkt_der_Versorgung__c = 'Innerhalb von 2 Wochen';
		opp.Anzahl_zu_betreuender_Personen__c = '1';
		opp.Name = 'TestOpp';
		opp.StageName = 'TestOpp';
		opp.CloseDate = d;
		opp.Nachteinsaetze__c = 'Ja, gelegentlich';
		opp.Hauswirtschaftsleistungen__c = true;
		opp.Alternative_Postleitzahl__c = '22451';
		opp.ContactId = c.Id;
		opp.Mobilit_t_des_Seniors__c = 'Rollator';
		opp.Geschlecht_der_Betreuungskraft__c = 'Weiblich';
		opp.Deutschkenntnisse_der_Betreuungskraft__c = 'Mittel';
		opp.Leichte_Pflege__c = 'Unterstützung Toilettengang;Körperpflege';
		opp.Betreuung__c = 'Dementenbetreuung';
		opp.Hauswirtschaft__c = 'Hilfe beim Einkaufen';
		insert opp;
		Account aa = new Account(Name = 'Test22');
		insert aa;
		Partner_Produkte__c pp = new Partner_Produkte__c(Name = 'Testprodukt',Anmerkung__c = 'TestAnmerkung',Partner__c = a.Id);
		insert pp;
		string id = [select Id from Partner_Produkte__c where Partner__c = :a.Id].Id;
		ocr.ContactId = opp.ContactId;
		ocr.OpportunityId = opp.Id;
		ocr.Role = 'PB = ASP';
		Partner_Ticket__c pt = new Partner_Ticket__c(Opportunity__c = opp.Id, Partner__r = a, Partner_Produkt__r = pp);
		insert sc;
		insert ocr;
		insert pt;
	}

	@IsTest static void testQueryAspWithAspPbRole() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate =:d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		List<Contact> c = sm.queryAsp();
		Test.stopTest();
		System.assertEquals(c.get(0).Id, sm.pbObj.get(0).Id);
	}

	@IsTest static void testQueryAspWithAspRole() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		OpportunityContactRole opp = [SELECT Role from OpportunityContactRole WHERE OpportunityId = :id].get(0);
		opp.Role = 'ASP';
		update opp;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		List<Contact> c = sm.queryAsp();
		OpportunityContactRole ocr =
				[SELECT ContactId FROM OpportunityContactRole where Role = 'ASP' and OpportunityId = :id].get(0);
		Test.stopTest();
		System.assertEquals(c.get(0).Id, ocr.ContactId);
	}

	@IsTest static void testQueryOpportunityNotNull() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		Opportunity o = sm.queryOpp();
		Test.stopTest();
		// Result not NULL
		System.assertNotEquals(o, null);
		System.assertEquals(o.Id, id);
	}

	@IsTest static void testGetCareStartWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCareStart();
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetCareStartWithEmptyResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Opportunity opp = [SELECT Zeitpunkt_der_Versorgung__c FROM Opportunity WHERE Id =:id];
		opp.Zeitpunkt_der_Versorgung__c = null;
		update opp;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCareStart();
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testGetPostalCodeWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getPostalCode();
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetPostalCodeWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Opportunity opp = [SELECT Alternative_Postleitzahl__c FROM Opportunity WHERE Id =:id];
		opp.Alternative_Postleitzahl__c = null;
		update opp;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getPostalCode();
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testGetCEmailWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCEmail(0);
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetCEmailWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Contact c = [SELECT Email from Contact WHERE FirstName = 'TestFirstName'];
		c.Email = null;
		update c;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCEmail(0);
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testGetCSalutationWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCSalutation(0);
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetCSalutationWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Contact c = [SELECT Salutation from Contact WHERE FirstName = 'TestFirstName'];
		c.Salutation = null;
		update c;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCSalutation(0);
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testGetCFirstNameWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCFirstName(0);
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetCFirstNameWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Contact c = [SELECT FirstName from Contact WHERE FirstName = 'TestFirstName'];
		c.FirstName = null;
		update c;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCFirstName(0);
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testGetCLastNameWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCLastName(0);
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetCPhoneWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCPhone(0);
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetCPhoneWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Contact c = [SELECT Phone from Contact WHERE FirstName = 'TestFirstName'];
		c.Phone = null;
		update c;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCPhone(0);
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testCountPBsWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.countPBs();
		Test.stopTest();
		System.assertNotEquals(res, '');
	}


	@IsTest static void testGetSalutationWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getSalutation(0);
		Test.stopTest();
		System.assertNotEquals(res, '');

	}

	@IsTest static void testGetPflegegradWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getPflegeStufeKunde();
		Test.stopTest();
		System.assertNotEquals(res, '');
		System.assertEquals(res, '121070004');
	}


	@IsTest static void testGetMobilityWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getMobility();
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetMobilityWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Opportunity opp = [SELECT Mobilit_t_des_Seniors__c FROM Opportunity WHERE Id=:id];
		opp.Mobilit_t_des_Seniors__c = '';
		update opp;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getMobility();
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testGetDementiaWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getDementia();
		Test.stopTest();
		System.assertEquals(res, '121070001');
	}

	@IsTest static void testGetDementiaWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Opportunity opp = [SELECT Betreuung__c FROM Opportunity WHERE Id=:id];
		opp.Betreuung__c = null;
		update opp;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getDementia();
		Test.stopTest();
		System.assertEquals(res, '121070000');
	}

	@IsTest static void testGetGenderWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getGender();
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetGenderWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Opportunity opp = [SELECT Geschlecht_der_Betreuungskraft__c FROM Opportunity WHERE Id=:id];
		opp.Geschlecht_der_Betreuungskraft__c = null;
		update opp;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getGender();
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testGetGermanSkillsWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getGermanSkills();
		Test.stopTest();
		System.assertNotEquals(res, '');
	}

	@IsTest static void testGetGermanSkillsWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Opportunity opp = [SELECT Deutschkenntnisse_der_Betreuungskraft__c FROM Opportunity WHERE Id=:id];
		opp.Deutschkenntnisse_der_Betreuungskraft__c = null;
		update opp;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getGermanSkills();
		Test.stopTest();
		System.assertEquals(res, '');
	}

	@IsTest static void testGetHwgvWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getHwgv();
		Test.stopTest();
		System.assertEquals(res, 'true');
	}

	@IsTest static void testGetHwgvWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Opportunity opp = [SELECT Hauswirtschaftsleistungen__c, Hauswirtschaft__c FROM Opportunity WHERE Id=:id];
		opp.Hauswirtschaft__c = null;
		opp.Hauswirtschaftsleistungen__c = false;
		update opp;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getHwgv();
		Test.stopTest();
		System.assertEquals(res, 'false');
	}

	@IsTest static void testGetShoppingHelpWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getShoppingHelp();
		Test.stopTest();
		System.assertEquals(res, 'true');
	}

	@IsTest static void testGetShoppingHelpWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Opportunity opp = [SELECT Hauswirtschaftsleistungen__c, Hauswirtschaft__c FROM Opportunity WHERE Id=:id];
		opp.Hauswirtschaft__c = null;
		opp.Hauswirtschaftsleistungen__c = false;
		update opp;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getShoppingHelp();
		Test.stopTest();
		System.assertEquals(res, 'false');
	}

	@IsTest static void testGetCareWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCare();
		Test.stopTest();
		System.assertEquals(res, 'true');
	}

	@IsTest static void testGetCareWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Opportunity opp = [SELECT Leichte_Pflege__c FROM Opportunity WHERE Id=:id];
		opp.Leichte_Pflege__c = null;
		update opp;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getCare();
		Test.stopTest();
		System.assertEquals(res, 'false');
	}

	@IsTest static void testGetToiletHelpWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getToiletHelp();
		Test.stopTest();
		System.assertEquals(res, 'true');
	}

	@IsTest static void testGetToiletHelpWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Opportunity opp = [SELECT Leichte_Pflege__c FROM Opportunity WHERE Id=:id];
		opp.Leichte_Pflege__c = null;
		update opp;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getToiletHelp();
		Test.stopTest();
		System.assertEquals(res, 'false');
	}

	@IsTest static void testGetNightHelpWithResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getNightHelp();
		Test.stopTest();
		System.assertEquals(res, '121070003');
	}

	@IsTest static void testGetNightHelpWithNoResult() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		Opportunity opp = [SELECT Nachteinsaetze__c FROM Opportunity WHERE Id=:id];
		opp.Nachteinsaetze__c = 'Nein';
		update opp;
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String res = sm.getNightHelp();
		Test.stopTest();
		System.assertEquals(res, '121070001');
	}

	@IsTest static void testCreateBodyReplacedPlaceholder() {
		Test.startTest();
		String id = [SELECT Id from Opportunity WHERE CloseDate = :d].Id;
		Strukturierte_Partner_Emails__c spm = [SELECT Email_Subject__c, Inhalt_der_Email__c FROM Strukturierte_Partner_Emails__c WHERE Email_Subject__c ='SCLEAD-PID2102002'];
		string ptid = [SELECT Id from Partner_Ticket__c where Opportunity__c = :id].Id;
		SunacareMail sm = new SunacareMail(id, spm.Inhalt_der_Email__c,ptid);
		String body = sm.createBody();
		String[] placeholder = new String[]{
				'{{allg.betreuungsbeginn}}',
				'{{allg.einsatzort}}',
				'{{hilfe.hwgv}}',
				'{{hilfe.einkaufen}}',
				'{{hilfe.guipflege}}',
				'{{hilfe.toilette}}',
				'{{hilfe.naechtlich}}',
				'{{anf.geschlecht}}',
				'{{anf.deutsch}}',
				'{{pb.anzahl}}',
				'{{pb1.geschlecht}}',
				'{{pb1.gewicht}}',
				'{{pb1.pflegestufe}}',
				'{{pb1.mobilitaet}}',
				'{{pb1.demenz}}',
				'{{pb2.geschlecht}}',
				'{{pb2.gewicht}}',
				'{{pb2.pflegestufe}}',
				'{{pb2.mobilitaet}}',
				'{{pb2.demenz}}',
				'{{c.email}}',
				'{{c.anrede}}',
				'{{c.firstname}}',
				'{{c.lastname}}',
				'{{c.telefon}}'};
		Test.stopTest();
		for (String p : placeholder) {
			//no placeholder left
			System.assert(!body.contains(p));
		}
	}
}