public class SunacareMail {
	private Partner_Ticket__c partnerTicket;
	private Id oppId;
	private String mailText;
	private Map<String, String> allg;
	private Map<String, String> help;
	private Map<String, String> anf;
	private Map<String, String> pb;
	@TestVisible private Opportunity oppObj;
	@TestVisible Private List<Contact> aspObj;
	@TestVisible private List<Contact> pbObj;

	// Construct
	public SunacareMail(Id oppId, String mailText, string ptId) {
		this.oppId = oppId;
		this.mailText = mailText;
		this.oppObj = queryOpp();
		this.aspObj = queryAsp();
		this.pbObj = queryPbObj();
		this.anf = new Map<String, String>();
		this.allg = new Map<String, String>();
		this.help = new Map<String, String>();
		this.pb = new Map<String, String>();
		this.partnerTicket = [SELECT Name FROM Partner_Ticket__c where Opportunity__c =: this.oppId and Id=:ptId];
		fillAllg();
		fillAnf();
		fillPb();
	}


	// getting called by PLZTool_Basis
	public String createBody() {
		replaceAllg();
		replaceHilfe();
		replaceAnf();
		replacePb();
		replaceC();
		return this.mailText;
	}

	@TestVisible private List<Contact> queryAsp() {
		List<Contact> contactList = [SELECT Email, Salutation, FirstName, LastName, Phone, MobilePhone, OtherPhone FROM Contact where Id in (SELECT ContactId FROM OpportunityContactRole where OpportunityId = :this.oppId and Role = 'ASP')];
		// when no role ASP found
		if (contactList.size() == 0) {
			// query asp = pb
			contactList = [SELECT Email, Salutation, FirstName, Pflegegrad__c, LastName, Phone, MobilePhone, OtherPhone FROM Contact where Id in (SELECT ContactId FROM OpportunityContactRole where OpportunityId = :this.oppId and Role = 'PB = ASP')];

		}
		return contactList;
	}

	@TestVisible private Opportunity queryOpp() {
		return [SELECT Zeitpunkt_der_Versorgung__c, Anzahl_zu_betreuender_Personen__c, Hauswirtschaft__c, Alternative_Postleitzahl__c, Hauswirtschaftsleistungen__c, Leichte_Pflege__c, Nachteinsaetze__c, Geschlecht_der_Betreuungskraft__c, Deutschkenntnisse_der_Betreuungskraft__c, Betreuung__c, Mobilit_t_des_Seniors__c FROM Opportunity where Id = :this.oppId];
	}

	@TestVisible private void replaceAllg() {
		this.mailText =
				this.mailText.replace('{{allg.betreuungsbeginn}}', getCareStart())
						.replace('{{allg.einsatzort}}', getPostalCode());
	}

	@TestVisible private void replaceC() {
		this.mailText =
				this.mailText.replace('{{c.email}}', getCEmail(0))
						.replace('{{c.anrede}}', getCSalutation(0))
						.replace('{{c.firstname}}', getCFirstName(0))
						.replace('{{c.lastname}}', getCLastName(0))
						.replace('{{c.telefon}}', getCPhone(0));
	}

	@TestVisible private void replacePb() {
		this.mailText =
				this.mailText.replace('{{pb.anzahl}}', String.valueOf(countPBs()))
						.replace('{{pb.imHaushalt}}', countPBs() == '2' ? '1' : '0')
						.replace('{{pb1.geschlecht}}', getSalutation(0))
						.replace('{{pb1.gewicht}}', '79')
						.replace('{{pb1.pflegestufe}}', getPflegeStufeKunde())
						.replace('{{pb1.mobilitaet}}', getMobility())
						.replace('{{pb1.demenz}}', getDementia());

		if (this.countPBs() == '2') {
			// Wenn 2 zu betreuende Pflegepersonen angegeben sind, so wird PB2 mit den Infos von PB1 beschrieben.
			try {
				this.mailText =
						this.mailText
								.replace('{{pb2.geschlecht}}', getSalutation(0))
								.replace('{{pb2.gewicht}}', '79')
								.replace('{{pb2.pflegestufe}}', getPflegeStufeKunde())
								.replace('{{pb2.mobilitaet}}', getMobility())
								.replace('{{pb2.demenz}}', getDementia());
			} catch (Exception e) {
				throw new CalloutException('Konnte keine 2. Pflegeperson finden.');
			}

		} else {
			// required fields according to SunaCare, so we're sending empty fields.
			this.mailText =
					this.mailText
							.replace('{{pb2.geschlecht}}', '')
							.replace('{{pb2.gewicht}}', '')
							.replace('{{pb2.pflegestufe}}', '')
							.replace('{{pb2.mobilitaet}}', '')
							.replace('{{pb2.demenz}}', '');

		}
		this.mailText = this.mailText.replace('{{customerno}}', this.partnerTicket.Name);

	}

