@isTest
private class SF_MC_NewsletterController_test {


	@testSetup static void setup() {
		Lead l = new Lead(Salutation = 'Herr',
				FirstName = 'Max',
				LastName = 'Mustermann',
				Email = 'testing_doi@example.com',
				OM_Token__c = 'example_token',
				OM_UserID__c = 'example_UserID123',
				OM_Visit_ID__c = 'example_visitID',
				OM_Timestamp__c = Datetime.now().format(),
				OM_Subscriber_Status__c = 'unconfirmed',
				OM_Subscriber_Key__c = 'testing_newsletter@example.com',
				OM_User_Role__c = 'example',
				pflegegrad__c = '2',
				Company = 'example_company',
				OM_Wizzard_Name2__c = '7015800000018KMAAY');
		insert l;
		Contact c = new Contact(OM_DOI_Requested_c__c = false,
				Pflegegrad__c = 'pflegegrad vorhanden',
				LastName = 'Mustermann',
				FirstName = 'Max',
				Email = 'testing_contact@example.com');
		insert c;
	}

	@IsTest static void testNewsletterRegistrationNewLead() {
		Map<String, String> testMap = getTestMap();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/sfmc/newsletter';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(JSON.serialize(testMap));
		RestContext.request = req;
		RestContext.response = res;
		SF_MC_NewsletterController.newsletterLead();
		Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
		// no errors
		System.assertEquals(m.get('errors'), new List<String>());
		// true
		System.assertEquals(m.get('success'), true);
		// id found, because only one lead with mail
		System.assertNotEquals(m.get('id'), '');
		// status 200
		System.assertEquals(res.statusCode, 200);
	}

	@IsTest static void testNewsletterRegistrationUpdateLead() {
		Map<String, String> testMap = getTestMap();
		// changing mail to match existing lead
		testMap.put('Email', 'testing_doi@example.com');
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/sfmc/newsletter';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(JSON.serialize(testMap));
		RestContext.request = req;
		RestContext.response = res;
		SF_MC_NewsletterController.newsletterLead();
		Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
		// no errors
		System.assertEquals(m.get('errors'), new List<String>());
		// true
		System.assertEquals(m.get('success'), true);
		// id found, because only one lead with mail
		System.assertNotEquals(m.get('id'), '');
		// status 200
		System.assertEquals(res.statusCode, 200);
	}

	@IsTest static void testNewsletterRegistrationUpdateContact() {
		Map<String, String> testMap = getTestMap();
		// changing mail to match existing contact
		testMap.put('Email', 'testing_contact@example.com');
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/sfmc/newsletter';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(JSON.serialize(testMap));
		RestContext.request = req;
		RestContext.response = res;
		SF_MC_NewsletterController.newsletterLead();
		Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
		// true
		System.assertEquals(m.get('errors'), new List<String>());
		System.assertEquals(m.get('success'), true);
		// no errors
		// id found, because only one lead with mail
		System.assertNotEquals(m.get('id'), '');
		// status 200
		System.assertEquals(res.statusCode, 200);
	}

	private static Map<String, String> getTestMap() {
		String rt = [SELECT Id from RecordType where Name =:'Newsletteranmeldung'].Id;
		Map<String, String> testMap = new Map<String, String>();
		testMap.put('Salutation', 'Herr');
		testMap.put('FirstName', 'Max');
		testMap.put('LastName', 'Mustermann');
		testMap.put('Email', 'testing_newsletter_new_lead@example.com');
		testMap.put('OM_Token__c', 'example_token');
		testMap.put('OM_UserID__c', 'example_UserID');
		testMap.put('OM_Visit_ID__c', 'example_visitID');
		testMap.put('OM_Timestamp__c', Datetime.now().format());
		testMap.put('OM_Subscriber_Status__c', 'unconfirmed');
		testMap.put('OM_Subscriber_Key__c', 'testing_doi@example.com');
		testMap.put('OM_User_Role__c', 'example');
		testMap.put('pflegegrad__c', '2');
		testMap.put('OM_DOI_Requested_c__c', 'true');
		testMap.put('Company', 'example_company');
		testMap.put('OM_Wizzard_Name2__c', '7015800000018KMAAY');
		testMap.put('RecordTypeId', rt);
		return testMap;
	}

	//	@IsTest static void testNewsletterUpdateLead() {
	//		SF_MC_NewsletterController.data d = new SF_MC_NewsletterController.data();
	//		d.Salutation = 'Herr';
	//		d.FirstName = 'Max';
	//		d.LastName = 'Mustermann';
	//		d.Email = 'testing_newsletter_new_lead@example.com';
	//		d.OM_Token = 'example_token';
	//		d.OM_UserID = 'example_UserID123';
	//		d.OM_Visit_ID = 'example_visitID';
	//		d.OM_Timestamp = Datetime.now().format();
	//		d.OM_Subscriber_Status = 'unconfirmed';
	//		d.OM_Subscriber_Key = 'testing_doi@example.com';
	//		d.OM_User_Role = 'example';
	//		d.pflegegrad = '2';
	//		d.OM_Registered_For_Newsletter = false;
	//		d.Company = 'example_company';
	//		d.OM_Wizzard_Name2 = '7015800000018KMAAY';
	//		RestRequest req = new RestRequest();
	//		RestResponse res = new RestResponse();
	//		req.requestURI = '/services/apexrest/sfmc/newsletter';
	//		req.httpMethod = 'POST';
	//		req.requestBody = Blob.valueOf(JSON.serialize(d));
	//		RestContext.request = req;
	//		RestContext.response = res;
	//		SF_MC_NewsletterController.newsletterLead(d);
	//		Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
	//		// true
	//		System.assertEquals(m.get('success'), true);
	//		// no errors
	//		System.assertEquals(m.get('errors'), new List<String>());
	//		// id found, because only one lead with mail
	//		System.assertNotEquals(m.get('id'), null);
	//
	//	}
}