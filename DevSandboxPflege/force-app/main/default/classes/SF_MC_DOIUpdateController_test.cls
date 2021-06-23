@isTest
private class SF_MC_DOIUpdateController_test {
	private static final string SFIDKEY = SF_MC_Statics.SFIDKEY;
	private static final string OPTINKEY = SF_MC_Statics.OPTINKEY;
	private static final string TIMESTAMPKEY = SF_MC_Statics.TIMESTAMPKEY;
	@testSetup static void insertTestLeads() {
		Lead l = new Lead(Salutation = 'Herr',
				FirstName = 'Max',
				LastName = 'Mustermann',
				Email = 'mail.doi@example.org',
				OM_Token__c = 'example_token',
				OM_UserID__c = 'example_UserID',
				OM_Visit_ID__c = 'example_visitID',
				OM_Timestamp__c = Datetime.now().format(),
				OM_Subscriber_Status__c = 'unconfirmed',
				OM_Subscriber_Key__c = 'testing_doi@example.com',
				OM_User_Role__c = 'example',
				pflegegrad__c = '2',
				OM_Registered_For_Newsletter__c = false,
				Company = 'example_company',
				OM_Wizzard_Name2__c = '7015800000018KMAAY');
		insert l;
		Contact c = new Contact(OM_DOI_Requested_c__c = true,
				Pflegegrad__c = 'pflegegrad vorhanden',
				LastName = 'Mustermann',
				FirstName = 'Max',
				Email = 'testing_contact@example.com');
		insert c;

	}

	@isTest static void doiUpdateResubscribeOnContact() {
		Map<String, String> testMap = getTestMapMCConnect(true);
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/sfmc/doi-update';
		req.httpMethod = 'PATCH';
		req.requestBody = Blob.valueOf(JSON.serialize(testMap));
		RestContext.request = req;
		RestContext.response = res;
		SF_MC_DOIUpdateController.updateNewsletter();
		Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
		// true
		System.assertEquals(m.get('success'), true);
		// no errors
		System.assertEquals(m.get('errors'), new List<String>());
		// id found, because only one lead with mail
		System.assertNotEquals(m.get('id'), null);
	}

	private static Map<String, String> getTestMapMCConnect(Boolean contact) {
		Map<String, String> testMap = new Map<String, String>();

		testMap.put(OPTINKEY, 'true');
		testMap.put('email', contact ? 'testing_contact@example.com' : 'mail.doi@example.org');
		return testMap;
	}

}