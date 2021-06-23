/*
 * **************************************************************************************************************************
 * // Created 22.07.2019 von AD
 * // Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
 * // Nordkanalstr. 58
 * // 20097 Hamburg
 * // Tel.: 04023882986
 * // Fax.: 04023882989
 * // Email: kontakt@klosesrockepartner.de
 * //
 * //****************************************************************************************************************************
 * //
 * // Parameter:
 * //****************************************************************************************************************************
 * //
 * // Description:
 * // Test Klasse.
 * //****************************************************************************************************************************
 * // Changes:
 * ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 */
@isTest
private class Formular_Erhalten_Test {

	@TestSetup static void DueDate() {
		// custom settings
		Due_Date__c dueDate = new Due_Date__c(Name = 'Antrag an PK', Follow_Up_Task_Due_Date__c = 15);
		insert dueDate;
		azhCredetials__c azh =
				new azhCredetials__c(name = 'Sandbox', Endpoint__c = 'test', User__c = 'test', password__c = 'test');
		insert azh;
		azh = new azhCredetials__c(name = 'Production', Endpoint__c = 'test', User__c = 'test', password__c = 'test');
		insert azh;
	}

	@isTest static void UpdateFiles() {
		// create products test data
		create_test_product.createProducts();
		// create contact
		create_test_product.createTestContacts(3);
		List<Contact> conList = [SELECT Id, Salutation, Name, FirstName, LastName, Email, AccountId, Betreuer__r.Salutation, Betreuer__r.Firstname, Betreuer__r.LastName FROM Contact];
		Contact con = conList[0];
		String contactId = con.Id;
		// create orders and opportunities
		create_test_product.createOrders();
		// attach filled document to contact
		ContentVersion attach = new ContentVersion();
		Blob atbody = Blob.valueOf('Test document');
		attach.VersionData = atbody;
		attach.Title = 'Formular_Alex';
		attach.PathOnClient = 'Formular_Alex.pdf';
		attach.FirstPublishLocationId = con.Id;
		attach.ContentLocation = 'S';
		insert attach;

		ContentDocument cd = [select Id, title from ContentDocument LIMIT 1];
		String documentId = cd.Id;
		// Test UpdateFiles(string documentId,string title,string recordId)
		List<ContentDocument> cdList = Formular_Erhalten.UpdateFiles(documentId, 'Antrag_PG54', contactId);
		System.assertNotEquals(0, cdList.size());
		// Test checkIfCreateOrder(String contactId)
		Boolean iscoop = Formular_Erhalten.checkIfCreateOrder(contactId);
		System.assertEquals(false, iscoop);
		// Test goToGenehmigung(String contactId, String paragraph)
		String navToOrder = Formular_Erhalten.goToGenehmigung(contactId, '54');
		System.assertNotEquals('', navToOrder);
		// Test newGenehmigung(String contactId, String paragraph, String documentId)
		String creGen = Formular_Erhalten.newGenehmigung(contactId, '54', documentId);
		System.assertNotEquals('', creGen);
		// Test getWunschCB(String contactId)
		String wunschbox = Formular_Erhalten.getWunschCB(contactId);
		System.assertNotEquals('', wunschbox);
		// Test checkInsuranceCooperativ(String contactId)
		Boolean cooperativ = Formular_Erhalten.checkInsuranceCooperativ(contactId);
		System.assertEquals(true, cooperativ);
	}

}