public class CuraboxCustomerHelpers {
	private class DeliveryInfos {
		Boolean filledSoon;
		Date dLineDate;
		String status;
		String deliveryNumber;
		String deliveryText;
		Date dnDate;
		Boolean pod;
		String dLineStatus;
		String interval;
	}

	public static final string FAMILYKEY = 'family';
	public static string BIRTHDATEKEY = 'birthdate';
	public static string ACCOUNTIDKEY = 'account_id';
	public static string UNKNOWNCUSTOMER = 'unknown customer';
	public static string UNKNOWNCONTACT = 'unknown contact';
	public static string NOAPPROVAL = 'no approval';
	public static string APPROVALPENDING = 'application pending';
	public static string APPROVEDAPPLICATION = 'application approved';
	public static string CANCELLEDAPPLICATION = 'curabox is cancelled';
	public static string CANDIDATEAPPLICATION = 'is candidate';
	public static string APPROVEDSTATUS = 'Bewilligung';
	public static string PENIDINGSTATUS = 'Antragsversand';
	public static string CANCELLED = 'Kündigung';
	public static string CANDIDATE = 'Kandidat';
	public static string CBPARAGRAPH = '54';
	public static string PG = 'PG';

	public static void createResMessage(RestResponse res, Integer status, string message) {
		Map <string, string> returnMessage = new Map<String, String>();
		res.statusCode = status;
		returnMessage.put('message', message);
		res.responseBody = Blob.valueOf(JSON.serialize(returnMessage));
		return;
	}

	//  public static void createResMessage(RestResponse res,
	//                    Integer status,
	//                    String success,
	//                    JSONResponseGenerator.FailedSubmittedData add) {
	//    res.statusCode = status;
	//    res.responseBody = Blob.valueOf(JSONResponseGenerator.generateJsonResponse(success, add, status));
	//    return;
	//  }

	public static void createResMessage(RestResponse res,
										Integer status,
										String success,
										Object add) {
		res.statusCode = status;
		res.responseBody = Blob.valueOf(JSONResponseGenerator.generateJsonResponse(success, add, status));
		return;
	}

	public static JSONResponseGenerator.ApprovedResponse generateResponseObject(List<
	Curabox_Genehmigungsposition__c> approvedList) {
		List<Product_Group__c> productGroupList = [SELECT Id, Name from Product_Group__c];
		JSONResponseGenerator.ApprovedResponse approvedResponse =
				new JSONResponseGenerator.ApprovedResponse();
		Set<string> approvedProducts = new Set<String>();
		for (Curabox_Genehmigungsposition__c item : approvedList) {
			approvedProducts.add(item.Product_Group__c);
		}
		approvedResponse.products = new List<Map<String, Boolean>>();
		for (Integer i = 0; i < productGroupList.size(); i++) {
			Map<string, boolean> returnMap = new Map<String, boolean>();
			if (approvedProducts.contains(productGroupList.get(i).Id)) {
				returnMap.put(productGroupList.get(i).Name, true);
			} else {
				returnMap.put(productGroupList.get(i).Name, false);
			}
			approvedResponse.products.add(returnMap);
		}
		return approvedResponse;
	}

	public static void createResMessage(RestResponse res,
										Integer status,
										List<Curabox_Genehmigungsposition__c> message) {
		Set<string> approvedProducts = new Set<String>();
		for (Curabox_Genehmigungsposition__c item : message) {
			approvedProducts.add(item.Product_Group__c);
		}
		List<Product_Group__c> productGroupList = [SELECT Id, Name from Product_Group__c];
		Map<string, boolean> returnMap = new Map<String, boolean>();
		for (Integer i = 0; i < productGroupList.size(); i++) {
			if (approvedProducts.contains(productGroupList.get(i).Id)) {
				returnMap.put(productGroupList.get(i).Name, true);
			} else {
				returnMap.put(productGroupList.get(i).Name, false);
			}
		}
		Map<string, Map<String, Boolean>> returnMessage = new Map<String, Map<String, Boolean>>();
		returnMessage.put('message', returnMap);
		res.responseBody = Blob.valueOf(JSON.serialize(returnMessage));
		res.statusCode = status;
		return;
	}

