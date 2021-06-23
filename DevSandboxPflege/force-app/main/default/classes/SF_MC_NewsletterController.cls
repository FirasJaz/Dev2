@RestResource(urlMapping = '/sfmc/newsletter')
global without sharing class SF_MC_NewsletterController {

	@HttpPost
	global static void newsletterLead() {
		RestResponse res = RestContext.response != null ? RestContext.response : new RestResponse();
		RestRequest req = RestContext.request != null ? RestContext.request : new RestRequest();
		res.addHeader('Content-Type', 'application/json');
		Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
		Map <String, String> JSONMap = new Map<String, String>();
		for (String key : dataMap.keySet()) {
			if (dataMap.get(key) != null) {
				if (key == 'pflegegrad__c') {
					if (dataMap.get(key).toString() == '1' || dataMap.get(key).toString() == '2' ||
									dataMap.get(key).toString() == '3' || dataMap.get(key).toString() == '4' ||
									dataMap.get(key).toString() == '5') {
						JSONMap.put(key, 'Pflegegrad vorhanden');
					} else {
						JSONMap.put(key, 'Keinen Pflegegrad');
					}
					continue;
				}
				JSONMap.put(key, dataMap.get(key).toString());
			}
		}
		Set<String> dataKeys = JSONMap.keySet();
		JSONResponseGenerator.SFResponse r = new JSONResponseGenerator.SFResponse();
		List<String> err = new List<String>();
		// prüfen ob bereits Kontakt mit Namen besteht
		// wenn ja, dann überschreibe die Kontakte.
		List<Contact> cList = [SELECT Salutation, FirstName, LastName, Email,
		OM_UserID__c, OM_Visit_ID__c, OM_Timestamp__c, OM_Subscriber_Status__c, OM_Subscriber_Key__c, OM_User_Role__c, OM_Token__c,
		pflegegrad__c, OM_DOI_Requested_c__c
		FROM Contact WHERE (Email =:JSONMap.get('Email') AND FirstName =:JSONMap.get(
				'FirstName') AND LastName =:JSONMap.get('LastName')) ORDER BY LastModifiedDate DESC limit 1];
		if (!cList.isEmpty()) {
			Contact c = cList.get(0);
			try {
				c = (Contact)SF_MC_NewsletterController.fillObject(c, dataKeys, JSONMap);
				System.debug(c);
			} catch (CalloutException e) {
				err.add(e.getMessage() + '-------' + 'fill contactObject');
			}
			try {
				update c;
				r.id = c.Id;
			} catch (Exception e) {
				err.add(e.getMessage() + '-------' + 'fill updateClist');
			}
		} else {
			// Prüfe ob leads mit der Kombination vorhanden sind, wenn ja, überschreibe diese, ansonsten erstelle einen neuen Lead
			List<Lead> leadsBasedOnEmailAndName = [SELECT Salutation, FirstName, LastName, Email, OM_Token__c,
			OM_UserID__c, OM_Visit_ID__c, OM_Timestamp__c, OM_Subscriber_Status__c, OM_Subscriber_Key__c, OM_User_Role__c,
			pflegegrad__c, OM_Newsletter__c, OM_DOI_Requested_c__c, Company, OM_Wizzard_Name2__c, RecordTypeId
			FROM Lead WHERE (Email =:JSONMap.get('Email') AND FirstName =:JSONMap.get(
					'FirstName') AND LastName =:JSONMap.get('LastName') AND RecordTypeId =: JSONMap.get(
					'RecordTypeId')) AND OM_Tracking_Order_ID__c = null ORDER BY LastModifiedDate DESC];
			if (leadsBasedOnEmailAndName.isEmpty()) {
				// neuen Lead anlegen
				lead l = new Lead();
				try {
					l = (Lead)SF_MC_NewsletterController.fillObject(l, dataKeys, JSONMap);
				} catch (CalloutException e) {
					err.add(e.getMessage() + '-------' + 'NewsletterController');
				}
				l.RecordTypeId = JSONMap.get('RecordTypeId');
				try {
					insert l;
					r.id = l.Id;
				} catch (Exception e) {
					err.add(e.getMessage() + 'trace:' + e.getStackTraceString());
				}
			} else {
				// update leads
				Lead l = leadsBasedOnEmailAndName.get(0);
				try {
					l = (Lead)SF_MC_NewsletterController.fillObject(l, dataKeys, JSONMap);
				} catch (CalloutException e) {
					err.add(e.getMessage() + '-------' + 'NewsletterController');
				}

				try {
					update l;
					r.id = l.Id;
				} catch (Exception e) {
					err.add(e.getMessage() + 'trace:' + e.getStackTraceString());
				}
			}
		}
		// response
		r.errors = new List<String>(err);
		if (r.errors.size() > 0) {
			r.success = false;
			res.statusCode = 400;
			r.id = null;
		} else {
			r.success = true;
			res.statusCode = 200;
		}
		res.responseBody = Blob.valueOf(JSONResponseGenerator.generateJsonResponse(r));
		return;
	}

	public static sObject fillObject(sObject o, Set<String> keys, Map<String, String> dataMap) {
		Set<String> objFields = o.getSObjectType().getDescribe().fields.getMap().keySet();
		for (string key : keys) {
			if (o.getSObjectType() == SObjectType.Contact.getSObjectType() && key == 'RecordTypeId') {
				continue;
			}
			if (objFields.contains(key.toLowerCase())) {
				try {
					o.put(key, dataMap.get(key));
				} catch (Exception e) {
					try {
						o.put(key, Boolean.valueOf(dataMap.get(key)));
					} catch (Exception ee) {
						try {
							o.put(key, Decimal.valueOf(dataMap.get(key)));
						} catch (Exception ex) {
							Exception myEx = new CalloutException(
											'error in mapping the values to the object (key ' + key + '-> error: ' + e +
											' -> trace: ' + e.getStackTraceString());
							throw myEx;
						}
					}
				}
			}
		}
		return o;
	}
}