	@TestVisible private void replaceAnf() {
		this.mailText =
				this.mailText.replace('{{anf.geschlecht}}', getGender())
						.replace('{{anf.deutsch}}', getGermanSkills());
	}

	@TestVisible private void replaceHilfe() {
		this.mailText =
				this.mailText.replace('{{hilfe.hwgv}}', getHwgv())
						.replace('{{hilfe.einkaufen}}', getShoppingHelp())
						.replace('{{hilfe.guipflege}}', getCare())
						.replace('{{hilfe.toilette}}', getToiletHelp())
						.replace('{{hilfe.naechtlich}}', getNightHelp());
	}

	/*
	 * Getter for Opp values
	 */
	@TestVisible private String getGermanSkills() {
		String toRet;
		try {
			toRet = this.anf.get(this.oppObj.Deutschkenntnisse_der_Betreuungskraft__c);
		} catch (Exception e) {
			System.debug('######### Keine Deutschkenntnisse für die Betreuungskraft gefunden für Opportunity ' +
					this.oppId + ' ##########');
			toRet = '';
		}
		return toRet == null ? '' : toRet;
	}

	@TestVisible private String getGender() {
		String toRet;
		try {
			toRet = this.anf.get(this.oppObj.Geschlecht_der_Betreuungskraft__c);
		} catch (Exception e) {
			toRet = '';
			System.debug('######### Kein Geschlecht für die Betreuungskraft gefunden für Opportunity ' + this.oppId +
					' ##########');
		}
		return toRet == null ? '' : toRet;
	}

	@TestVisible private String getNightHelp() {
		if (this.oppObj.Nachteinsaetze__c == null || this.oppObj.Nachteinsaetze__c == 'Nein') {
			return '121070001';

		}
		return '121070003';
	}

	@TestVisible private String getToiletHelp() {
		if (this.oppObj.Leichte_Pflege__c == null ||
				!this.oppObj.Leichte_Pflege__c.contains('Unterstützung Toilettengang')) {
			return 'false';
		}
		return 'true';
	}

	@TestVisible private String getCare() {
		if (this.oppObj.Leichte_Pflege__c == null || !this.oppObj.Leichte_Pflege__c.contains('Körperpflege')) {
			return 'false';
		}
		return 'true';
	}

	@TestVisible private String getShoppingHelp() {
		if (this.oppObj.Hauswirtschaft__c == null || !this.oppObj.Hauswirtschaft__c.contains('Hilfe beim Einkaufen')) {
			return 'false';
		}
		return 'true';
	}

	@TestVisible private String getHwgv() {
		return this.oppObj.Hauswirtschaftsleistungen__c == false ? 'false' : 'true';
	}

	@TestVisible private String getPostalCode() {
		return this.oppObj.Alternative_Postleitzahl__c == null ? '' : this.oppObj.Alternative_Postleitzahl__c;
	}

	@TestVisible private String getCareStart() {
		String toRet;
		try {
			toRet = this.allg.get(oppObj.Zeitpunkt_der_Versorgung__c);
		} catch (Exception e) {
			toRet = '';
			System.debug('######### Kein Versorgungsbeginn gefunden für Opportunity ' + this.oppId +
					' ##########');
		}
		return toRet == null ? '' : toRet;
	}


	/*
	 * Getter contact values
	 */

	@TestVisible private String getCLastName(Integer index) {
		return this.aspObj.get(index).LastName == null ? '' : this.aspObj.get(index).LastName;
	}