	public static boolean validParams(string familyNr, string birthdate) {
		Pattern familyNrRegex = Pattern.compile('^F-[0-9]{6}$');
		Pattern birthdateRegex = Pattern.compile('^(0[1-9]|[12][0-9]|3[01])[.](0[1-9]|1[012])[.](19|20)[0-9]{2}$');
		Matcher familyNrMatcher = familyNrRegex.matcher(familyNr);
		Matcher birthdateMatcher = birthdateRegex.matcher(birthdate);
		return familyNrMatcher.matches() && birthdateMatcher.matches();
	}

	public static string getContactId(string accountId, Date birthdate) {
		List<Contact> contactList = [SELECT Id, LastName from Contact where AccountId = :accountId and Birthdate = :birthdate];
		if (contactList.size() == 0 || birthdate == Date.parse('28.02.1900')) {
			return '0';
		}
		return contactList.get(0).Id;

	}

	public static string getAccountId(string familyId, Date birthdate) {
		List<Account> accountList = [Select Id from Account where Familien_ID__c = :familyId
		AND Id in (Select AccountId from Contact where birthdate = :birthdate)];
		if (accountList.size() == 0) {
			return '0';
		}
		return accountList.get(0).Id;
	}

	public static List<Curabox_Genehmigung__c> getApprovalId(string contactId) {
		List<String> t = new List<String>();
		t.add('Antragsversand');
		t.add('Bewilligung');
		List<Curabox_Genehmigung__c> approvals = [Select Id, Name, Nach_Paragraph__c, genehmigt_bis__c, unbefristet_genehmigt__c, Status__c
		From Curabox_Genehmigung__c Where Contact__c = :contactId AND Status__c IN :t
		ORDER BY genehmigt_ab__c DESC];
		//AND ID in (select Genehmigung__c from Curabox_Genehmigungsposition__c Where Gen_Menge_Stk__c> 0)
		if (approvals.size() == 0) {
			return null;
		}

		return approvals;
	}

	public static List < Curabox_Genehmigungsposition__c > getApprovedProducts(string approvalId) {
		List < Curabox_Genehmigungsposition__c > approvedList = [Select Product_Group__c
		From Curabox_Genehmigungsposition__c
		Where Genehmigung__c = :approvalId AND Gen_Menge_Stk__c> 0];
		return approvedList;
	}

	public static string getTrackingNumber(string contactId) {
		List<Delivery_Note__c> deliveryNumber = [Select DPD_shipping_number__c
		From Delivery_note__c
		Where Contact__c = :contactId
		ORDER BY CreatedDate DESC];
		if (deliveryNumber.size() == 0 || deliveryNumber.get(0).DPD_shipping_number__c == null) {
			return '0';
		}
		return deliveryNumber.get(0).DPD_shipping_number__c;
	}


	public static Map<String, Map<String, String>> getTrackingData(String contactId) {
		Map<String, Map<String, String>> returnMap = new Map<String, Map<String, String>>();
		DeliveryInfos deliveryInfos = getInfos(contactId, true);
		DeliveryInfos deliveryInfosNext = getInfos(contactId, false);
		if (deliveryInfos == null) {
			returnMap.put('next', null);
			returnMap.put('current', null);
			return returnMap;
		}
		Map<String, String> current = fillMap(deliveryInfos, true);
		Map<String, String> next = fillMap(deliveryInfosNext, false);
		returnMap.put('next', next);
		returnMap.put('current', current);
		return returnMap;
	}

