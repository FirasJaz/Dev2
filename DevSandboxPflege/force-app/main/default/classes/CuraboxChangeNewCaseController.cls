@RestResource (urlMapping = '/curabox/change/case')
global class CuraboxChangeNewCaseController {
  @HttpPost
  global static void createNewCase() {
    RestResponse res = RestContext.response != null ? RestContext.response : new RestResponse();
    RestRequest req = RestContext.request != null ? RestContext.request : new RestRequest();
    Map <String, Object> tempMap = (Map<String, Object>)JSON.deserializeUntyped(req.requestBody.toString());
    Map <String, String> finalMap = new Map<String, String>();
    for (String key : tempMap.keySet()) {
      if(tempMap.get(key) != null) {
        finalMap.put(key, tempMap.get(key).toString());
      }
    }
    Case c = new Case();
    for (String key : finalMap.keySet()) {
      if (key == 'test') continue; // for testing
      //if (key == 'recordType' || key == 'Kundenvorgangsursprung' || key == 'orgid' || key == 'debug') continue;
      if (finalMap.get(key) == 'null') continue;
      try {
        c.put(key, finalMap.get(key));

      } catch (Exception e) {
        try {
          c.put(key, Boolean.valueOf(finalMap.get(key)));
        } catch (Exception ee) {
          try {
            c.put(key, Decimal.valueOf(finalMap.get(key)));
          } catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(ex.getMessage() + '-------------' + key);
            return;
          }
        }
      }
      list<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :finalMap.get('SuppliedEmail')];
      if (finalMap.get('test') == 'true') contacts.add(new Contact()); //for testing
      if ((contacts != null) && (contacts.size() == 1)) {
        c.ContactId = contacts[0].Id;
      }
    }
    try {
      insert c;
      list<Case> cases = [SELECT CaseNumber FROM Case WHERE Id =:c.Id];
      String caseNr = '';
      if (finalMap.get('test') == 'true') cases = null;  // for testing
      if ((cases != null) && (cases.size() > 0)) {
        caseNr = cases[0].CaseNumber;
        res.statusCode = 200;
        res.responseBody =
            Blob.valueOf(' Case nr. ' + caseNr + ' successfully created. Id of the case: ' + c.Id);
        return;
      } else {
        CalloutException e = new CalloutException();
        e.setMessage('Failed to create and save the new Case');
        throw e;
      }
    } catch (Exception e) {
      res.statusCode = 400;
      res.responseBody = Blob.valueOf(e.getMessage());


    }
  }
}


/*
 * {
 * All needed Case FIelds
 * alesForceEssentials: {
 * // recordType: prod or sandbox
 * recordType: isProd() ? '0121i000000iBgD' : '0121i000000iBgDAAU',
 * Kundenvorgangsursprung: 'Web',
 * // origid prod or sandbox
 * orgid: isProd() ? '00D24000000JCFr' : '00D3N0000001ay2',
 * debug: isProd() ? '0' : '1',
 * Accountnumber__c: 'F-', // Kundennummer
 * Box_change__c: null,
 * // Flexbox
 * Einmalhandschuhe_quantity__c: null,
 * Haendedesinfektion_quantity__c: null,
 * Flaechendesinfektion_quantity__c: null,
 * Bettschutzeinlagen_quantity__c: null,
 * Mundschutz_quantity__c: null,
 * Schutzschuerzen_quantity__c: null,
 * Glove_size__c: null,
 * Delivery_interval__c: null,
 * change_shipping_info__c: null,
 * Stop_delivery__c: null,
 * No_entitlement_for_curabox__c: null,
 * Insurance_number__c: null,
 * Health_insurance__c: null,
 * Other_information__c: null,
 * Phone_number_PB__c: null, // PB = Pflegebedürfiger
 * Street_PB__c: null,
 * Street_ASP__c: null, // ASP = Angehöriger
 * Street_Pflegedienst__c: null,
 * Postalcode_PB__c: null,
 * Postalcode_ASP__c: null,
 * Postalcode_Packstation__c: null,
 * Postalcode_Pflegedienst__c: null,
 * E_Mail_new__c: null,
 * City_PB__c: null,
 * City_ASP__c: null,
 * City_Packstation__c: null,
 * City_Pflegedienst__c: null,
 * Pause_cb__c: null,
 * New_delivery_interval__c: null,
 * Another_supplier__c: null,
 * Firstname_PB__c: null,
 * Firstname_PB_New__c: null,
 * Firstname_ASP__c: null,
 * Firstname_Packstation__c: null,
 * Lastname_PB__c: null,
 * Lastname_PB_New__c: null,
 * Lastname_ASP__c: null,
 * Lastname_Packstation__c: null,
 * Postnummer__c: null,
 * Number_DHL_Packstation__c: null,
 * Company_name_Pflegedienst__c: null,
 * Origin: null,
 * Request_from__c: null,
 * Bettschutzeinlagen__c: null,
 * Firstname_requester__c: null,
 * Lastname_requester__c: null,
 * Firstname_requested_PB__c: null,
 * Lastname_requested_PB__c: null,
 * Birthdate_requested_PB__c: null,
 * email: null,
 * Street_PB_new__c: null,
 * Postalcode_PB_new__c: null,
 * City_PB_new__c: null,
 * Too_many_products__c: null,
 * Other_reasons_cancelation__c: null,
 * },
 */