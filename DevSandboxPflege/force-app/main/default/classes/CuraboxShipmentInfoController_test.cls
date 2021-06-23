@isTest
private class CuraboxShipmentInfoController_test {

  // No Params in URL
  static testmethod void testNoParamsInUrl() {
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/curabox/customer/shipment/';
    req.httpMethod = 'GET';
    req.requestBody = Blob.valueOf('INFO HIER');
    RestContext.request = req;
    RestContext.response = res;
    CuraboxShipmentInfoController.getShipmentInfo();
    System.assertEquals(res.statusCode, 400);
  }

    // Invalid Formats
  static testmethod void testInvalidParamsInUrl() {
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/curabox/customer/shipment/';
    req.httpMethod = 'GET';
    req.requestBody = Blob.valueOf('INFO HIER');
    req.params.put('family', 'F-1234');
    req.params.put('birthdate', '12-31-2020');
    RestContext.request = req;
    RestContext.response = res;
    CuraboxShipmentInfoController.getShipmentInfo();
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
    req.requestURI = '/services/apexrest/curabox/customer/shipment/';
    req.httpMethod = 'GET';
    req.requestBody = Blob.valueOf('INFO HIER');
    req.params.put('family', 'F-123456');
    req.params.put('birthdate', '31.12.2020');
    RestContext.request = req;
    RestContext.response = res;
    CuraboxShipmentInfoController.getShipmentInfo();
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

  // No Tracking number
 /* static testmethod void testNoTrackingNumberFoundReturn() {
    Account acc = new Account();
    acc.Name = 'TestName';
    Contact c = new Contact();
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
    req.requestURI = '/services/apexrest/curabox/customer/shipment/';
    req.httpMethod = 'GET';
    req.params.put('family', id.get(0).Familien_ID__c);
    req.params.put('birthdate', '31.12.2020');
    RestContext.request = req;
    RestContext.response = res;
    CuraboxShipmentInfoController.getShipmentInfo();
    Map<String, String> resMap = (Map<String, String>)
        JSON.deserialize(res.responseBody.toString(), Map<String, String>.class);
    System.assertEquals(resMap.get('message'), 'No Trackingnumber on contact ID'+ c.Id+' found');
  }*/

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
    req.requestURI = '/services/apexrest/curabox/customer/shipment/';
    req.httpMethod = 'GET';
    req.params.put('family', id.get(0).Familien_ID__c);
    req.params.put('birthdate', '28.02.1900');
    RestContext.request = req;
    RestContext.response = res;
    CuraboxShipmentInfoController.getShipmentInfo();
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

  // Everything is fine
  static testmethod void testSuccessfulRequest() {
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
    a.Status__c = 'Bewilligung';
    a.Contact__c = c.Id;
    a.unbefristet_genehmigt__c = true;
    insert a;
    Delivery_Note__c d = new Delivery_Note__c();
    d.Contact__c = c.Id;
    d.DHL_shipping_number__c = 'TestNumber';
    d.Delivery_date__c = Date.today();
    insert d;
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
    List <Account> id = [SELECT Familien_ID__c from Account where Id = :acc.Id];
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/curabox/customer/shipment/';
    req.httpMethod = 'GET';
    req.params.put('family', id.get(0).Familien_ID__c);
    req.params.put('birthdate', '31.12.2020');
    RestContext.request = req;
    RestContext.response = res;
    CuraboxShipmentInfoController.getShipmentInfo();
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
    System.assertEquals(message, 'application approved');
  }

  // Everything is fine
  static testmethod void testSuccesfulRequestPendingApplication() {
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
    a.Contact__c = c.Id;
//    a.unbefristet_genehmigt__c = true;
    insert a;
    Delivery_Note__c d = new Delivery_Note__c();
    d.Contact__c = c.Id;
    d.DHL_shipping_number__c = 'TestNumber';
    d.Delivery_date__c = Date.today();
    insert d;
    List <Account> id = [SELECT Familien_ID__c from Account where Id = :acc.Id];
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/curabox/customer/shipment/';
    req.httpMethod = 'GET';
    req.params.put('family', id.get(0).Familien_ID__c);
    req.params.put('birthdate', '31.12.2020');
    RestContext.request = req;
    RestContext.response = res;
    CuraboxShipmentInfoController.getShipmentInfo();
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
    System.assertEquals(message, 'application pending');
  }
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
    req.requestURI = '/services/apexrest/curabox/customer/shipment/';
    req.httpMethod = 'GET';
    req.params.put('family', id.get(0).Familien_ID__c);
    req.params.put('birthdate', '31.12.2020');
    RestContext.request = req;
    RestContext.response = res;
    CuraboxShipmentInfoController.getShipmentInfo();
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
}