	public static boolean isCancelled(String contactId) {
		try {
			Contact_Status__c c =
					[SELECT Status__c FROM Contact_Status__c WHERE Contact__c =:contactId AND Productgroup__c = :
							PG + CBPARAGRAPH ORDER BY LastModifiedDate DESC].get(0);
			if (c.Status__c == CANCELLED) {
				return true;
			}
		} catch (Exception e) {
			System.debug(e);
		}
		return false;
	}


	private static DeliveryInfos getInfos(String contactId, Boolean currentDelivery) {
		List<Order__c> intervalList = [SELECT Delivery_frequency__c FROM Order__c WHERE Status__c = 'aktiv' AND Nach_Paragraph__c = '54' AND Contact__c = :contactId ORDER BY CreatedDate DESC];
		Integer currMonth = Date.today().month();
		Integer currYear = Date.today().year();
		Integer intervalNext;
		if (!currentDelivery) {
			if (intervalList.isEmpty()) {
				intervalNext = 0;
			} else {
				intervalNext = getIntervalAsInt(intervalList.get(0).Delivery_frequency__c);
				if (intervalNext == 12) {
					currYear += 1;
				} else {
					currMonth += intervalNext;
				}
			}
		}
		List<Delivery_Line__c> dLineList;
		Delivery_Note__c dN;
		String bedProtectId = [SELECT Id from Product__c where Name =: 'MoliNea textile Bettschutzeinlage'].Id;
		DeliveryInfos deliveryInfos = new DeliveryInfos();
		Boolean isPaused = false;
		//		if (currentDelivery) {
		// delivery note
		List<Delivery_Note__c> deliveryNoteList = [SELECT Id, Delivery_date__c, pod_recieved__c, DHL_shipping_number__c, DPD_shipping_number__c, Delivery_text__c FROM Delivery_Note__c WHERE Contact__c =:contactId AND (CALENDAR_MONTH(Delivery_date__c) =:currMonth AND CALENDAR_YEAR(Delivery_date__c) =:currYear) ORDER BY CreatedDate DESC];
		if (deliveryNoteList.isEmpty()) {
			// is paused?
			Order__c o = getOrder(contactId);
			if (o == null || o.Status__c != 'pausiert') {
				// is new Delivery? (Bedarf?)
				dLineList = [SELECT Delivery_status__c, Delivery_date__c FROM Delivery_Line__c where Contact__c =:contactId AND (Delivery_status__c =:'Bedarf' AND CALENDAR_MONTH(Delivery_date__c) =:currMonth AND CALENDAR_YEAR(Delivery_date__c) =:currYear) AND Product__c!=:bedProtectId];
				if (dLineList.isEmpty()) {
					System.debug('deliveryNoteList in getTrackingData() is empty, returning null.');
					return null;
				}
			}
			if (o.Status__c == 'pausiert') {
				isPaused = true;
			}
		}
		if (!isPaused && !deliveryNoteList.isEmpty()) {
			dN = deliveryNoteList.get(0);
			dLineList = [SELECT Delivery_status__c, Delivery_date__c FROM Delivery_Line__c where Delivery_note__c =:dN.Id AND Contact__c =:contactId AND Product__c!=:bedProtectId];
			if (dLineList.isEmpty()) {
				System.debug('dLineList in getTrackingData() is empty, returning null.');
				return null;
			}
		}
		//		} else {
		//		if (!currentDelivery) {
		//			dLineList = [SELECT Delivery_status__c, Delivery_date__c FROM Delivery_Line__c where Contact__c =:contactId AND (Delivery_status__c =:'Bedarf' AND CALENDAR_MONTH(Delivery_date__c) =:currMonth AND CALENDAR_YEAR(Delivery_date__c) =:currYear) AND Product__c!=:bedProtectId];
		//			if (dLineList.isEmpty()) {
		//				return null;
		//			}
		//		}
		//		}
		if (!isPaused) {
			// Lieferdatum aus Lieferscheinposition
			deliveryInfos.dLineDate = dLineList.get(0).Delivery_date__c;
			// Lieferstatus aus Lieferscheinposition
			deliveryInfos.status = dLineList.get(0).Delivery_status__c;
			// Sendungsnummer aus Lieferschein
			// todo check ob dhl oder ob dpd beliefert
			deliveryInfos.deliveryNumber = dN != null ? dN.DPD_shipping_number__c : null;
			// Lieferscheintext aus Lieferschein
			deliveryInfos.deliveryText = dN != null ? dN.Delivery_text__c : null;
			// Lieferdatum aus Lieferschein
			deliveryInfos.dnDate = dN != null ? dN.Delivery_date__c : dLineList.get(0).Delivery_date__c;
			// Ablieferbeleg in Systeminfo in Lieferschein
			deliveryInfos.pod = dN != null ? dN.pod_recieved__c : false;
			// Status aus Lieferscheinposition
			deliveryInfos.dLineStatus = dLineList.get(0).Delivery_status__c;
			// Lieferintervall
			//		List<Order__c> intervalList = [SELECT Delivery_frequency__c FROM Order__c WHERE Status__c = 'aktiv' AND Nach_Paragraph__c = '54' AND Contact__c = :contactId ORDER BY CreatedDate DESC];
			deliveryInfos.interval = null;
			if (!intervalList.isEmpty()) {
				deliveryInfos.interval = intervalList.get(0).Delivery_frequency__c;
			}
		} else {
			// Lieferdatum aus Lieferscheinposition
			deliveryInfos.dLineDate = null;
			// Lieferstatus aus Lieferscheinposition - pausiert, da kein aktiver Auftrag
			deliveryInfos.status = 'pausiert';
			// Sendungsnummer aus Lieferschein
			deliveryInfos.deliveryNumber = null;
			// Lieferscheintext aus Lieferschein
			deliveryInfos.deliveryText = null;
			// Lieferdatum aus Lieferschein
			deliveryInfos.dnDate = null;
			// Ablieferbeleg in Systeminfo in Lieferschein
			deliveryInfos.pod = false;
			// Status aus Lieferscheinposition
			deliveryInfos.dLineStatus = null;
			// Lieferintervall
			//		List<Order__c> intervalList = [SELECT Delivery_frequency__c FROM Order__c WHERE Status__c = 'aktiv' AND Nach_Paragraph__c = '54' AND Contact__c = :contactId ORDER BY CreatedDate DESC];
			deliveryInfos.interval = null;
			if (!intervalList.isEmpty()) {
				deliveryInfos.interval = intervalList.get(0).Delivery_frequency__c;
			}
		}


		return deliveryInfos;
	}

