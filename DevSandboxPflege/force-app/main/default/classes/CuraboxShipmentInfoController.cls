@RestResource(urlMapping = '/curabox/customer/shipment/')
global class CuraboxShipmentInfoController {

	@HttpGet
	global static void getShipmentInfo() {
		RestResponse res = RestContext.response != null ? RestContext.response : new RestResponse();
		RestRequest req = RestContext.request != null ? RestContext.request : new RestRequest();
		res.addHeader('Content-Type', 'application/json');
		if (req.params.containsKey(CuraboxCustomerHelpers.FAMILYKEY) &&
				req.params.containsKey(CuraboxCustomerHelpers.BIRTHDATEKEY)) {
			if (CuraboxCustomerHelpers.validParams(req.params.get(CuraboxCustomerHelpers.FAMILYKEY),
					req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY))) {
				string familyId = req.params.get(CuraboxCustomerHelpers.FAMILYKEY);
				Date birthdate = Date.parse(req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY));
				string accountId = CuraboxCustomerHelpers.getAccountId(familyId, birthdate);
				if (accountId == '0') {
					JSONResponseGenerator.FailedSubmittedData responseJSON =
							new JSONResponseGenerator.FailedSubmittedData();
					responseJSON.message = CuraboxCustomerHelpers.UNKNOWNCUSTOMER;
					Map<String, String> j = new Map<String, String>();
					j.put(CuraboxCustomerHelpers.FAMILYKEY, familyId);
					j.put(CuraboxCustomerHelpers.BIRTHDATEKEY, req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY));
					responseJSON.submitted = j;
					CuraboxCustomerHelpers.createResMessage(res, 400, 'fail', responseJSON);
					return;
				}
				string contactId = CuraboxCustomerHelpers.getContactId(accountId, birthdate);
				if (contactId == '0') {
					JSONResponseGenerator.FailedSubmittedData responseJSON =
							new JSONResponseGenerator.FailedSubmittedData();
					responseJSON.message = CuraboxCustomerHelpers.UNKNOWNCONTACT;
					Map<String, String> j = new Map<String, String>();
					j.put(CuraboxCustomerHelpers.FAMILYKEY, familyId);
					j.put(CuraboxCustomerHelpers.BIRTHDATEKEY, req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY));
					j.put(CuraboxCustomerHelpers.ACCOUNTIDKEY, accountId);
					responseJSON.submitted = j;
					CuraboxCustomerHelpers.createResMessage(res, 400, 'fail', responseJSON);
					return;
				}
				// check if cancelled curabox
				if (CuraboxCustomerHelpers.isCancelled(contactId)) {
					JSONResponseGenerator.CanceledCuraboxResponse par =
							new JSONResponseGenerator.CanceledCuraboxResponse();
					par.message = CuraboxCustomerHelpers.CANCELLEDAPPLICATION;
					CuraboxCustomerHelpers.createResMessage(res, 400, 'fail', par);
					return;
				}
				// status = Kandidat
				if (CuraboxCustomerHelpers.isCandidate(contactId)) {
					JSONResponseGenerator.CanceledCuraboxResponse par =
							new JSONResponseGenerator.CanceledCuraboxResponse();
					par.message = CuraboxCustomerHelpers.CANDIDATEAPPLICATION;
					CuraboxCustomerHelpers.createResMessage(res, 200, 'success', par);
					return;
				}
				List<Curabox_Genehmigung__c> approvalId = CuraboxCustomerHelpers.getApprovalId(contactId);
				if (approvalId == null) {
					JSONResponseGenerator.FailedSubmittedData responseJSON =
							new JSONResponseGenerator.FailedSubmittedData();
					responseJSON.message = CuraboxCustomerHelpers.NOAPPROVAL;
					Map<String, String> submitted = new Map<String, String>();
					submitted.put(CuraboxCustomerHelpers.FAMILYKEY, familyId);
					submitted.put(CuraboxCustomerHelpers.BIRTHDATEKEY,
							req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY));
					submitted.put(CuraboxCustomerHelpers.ACCOUNTIDKEY, accountId);
					responseJSON.submitted = submitted;
					CuraboxCustomerHelpers.createResMessage(res, 400, 'fail', responseJSON);
					return;
				}
				for (Curabox_Genehmigung__c t : approvalId) {
					if ((t.genehmigt_bis__c >= Date.today() || t.unbefristet_genehmigt__c) &&
									t.Status__c == CuraboxCustomerHelpers.APPROVEDSTATUS) {
						JSONResponseGenerator.ApprovedShipmentResponse par =
								new JSONResponseGenerator.ApprovedShipmentResponse();
						par.tracking_data = CuraboxCustomerHelpers.getTrackingData(contactId);
						par.message = CuraboxCustomerHelpers.APPROVEDAPPLICATION;
						CuraboxCustomerHelpers.createResMessage(res, 200, 'success', par);
					}
				}
				for (Curabox_Genehmigung__c t : approvalId) {
					if (t.Status__c == CuraboxCustomerHelpers.PENIDINGSTATUS &&
									t.Nach_Paragraph__c == CuraboxCustomerHelpers.CBPARAGRAPH) {
						// curabox
						JSONResponseGenerator.PendingApprovalShipmentResponse par =
								new JSONResponseGenerator.PendingApprovalShipmentResponse();
						par.message = CuraboxCustomerHelpers.APPROVALPENDING;
						CuraboxCustomerHelpers.createResMessage(res, 200, 'success', par);
					}
				}
			} else {
				JSONResponseGenerator.FailedSubmittedData responseJSON =
						new JSONResponseGenerator.FailedSubmittedData();
				responseJSON.message = 'invalid formatted parameters';
				Map<String, String> submitted = new Map<String, String>();
				submitted.put(CuraboxCustomerHelpers.FAMILYKEY, req.params.get(CuraboxCustomerHelpers.FAMILYKEY));
				submitted.put(CuraboxCustomerHelpers.BIRTHDATEKEY, req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY));
				responseJSON.submitted = submitted;
				CuraboxCustomerHelpers.createResMessage(res, 400, 'fail', responseJSON);
				return;
			}
		} else {
			JSONResponseGenerator.FailedSubmittedData responseJSON =
					new JSONResponseGenerator.FailedSubmittedData();
			responseJSON.message = 'no family and birthdate parameters provided';
			//      Map<String, String> submitted = new Map<String, String>();
			//      submitted.put(CuraboxCustomerHelpers.FAMILYKEY, req.params.get(CuraboxCustomerHelpers.FAMILYKEY));
			//      submitted.put(CuraboxCustomerHelpers.BIRTHDATEKEY, req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY));
			//      responseJSON.submitted = submitted;
			CuraboxCustomerHelpers.createResMessage(res, 400, 'fail', responseJSON);
			return;
		}

	}

}