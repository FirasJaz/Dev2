@RestResource(urlMapping = '/curabox/customer/products/')
global class CuraboxApprovedProductsController {


	@HttpGet
	global static void getApprovedProducts() {
		RestResponse res = RestContext.response != null ? RestContext.response : new RestResponse();
		RestRequest req = RestContext.request != null ? RestContext.request : new RestRequest();
		res.addHeader('Content-Type', 'application/json');
		if (req.params.containsKey(CuraboxCustomerHelpers.FAMILYKEY) && req.params.containsKey(CuraboxCustomerHelpers.BIRTHDATEKEY)) {
			if (CuraboxCustomerHelpers.validParams(req.params.get(CuraboxCustomerHelpers.FAMILYKEY), req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY))) {
				string familyId = req.params.get(CuraboxCustomerHelpers.FAMILYKEY);
				Date birthdate = Date.parse(req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY));
				//    string familyId = 'F-655942';
				//    Date birthdate = Date.parse('03.01.1960');
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
				if (CuraboxCustomerHelpers.isCandidate(contactId)) {
					JSONResponseGenerator.CanceledCuraboxResponse par =
							new JSONResponseGenerator.CanceledCuraboxResponse();
					par.message = CuraboxCustomerHelpers.CANDIDATEAPPLICATION;
					CuraboxCustomerHelpers.createResMessage(res, 200, 'success', par);
					return;
				}
				List<Curabox_Genehmigung__c> approvalList = CuraboxCustomerHelpers.getApprovalId(contactId);
				// send no approved
				if (approvalList == null) {
					JSONResponseGenerator.FailedSubmittedData responseJSON =
							new JSONResponseGenerator.FailedSubmittedData();
					responseJSON.message = CuraboxCustomerHelpers.NOAPPROVAL;
					Map<String, String> submitted = new Map<String, String>();
					submitted.put(CuraboxCustomerHelpers.FAMILYKEY, familyId);
					submitted.put(CuraboxCustomerHelpers.BIRTHDATEKEY, req.params.get(CuraboxCustomerHelpers.BIRTHDATEKEY));
					submitted.put(CuraboxCustomerHelpers.ACCOUNTIDKEY, accountId);
					responseJSON.submitted = submitted;
					CuraboxCustomerHelpers.createResMessage(res, 400, 'fail', responseJSON);
					return;
				}
				List<Curabox_Genehmigungsposition__c> approvedList = new List<Curabox_Genehmigungsposition__c>();
				for (Curabox_Genehmigung__c approval : approvalList) {
					List<Curabox_Genehmigungsposition__c> temp = new List<Curabox_Genehmigungsposition__c>();
					if ((approval.genehmigt_bis__c > Date.today() || approval.unbefristet_genehmigt__c) &&
									approval.Status__c == CuraboxCustomerHelpers.APPROVEDSTATUS) {
						temp = CuraboxCustomerHelpers.getApprovedProducts(approval.Id);
						approvedList.addAll(temp);
					}
				}
				// genehmigt
				if (approvedList.size() > 0) {
					JSONResponseGenerator.ApprovedResponse responseObject =
							CuraboxCustomerHelpers.generateResponseObject(approvedList);
					responseObject.message = CuraboxCustomerHelpers.APPROVEDAPPLICATION;
					responseObject.tracking_data = CuraboxCustomerHelpers.getTrackingData(contactId);
					CuraboxCustomerHelpers.createResMessage(res, 200, 'success', responseObject);
					return;
				}
				// antragsversand
				for (Curabox_Genehmigung__c approval : approvalList) {
					if (approval.Status__c == CuraboxCustomerHelpers.PENIDINGSTATUS && approval.Nach_Paragraph__c == CuraboxCustomerHelpers.CBPARAGRAPH) {
						// curabox
						JSONResponseGenerator.PendingApprovalResponse par =
								new JSONResponseGenerator.pendingApprovalResponse();
						//            par.tracking_data = CuraboxCustomerHelpers.getTrackingData(contactId);
						par.message = CuraboxCustomerHelpers.APPROVALPENDING;
						CuraboxCustomerHelpers.createResMessage(res, 200, 'success', par);
						return;
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
			CuraboxCustomerHelpers.createResMessage(res, 400, 'fail', responseJSON);
			return;
		}
	}

}