	private static Order__c getOrder(string contactId) {
		//AND CALENDAR_MONTH(Liefertag__c) = :month AND CALENDAR_YEAR(Liefertag__c) =:year
		List<Order__c> orderList = [SELECT Status__c, Nach_Paragraph__c FROM Order__c WHERE Nach_Paragraph__c = '54' AND Contact__c = :contactId ORDER BY CreatedDate DESC];
		if (orderList.isEmpty()) {
			System.debug('no order found, returning null.');
			return null;
		}
		return orderList.get(0);
	}

	private static Integer getIntervalAsInt(String frequency) {
		// monatlich,zweimonatlich,dritteljährlich,vierteljährlich,halbjährlich,jährlich,einmalig
		switch on frequency {
			when 'monatlich' {
				return 1;
			}
			when 'zweimonatlich' {
				return 2;
			}
			when 'vierteljährlich' {
				return 3;
			}
			when 'dritteljährlich' {
				return 4;
			}
			when 'halbjährlich' {
				return 6;
			}
			when 'jährlich' {
				return 12;
			}
			when 'einmalig' {
				return 0;
			}
		}
		return 0;
	}

	public static Map<String, String> fillMap(DeliveryInfos deliveryInfos, Boolean current) {
		Map<String, String> returnMap = new Map<String, String>();
		if (deliveryInfos == null) {
			return null;
		}
		Integer currMonth = Date.today().month();
		Integer currYear = Date.today().year();
		Integer intervalNext;
		if (!current) {
			if (deliveryInfos.interval == null) {
				intervalNext = 0;
			} else {
				intervalNext = getIntervalAsInt(deliveryInfos.interval);
				System.debug('##### ->' + intervalNext);
				if (intervalNext == 12) {
					currYear += 1;
				} else {
					currMonth += intervalNext;
				}
			}
		}
		Integer difference = 0;
		if (deliveryInfos.dnDate != null) {
			difference = Date.today().daysBetween(deliveryInfos.dnDate);
			// if negative, set it to zero
			if (difference < 0) {
				difference = 0;
			}
		}
		// case 1 - Keine trackingnummer, aber Lieferdatum vorhanden
		if (String.isBlank(deliveryInfos.deliveryNumber) && deliveryInfos.dnDate != null &&
						deliveryInfos.dnDate.month() == currMonth && deliveryInfos.dnDate.year() == currYear &&
						deliveryInfos.deliveryText != 'KUWV') {
			returnMap.put('status', 'packing');
			returnMap.put('tracking_number', deliveryInfos.deliveryNumber);
			returnMap.put('packing_date', deliveryInfos.dnDate.format());
			returnMap.put('delivery_interval', deliveryInfos.interval);
			returnMap.put('days_until_packing', String.valueOf(difference));

			return returnMap;
		}
		// case 2 - Paket ist in Zustellung
		if (!deliveryInfos.pod && deliveryInfos.dnDate != null && deliveryInfos.dnDate.month() == currMonth &&
						deliveryInfos.dnDate.year() == currYear &&
				String.isNotBlank(deliveryInfos.deliveryNumber) &&
						deliveryInfos.deliveryText != 'KUWV') {
			returnMap.put('status', 'in delivery');
			returnMap.put('tracking_number', deliveryInfos.deliveryNumber);
			returnMap.put('packing_date', deliveryInfos.dnDate.format());
			returnMap.put('delivery_interval', deliveryInfos.interval);
			returnMap.put('days_until_packing', String.valueOf(difference));

			return returnMap;
		}
		// case 3 - Paket ist zugestellt
		if (deliveryInfos.dnDate != null && deliveryInfos.dnDate.month() == currMonth &&
						deliveryInfos.dnDate.year() == currYear && deliveryInfos.pod &&
						deliveryInfos.deliveryText != 'KUWV') {
			returnMap.put('status', 'delivered');
			returnMap.put('tracking_number', deliveryInfos.deliveryNumber);
			returnMap.put('packing_date', deliveryInfos.dnDate.format());
			returnMap.put('delivery_interval', deliveryInfos.interval);
			returnMap.put('days_until_packing', String.valueOf(difference));

			return returnMap;
		}
		// case 4 - Lieferung ist pausiert
		if (deliveryInfos.dLineDate == null && deliveryInfos.status == 'pausiert') {
			returnMap.put('status', 'paused');
			returnMap.put('tracking_number', deliveryInfos.deliveryNumber);
			returnMap.put('packing_date', null);
			returnMap.put('delivery_interval', deliveryInfos.interval);
			returnMap.put('days_until_packing', String.valueOf(difference));

			return returnMap;
		}
		return null;
	}


	public static Boolean isCandidate(String contactID) {
		try {
			Contact_Status__c c =
					[SELECT Status__c FROM Contact_Status__c WHERE Contact__c =:contactId AND Productgroup__c = :
							PG + CBPARAGRAPH ORDER BY CreatedDate DESC].get(0);
			if (c.Status__c == CANDIDATE) {
				return true;
			}
		} catch (Exception e) {
			System.debug(e);
		}
		return false;
	}
}