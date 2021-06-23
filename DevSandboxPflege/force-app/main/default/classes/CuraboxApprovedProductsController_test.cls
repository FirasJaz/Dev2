@isTest
private class CuraboxApprovedProductsController_test {

	// No Params in URL
	static testmethod void testNoParamsInUrl() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/curabox/customer/products/';
		req.httpMethod = 'GET';
		req.requestBody = Blob.valueOf('INFO HIER');
		RestContext.request = req;
		RestContext.response = res;
		CuraboxApprovedProductsController.getApprovedProducts();
		System.assertEquals(res.statusCode, 400);
	}

	// Invalid Formats
	static testmethod void testInvalidParamsInUrl() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/curabox/customer/products/';
		req.httpMethod = 'GET';
		req.requestBody = Blob.valueOf('INFO HIER');
		req.params.put('family', 'F-1234');
		req.params.put('birthdate', '12-31-2020');
		RestContext.request = req;
		RestContext.response = res;
		CuraboxApprovedProductsController.getApprovedProducts();
		JSONParser parser = JSON.createParser(res.responseBody.toString());
		String message = null;
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
					(parser.getText() == 'message')) {
				// Get the value.
				parser.nextToken();
				// Compute the grand total price for all invoices.
				message = parser.getText();
			}
		}
		System.assertEquals(message, 'invalid formatted parameters');
	}

	// No Account found return
	static testmethod void testNoAccountFoundReturn() {
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/curabox/customer/products/';
		req.httpMethod = 'GET';
		req.requestBody = Blob.valueOf('INFO HIER');
		req.params.put('family', 'F-123456');
		req.params.put('birthdate', '31.12.2020');
		RestContext.request = req;
		RestContext.response = res;
		CuraboxApprovedProductsController.getApprovedProducts();
		JSONParser parser = JSON.createParser(res.responseBody.toString());
		String message = null;
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
					(parser.getText() == 'message')) {
				// Get the value.
				parser.nextToken();
				// Compute the grand total price for all invoices.
				message = parser.getText();
			}
		}
		System.assertEquals(message, 'unknown customer');
	}

	// No Approvals found
	static testmethod void testNoApprovalsFoundReturn() {
		Account acc = new Account();
		acc.Name = 'TestName';
		Contact c = new Contact();
		c.Salutation = 'Herr';
		c.Birthdate = Date.parse('31.12.2020');
		c.LastName = 'TestNachname';
		insert c;
		acc.Contacts.add(c);
		acc.Contacts__r.add(c);
		insert acc;
		c.AccountId = acc.Id;
		update c;
		List <Account> id = [SELECT Familien_ID__c from Account where Id = :acc.Id];
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/curabox/customer/products/';
		req.httpMethod = 'GET';
		req.params.put('family', id.get(0).Familien_ID__c);
		req.params.put('birthdate', '31.12.2020');
		RestContext.request = req;
		RestContext.response = res;
		CuraboxApprovedProductsController.getApprovedProducts();
		JSONParser parser = JSON.createParser(res.responseBody.toString());
		String message = null;
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
					(parser.getText() == 'message')) {
				// Get the value.
				parser.nextToken();
				// Compute the grand total price for all invoices.
				message = parser.getText();
			}
		}
		System.assertEquals(message, 'no approval');
	}

	// No Contact
	static testmethod void testNoContactFoundReturn() {
		Account acc = new Account();
		acc.Name = 'TestName';
		Contact c = new Contact();
		c.Salutation = 'Herr';
		c.Birthdate = Date.parse('28.02.1900');
		c.LastName = 'TestNachname';
		insert c;
		acc.Contacts.add(c);
		acc.Contacts__r.add(c);
		insert acc;
		c.AccountId = acc.Id;
		update c;
		List <Account> id = [SELECT Familien_ID__c from Account where Id = :acc.Id];
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/curabox/customer/products/';
		req.httpMethod = 'GET';
		req.params.put('family', id.get(0).Familien_ID__c);
		req.params.put('birthdate', '28.02.1900');
		RestContext.request = req;
		RestContext.response = res;
		CuraboxApprovedProductsController.getApprovedProducts();
		JSONParser parser = JSON.createParser(res.responseBody.toString());
		String message = null;
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
					(parser.getText() == 'message')) {
				// Get the value.
				parser.nextToken();
				message = parser.getText();
				break;
			}
		}
		System.assertEquals(message, 'unknown contact');
	}
	// Successful request
	static testmethod void testSuccessfulRequest() {
		Account acc = new Account();
		acc.Name = 'TestName';
		Contact c = new Contact();
		c.Birthdate = Date.parse('31.12.2020');
		c.LastName = 'TestNachname';
		c.Salutation = 'Herr';
		insert c;
		acc.Contacts.add(c);
		acc.Contacts__r.add(c);
		insert acc;
		c.AccountId = acc.Id;
		update c;
		Curabox_Genehmigung__c a = new Curabox_Genehmigung__c();
		a.Nach_Paragraph__c = '54';
		a.Status__c = 'Bewilligung';
		a.Contact__c = c.Id;
		a.unbefristet_genehmigt__c = true;
		insert a;
		Curabox_Genehmigungsposition__c gp = new Curabox_Genehmigungsposition__c();
		gp.Gen_Menge_Stk__c = 3;
		gp.Genehmigung__c = [SELECT Id from Curabox_Genehmigung__c where Contact__c = :c.Id].get(0).Id;
		gp.unbefristet_genehmigt__c = true;
		insert gp;
		Order__c order = new Order__c();
		order.Status__c = 'aktiv';
		order.Delivery_frequency__c = 'monatlich';
		order.Nach_Paragraph__c = '54';
		order.Contact__c = c.Id;
		Opportunity opp = new Opportunity();
		opp.Zeitpunkt_der_Versorgung__c = 'Innerhalb von 2 Wochen';
		opp.Name = 'TestOpp';
		opp.StageName = 'TestOpp';
		opp.CloseDate = Date.today().addMonths(2);
		opp.Nachteinsaetze__c = 'Ja, gelegentlich';
		opp.Hauswirtschaftsleistungen__c = true;
		opp.Alternative_Postleitzahl__c = '22451';
		opp.ContactId = '0035800001dLOoYAAW';
		insert opp;
		order.Opportunity__c = opp.Id;
		insert order;
		List < Account > id = [SELECT Familien_ID__c from Account where Id = :acc.Id];
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/curabox/customer/products/';
		req.httpMethod = 'GET';
		req.params.put('family', id.get(0).Familien_ID__c);
		req.params.put('birthdate', '31.12.2020');
		RestContext.request = req;
		RestContext.response = res;
		CuraboxApprovedProductsController.getApprovedProducts();
		String message = null;
		JSONParser parser = JSON.createParser(res.responseBody.toString());
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
					(parser.getText() == 'message')) {
				// Get the value.
				parser.nextToken();
				message = parser.getText();
				break;
			}
		}
		System.assertEquals(message, 'application approved');
	}
	// No Approved Items
	static testmethod void testNoApprovedItemsReturn() {
		Account acc = new Account();
		acc.Name = 'TestName';
		Contact c = new Contact();
		c.Salutation = 'Herr';
		c.Birthdate = Date.parse('31.12.2020');
		c.LastName = 'TestNachname';
		insert c;
		acc.Contacts.add(c);
		acc.Contacts__r.add(c);
		insert acc;
		c.AccountId = acc.Id;
		update c;
		Curabox_Genehmigung__c a = new Curabox_Genehmigung__c();
		a.Nach_Paragraph__c = '54';
		a.Status__c = 'Antragsversand';
		a.unbefristet_genehmigt__c = true;
		a.Contact__c = c.Id;
		insert a;
		Curabox_Genehmigungsposition__c gp = new Curabox_Genehmigungsposition__c();

		gp.Gen_Menge_Stk__c = 3;
		gp.Genehmigung__c = [SELECT Id from Curabox_Genehmigung__c where Contact__c = :c.Id].get(0).Id;
		insert gp;
		List < Account > id = [SELECT Familien_ID__c from Account where Id = :acc.Id];
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/curabox/customer/products/';
		req.httpMethod = 'GET';
		req.params.put('family', id.get(0).Familien_ID__c);
		req.params.put('birthdate', '31.12.2020');
		RestContext.request = req;
		RestContext.response = res;
		CuraboxApprovedProductsController.getApprovedProducts();
		String message = null;
		JSONParser parser = JSON.createParser(res.responseBody.toString());
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
					(parser.getText() == 'message')) {
				// Get the value.
				parser.nextToken();
				message = parser.getText();
				break;
			}
		}
		System.assertEquals(message, 'application pending');
	}

	// Canceled
	static testmethod void testCancelledPerson() {
		Account acc = new Account();
		acc.Name = 'TestName';
		Contact c = new Contact();
		c.Salutation = 'Herr';
		c.Birthdate = Date.parse('31.12.2020');
		c.LastName = 'TestNachname';
		insert c;
		acc.Contacts.add(c);
		acc.Contacts__r.add(c);
		insert acc;
		c.AccountId = acc.Id;
		update c;
		Curabox_Genehmigung__c a = new Curabox_Genehmigung__c();
		a.Nach_Paragraph__c = '54';
		a.Status__c = 'Antragsversand';
		a.unbefristet_genehmigt__c = true;
		a.Contact__c = c.Id;
		insert a;
		Contact_Status__c cs = new Contact_Status__c(Contact__c = c.Id);
		cs.Productgroup__c = 'PG54';
		cs.Status__c = 'Kündigung';
		insert cs;
		Curabox_Genehmigungsposition__c gp = new Curabox_Genehmigungsposition__c();

		gp.Gen_Menge_Stk__c = 3;
		gp.Genehmigung__c = [SELECT Id from Curabox_Genehmigung__c where Contact__c = :c.Id].get(0).Id;
		insert gp;
		List < Account > id = [SELECT Familien_ID__c from Account where Id = :acc.Id];
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/curabox/customer/products/';
		req.httpMethod = 'GET';
		req.params.put('family', id.get(0).Familien_ID__c);
		req.params.put('birthdate', '31.12.2020');
		RestContext.request = req;
		RestContext.response = res;
		CuraboxApprovedProductsController.getApprovedProducts();
		String message = null;
		JSONParser parser = JSON.createParser(res.responseBody.toString());
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
					(parser.getText() == 'message')) {
				// Get the value.
				parser.nextToken();
				message = parser.getText();
				break;
			}
		}
		System.assertEquals(message, 'curabox is cancelled');
	}

}