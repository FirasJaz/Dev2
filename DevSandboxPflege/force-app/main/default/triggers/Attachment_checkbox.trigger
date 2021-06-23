//Trigger to update the Checkbox_Attachment__c checkbox field in Task //if it has any attachments.
trigger Attachment_checkbox on attachment (after insert) {
	List<Task> co = [select id, Checkbox_Attachment__c from Task where id =: Trigger.New[0].ParentId];
		if(co.size()>0) {
			co[0].Checkbox_Attachment__c = true;
			update co;
		}
}