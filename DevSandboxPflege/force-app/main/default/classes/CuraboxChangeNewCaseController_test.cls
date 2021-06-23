@isTest
private class CuraboxChangeNewCaseController_test {
  static testMethod void  caseCreatedTest() {
    Map<String, String> jsonMap = new Map<String, String>();
    jsonMap.put('Accountnumber__c', 'F-650317');
    jsonMap.put('Bettschutzeinlagen__c', '2');
    jsonMap.put('Bettschutzeinlagen_quantity__c', '1');
    jsonMap.put('Box_change__c', 'Box 6 - Flexbox');
    jsonMap.put('Einmalhandschuhe_quantity__c', '2');
    jsonMap.put('Firstname_requested_PB__c', 'Test Vorname');
    jsonMap.put('Firstname_requester__c', 'Test Nachname');
    jsonMap.put('Flaechendesinfektion_quantity__c', '2');
    jsonMap.put('Glove_size__c', 'XL');
    jsonMap.put('Haendedesinfektion_quantity__c', '2');
    jsonMap.put('Lastname_requested_PB__c', 'VersicherterVornameTest');
    jsonMap.put('Lastname_requester__c', 'VersicherterNachnameTest');
    jsonMap.put('Latex_Allergie__c', 'true');
    jsonMap.put('Mundschutz_quantity__c', '2');
    jsonMap.put('Nitril_Allergie__c', 'false');
    jsonMap.put('Origin', 'Web');
    jsonMap.put('Request_from__c', 'Angehöriger/ Pflegeperson');
    jsonMap.put('Schutzschuerzen_quantity__c', '4');
    jsonMap.put('SuppliedEmail', 'dennis.zietkoff@pflege.de');
    jsonMap.put('Vinyl_Allergie__c', 'false');
    jsonMap.put('Other_Information__c', null);

    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/curabox/change/case';
    req.httpMethod = 'POST';
    req.requestBody = Blob.valueOf(JSON.serialize(jsonMap));
    RestContext.request = req;
    RestContext.response= res;
    CuraboxChangeNewCaseController.createNewCase();
    System.assertEquals(res.statusCode, 200);
  }
  static testMethod void  caseExceptionTest() {
    Map<String, String> jsonMap = new Map<String, String>();
    jsonMap.put('Accountnumber__c', 'F-650317');
    jsonMap.put('Bettschutzeinlagen__c', '2');
    jsonMap.put('Bettschutzeinlagen_quantity__c', '1');
    jsonMap.put('Box_change__c', 'Box 6 - Flexbox');
    jsonMap.put('Einmalhandschuhe_quantity__c', '2');
    jsonMap.put('Firstname_requested_PB__c', 'Test Vorname');
    jsonMap.put('Firstname_requester__c', 'Test Nachname');
    jsonMap.put('Flaechendesinfektion_quantity__c', '2');
    jsonMap.put('Glove_size__c', 'XL');
    jsonMap.put('Haendedesinfektion_quantity__c', '2');
    jsonMap.put('Lastname_requested_PB__c', 'VersicherterVornameTest');
    jsonMap.put('Lastname_requester__c', 'VersicherterNachnameTest');
    jsonMap.put('Latex_Allergie__c', 'true');
    jsonMap.put('Mundschutz_quantity__c', '2');
    jsonMap.put('Nitril_Allergie__c', 'false');
    jsonMap.put('Origin', 'Web');
    jsonMap.put('Request_from__c', 'Angehöriger/ Pflegeperson');
    jsonMap.put('Schutzschuerzen_quantity__c', '4');
    jsonMap.put('SuppliedEmail', 'max@mustertyp.de');
    jsonMap.put('test', 'true');     //test no contact
    jsonMap.put('Vinyl_Allergie__c', 'false');
    jsonMap.put('Other_Information__c', null);
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/curabox/change/case';
    req.httpMethod = 'POST';
    req.requestBody = Blob.valueOf(JSON.serialize(jsonMap));
    RestContext.request = req;
    RestContext.response= res;
    CuraboxChangeNewCaseController.createNewCase();
    System.assertEquals(res.statusCode, 400);
  }
  static testMethod void  caseFailedTest() {
    Map<String, String> jsonMap = new Map<String, String>();
    jsonMap.put('Accountnumber__c', 'F-650317');
    jsonMap.put('Bettschutzeinlagen__c', '2');
    jsonMap.put('Bettschutzeinlagen_quantity__c', '1');
    jsonMap.put('Box_change__c', 'Box 6 - Flexbox');
    jsonMap.put('Einmalhandschuhe_quantity__c', '2');
    jsonMap.put('Firstname_requested_PB__c', 'Test Vorname');
    jsonMap.put('Firstname_requester__c', 'Test Nachname');
    jsonMap.put('Flaechendesinfektion_quantity__c', '2');
    jsonMap.put('Glove_size__c', 'XL');
    // Not a number causes error
    jsonMap.put('Haendedesinfektion_quantity__c', 'wwee');
    jsonMap.put('Lastname_requested_PB__c', 'VersicherterVornameTest');
    jsonMap.put('Lastname_requester__c', 'VersicherterNachnameTest');
    jsonMap.put('Latex_Allergie__c', 'true');
    jsonMap.put('Mundschutz_quantity__c', '2');
    jsonMap.put('Nitril_Allergie__c', 'false');
    jsonMap.put('Origin', 'Web');
    jsonMap.put('Other_Information__c', null);

    jsonMap.put('Request_from__c', 'Angehöriger/ Pflegeperson');
    // Not a number causes error

    jsonMap.put('Schutzschuerzen_quantity__c', 'asdasd');
    jsonMap.put('SuppliedEmail', 'dennis.zietkoff@pflege.de');
    jsonMap.put('Vinyl_Allergie__c', 'false');
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/curabox/change/case';
    req.httpMethod = 'POST';
    req.requestBody = Blob.valueOf(JSON.serialize(jsonMap));
    RestContext.request = req;
    RestContext.response= res;
    CuraboxChangeNewCaseController.createNewCase();
    System.assertEquals(res.statusCode, 400);
  }
}