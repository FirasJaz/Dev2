@RestResource(urlMapping = '/sfmc/doi')
global class SF_MC_DOIController {
	// mappings
	private static final string SFIDKEY = SF_MC_Statics.SFIDKEY;
	private static final string OPTINKEY = SF_MC_Statics.OPTINKEY;
	private static final string TIMESTAMPKEY = SF_MC_Statics.TIMESTAMPKEY;

	// errors
	private static final string NOOBJECTFOUNDERROR = SF_MC_Statics.NOOBJECTFOUNDERROR;
	private static final string NOINDIVIDUALFOUNDONLEAD = SF_MC_Statics.NOINDIVIDUALFOUNDONLEAD;
	private static final string NOINDIVIDUALFOUNDONCONTACT = SF_MC_Statics.NOINDIVIDUALFOUNDONCONTACT;
	private static final string INDIVUDUALUPDATEERROR = SF_MC_Statics.INDIVUDUALUPDATEERROR;

	@HttpPost
	global static void OptInSetter() {
		List<String> err = new List<String>();
		RestResponse res = RestContext.response != null ? RestContext.response : new RestResponse();
		RestRequest req = RestContext.request != null ? RestContext.request : new RestRequest();
		res.addHeader('Content-Type', 'application/json');
		Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
		Map <String, String> finalMap = new Map<String, String>();
		for (String key : dataMap.keySet()) {
			if (dataMap.get(key) != null) {
				finalMap.put(key, dataMap.get(key).toString());
			}
		}
		// there is a leadID, so we're setting the optin on the specified lead
		if (finalMap.containsKey(SFIDKEY)) {
			try {
				Individual individualToUpdate;
				// look for contact
				List<Contact> contacts = [SELECT IndividualId FROM Contact where Id =:finalMap.get(SFIDKEY)];
				// if no contacts found, try to look if there is a lead with this id
				if (contacts.isEmpty()) {
					List<Lead> leads = [SELECT IndividualId FROM Lead where Id =:finalMap.get(SFIDKEY)];
					// nothing found, throw error
					if (leads.isEmpty()) {
						CalloutException e =
								new CalloutException(NOOBJECTFOUNDERROR + finalMap.get(SFIDKEY));
						throw e;
					}
					// set Optin for this individum
					Lead l = leads.get(0);
					List<Individual> individualList = [SELECT OM_Opt_In__c FROM Individual WHERE Id=:l.IndividualId];
					if (individualList.isEmpty()) {
						CalloutException e =
								new CalloutException(NOINDIVIDUALFOUNDONLEAD + l.IndividualId);
						throw e;
					}
					individualToUpdate = individualList.get(0);
					individualToUpdate.OM_OptIn_Source_Contact__c = null;
					individualToUpdate.OM_OptIn_Source_Lead__c = l.Id;

				} else {
					Contact c = contacts.get(0);
					List<Individual> individualList = [SELECT OM_Opt_In__c FROM Individual WHERE Id=:c.IndividualId];
					if (individualList.isEmpty()) {
						CalloutException e =
								new CalloutException(NOINDIVIDUALFOUNDONCONTACT + c.IndividualId);
						throw e;
					}
					individualToUpdate = individualList.get(0);
					individualToUpdate.OM_OptIn_Source_Contact__c = c.Id;
					individualToUpdate.OM_OptIn_Source_Lead__c = null;


				}
				individualToUpdate.OM_Opt_In__c = Boolean.valueOf(finalMap.get(OPTINKEY));
				individualToUpdate.OM_Last_DOI_Accomplished__c = true;
				individualToUpdate.OM_OptIn_Timestamp__c = Datetime.valueOf(finalMap.get(TIMESTAMPKEY));
				try {
					update individualToUpdate;
				} catch (Exception e) {
					CalloutException ex =
							new CalloutException(INDIVUDUALUPDATEERROR + e.getMessage() + e.getStackTraceString());

					throw ex;
				}
			} catch (CalloutException e) {
				err.add(e.getMessage());
			}
		}
		// response
		JSONResponseGenerator.SFResponse r = new JSONResponseGenerator.SFResponse();
		r.errors = new List<String>(err);
		if (r.errors.size() > 0) {
			r.success = false;
			res.statusCode = 400;
			r.id = null;
		} else {
			r.success = true;
			res.statusCode = 200;
			r.id = finalMap.get(SFIDKEY);
		}
		res.responseBody = Blob.valueOf(JSONResponseGenerator.generateJsonResponse(r));
		return;
	}
}