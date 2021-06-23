@RestResource(urlMapping = '/sfmc/doi-update')
global class SF_MC_DOIUpdateController {
	// mappings
	private static string SFIDKEY = SF_MC_Statics.SFIDKEY;
	private static string OPTINKEY = SF_MC_Statics.OPTINKEY;
	// errors
	private static string NOINDIVIDUALFOUNDERROR = SF_MC_Statics.NOINDIVIDUALFOUNDERROR;
	private static string INDIVUDUALUPDATEERROR = SF_MC_Statics.INDIVUDUALUPDATEERROR;


	@HttpPatch
	global static void updateNewsletter() {
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
		// Unsibscribe
		try {
			if (Boolean.valueOf(finalMap.get(OPTINKEY)) == false) {
				List<Individual> indiList = [SELECT OM_Opt_In__c, OM_OptOut_Timestamp__c, OM_Registered_For_Newsletter__c, OM_OptOut__c FROM Individual WHERE Email__c =: finalMap.get(
						'email')];
				if (indiList.isEmpty()) {
					CalloutException ce = new CalloutException(NOINDIVIDUALFOUNDERROR);
					throw ce;
				}
				Individual indi = indiList.get(0);
				indi.OM_OptOut__c = true;
				try {
					update indi;
				} catch (Exception e) {
					err.add(INDIVUDUALUPDATEERROR + e.getMessage() + e.getStackTraceString());
				}
			}
			// resubsctibe
			else {
				List<Individual> individuals = [SELECT OM_Opt_In__c, OM_OptOut_Timestamp__c, OM_Registered_For_Newsletter__c, OM_OptOut__c FROM Individual WHERE Email__c =: finalMap.get(
						'email') ORDER BY OM_OptIn_Timestamp__c DESC];
				if (individuals.isEmpty()) {
					CalloutException ce = new CalloutException(NOINDIVIDUALFOUNDERROR);
					throw ce;
				}
				Individual indi = individuals.get(0);
				indi.OM_Opt_In__c = true;

			}
		} catch (CalloutException ce) {
			err.add(ce.getMessage() + ce.getStackTraceString());
		}
		// response
		JSONResponseGenerator.SFResponse r = new JSONResponseGenerator.SFResponse();
		r.errors
				= new

				List< String > (err);
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