	@TestVisible private String getCFirstName(Integer index) {
		return this.aspObj.get(index).FirstName == null ? '' : this.aspObj.get(index).FirstName;
	}

	@TestVisible private String getCSalutation(Integer index) {
		return this.aspObj.get(index).Salutation == null ? '' : this.allg.get(this.pbObj.get(index).Salutation);
	}

	@TestVisible private String getCEmail(Integer index) {
		return this.aspObj.get(index).Email == null ? '' : this.aspObj.get(index).Email;
	}

	@TestVisible private String getCPhone(Integer index) {
		if (this.aspObj.get(index).Phone != null) {
			return this.aspObj.get(index).Phone;
		}
		if (this.aspObj.get(index).MobilePhone != null) {
			return this.aspObj.get(index).MobilePhone;
		}
		if (this.aspObj.get(index).OtherPhone != null) {
			return this.aspObj.get(index).OtherPhone;
		}
		return '';

	}

	/*
	 * Getter care person values
	 */
	@TestVisible private List<Contact> queryPbObj() {
		return [SELECT Pflegegrad__c, Salutation FROM Contact Where Id in(SELECT ContactId from OpportunityContactRole WHERE OpportunityId = :this.oppId and Role in ('PB', 'PB = ASP'))];
	}

	@TestVisible private String getDementia() {
		if (this.oppObj.Betreuung__c == null || !this.oppObj.Betreuung__c.contains('Dementenbetreuung')) {
			return this.pb.get('false');
		}
		return this.pb.get('true');
	}

	@TestVisible private String getMobility() {
		String toRet;
		try {
			toRet = this.pb.get(this.oppObj.Mobilit_t_des_Seniors__c);
		} catch (Exception e) {
			System.debug('######### Keine Mobilitätsoption gefunden für Opportunity ' + this.oppId +
					' ##########');
			toRet = '';
		}
		return toRet == null ? '' : toRet;
	}

	@TestVisible private String getSalutation(Integer index) {
		String toRet;
		try {
			toRet = this.pb.get(this.pbObj.get(index).Salutation);
		} catch (Exception e) {
			System.debug('######### Keine Anrede gefunden für Opportunity ' + this.oppId +
					' ##########');
			toRet = '';
		}
		return toRet;
	}

	@TestVisible private String getPflegeGrad(Integer index) {
		queryPbObj();

		if (this.pbObj == null) {
			return '';
		}
		return this.pb.get(this.pbObj.get(index).Pflegegrad__c) == null ? '' : this.pb.get(this.pbObj.get(index).Pflegegrad__c);
	}

	@TestVisible private String countPBs() {
		return oppObj.Anzahl_zu_betreuender_Personen__c == null ? '' : oppObj.Anzahl_zu_betreuender_Personen__c;

	}


	/*
	 * Mapping pflege values and SunaCare Values
	 */
	@TestVisible private void fillAllg() {
		//Mapping Betreuungsbeginn
		this.allg.put('Sofort', '121070003');
		this.allg.put('Herr', '121070000');
		this.allg.put('Frau', '121070001');
		this.allg.put('Schnellstmöglich', '121070003');
		this.allg.put('Innerhalb von 2 Wochen', '121070000');
		this.allg.put('Innerhalb eines Monats', '121070001');
	}

	@TestVisible private void fillAnf() {
		// mapping anforderungen
		this.anf.put('Weiblich', '2');
		this.anf.put('Männlich', '1');
		this.anf.put('Egal', '0');
		this.anf.put('Gut', '121070001');
		this.anf.put('Sehr gut', '121070001');
		this.anf.put('Mittel', '121070000');
		this.anf.put('Irrelevant', '121070002');
		this.anf.put('Einfach', '121070002');
	}

	@TestVisible private void fillPb() {
		// info pflegebedürftiger
		this.pb.put('Herr', '1');
		this.pb.put('Frau', '2');
		this.pb.put('Uneingeschränkt', '121070000');
		this.pb.put('Rollator', '121070002');
		this.pb.put('Rollstuhl', '121070003');
		this.pb.put('Bettlägrig', '121070004');
		this.pb.put('false', '121070000');
		this.pb.put('true', '121070001');
	}
	@TestVisible private string getPflegeStufeKunde() {
		return '121070004';
	}
}