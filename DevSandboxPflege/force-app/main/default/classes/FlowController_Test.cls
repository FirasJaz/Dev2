@isTest
public class FlowController_Test{
	

	static testMethod void test_FollowUpTasksController(){
		//create contact
		Contact contact = new Contact(Lastname = 'test', Email = 'test@email.com');
		insert contact;
		//create follow up task 
		List<Follow_up_Task__c> tasks = new List<Follow_up_Task__c>();
		Follow_up_Task__c followUpTask = new Follow_up_Task__c(Subject__c = 'Lieferung angehalten', Due_Date__c = System.now(), contact__c = contact.Id);
		insert followUpTask;
		tasks.add(followUpTask);
		//instanciate  FlowController class
		FlowController flowController = new FlowController();
        flowController.followUpTasksToUpdate=tasks;
		//edit  a followUpTask in followUpTasksToUpdate
		flowController.followUpTasksToUpdate[0].Due_Date__c = System.now()+1;
        //check UpdatedFollowUpTasks
		System.assertEquals(flowController.UpdatedFollowUpTasks == null, false);
   
      	//assign contactId
        flowController.contactId=contact.Id;
        //check contact
		System.assertEquals(flowController.Contact == null, false);
	}
    
 
}