@isTest
private class SF_MC_DOIController_test {
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

	@IsTest static void testSetOptinOnLeadId() {
		Map<String, String> testMap = getTestMapMCConnect(false);
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/sfmc/doi';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(JSON.serialize(testMap));
		RestContext.request = req;
		RestContext.response = res;
		SF_MC_DOIController.OptInSetter();
		Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
		Lead l = [SELECT OM_Registered_For_Newsletter__c, IndividualId, OM_Subscriber_Status__c FROM Lead where Id =:testMap.get(
				SFIDKEY) limit 1];
		Individual ind = [SELECT OM_Opt_In__c, OM_OptIn_Source_Lead__c FROM Individual where Id=:l.IndividualId limit 1];
		// is subscribed after doi
		System.assertEquals(ind.OM_Opt_In__c, true);
		System.assertEquals(ind.OM_OptIn_Source_Lead__c, l.Id);
		// json response
		System.assertEquals(m.get('success'), true);
		System.assertEquals(m.get('errors'), new List<String>());
		System.assertNotEquals(m.get('id'), null);
	}

	@IsTest static void testSetOptinOnContactId() {
		Map<String, String> testMap = getTestMapMCConnect(true);
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/sfmc/doi';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(JSON.serialize(testMap));
		RestContext.request = req;
		RestContext.response = res;
		SF_MC_DOIController.OptInSetter();
		Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
		Contact c = [SELECT OM_Registered_For_Newsletter__c, IndividualId, OM_Subscriber_Status__c FROM Contact where Id =:testMap.get(
				SFIDKEY) limit 1];
		Individual ind = [SELECT OM_Opt_In__c, OM_OptIn_Source_Lead__c, OM_OptIn_Source_Contact__c FROM Individual where Id=:c.IndividualId limit 1];
		// is subscribed after doi
		System.assertEquals(ind.OM_Opt_In__c, true);
		System.assertEquals(ind.OM_OptIn_Source_Contact__c, c.Id);
		// json response
		System.assertEquals(m.get('success'), true);
		System.assertEquals(m.get('errors'), new List<String>());
		System.assertNotEquals(m.get('id'), null);
	}


	private static Map<String, String> getTestMapMCConnect(Boolean contact) {
		Map<String, String> testMap = new Map<String, String>();
		Contact c;
		Lead l;
		if(contact) {
			c = [SELECT Id from Contact where Email ='testing_contact@example.com' limit 1];

		}
		else {
			l = [SELECT Id from Lead where Email ='mail.doi@example.org' limit 1];
		}
		testMap.put(SFIDKEY, contact ? c.id : l.id);
		testMap.put(OPTINKEY, 'true');
		testMap.put(TIMESTAMPKEY, String.valueOf(Datetime.now()));
		return testMap;
	}
}