({
    // the first method which is called. to get list of emails
    doInit: function(component, event, helper) {
        var action = component.get("c.getAllNewEmails");
        action.setCallback(this, function(a) {
            var returnValue = a.getReturnValue();
            component.set("v.newEmails", returnValue);
        });
        $A.enqueueAction(action);

        component.set('v.emailMessageDataTableColumns', helper.getDataTableColumns());
    },
    
    //opens the modal and sets the emailsMessageId
    // is called from dataTable with emailMessage-rows
    openModal: function(component, event, helper) {
        var row = event.getParam('row');
        var emailMessageId = row.Id;
        component.set("v.emailMessageId", emailMessageId);
        component.set("v.isOpen", true);
        
    },
    
    // 19.10.18 MS
    // somehow setting oppId here didnt quite work,
    // now using other component so this function is actually deprecated
    getOpportunityId: function(component, event, helper) {
        component.set("v.oppId", event.getParam('value'));
    },
    
    // call method from controller 
    markAsRead: function(component, event, helper){
        var redirectFlag = false;
        if(component.get("v.selectedOpportunity").Id != undefined){
        	var oppId = component.get("v.selectedOpportunity").Id;
        } else {
            component.set("v.errorMessage", 'Opportunity darf nicht leer sein.');
            return;
        }
        
        
        var action = component.get("c.assignToOpportunity");
        action.setParams({
            "oppId": oppId,
            "messageId":component.get("v.emailMessageId")
        });
        action.setCallback(this, function(a) {
            var returnValue = a.getReturnValue();
            if( returnValue == null){
                component.set("v.errorMessage", 'Unbekannter Fehler beim Zuordnen zu Opportunity.');
            }else if( returnValue.search("Error") != -1 ){
                component.set("v.errorMessage", returnValue);
            }else{
                component.set("v.errorMessage", 'None');
                component.set("v.isOpen", false);
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": returnValue,
                    "slideDevName": "related"
                });
                navEvt.fire();
                //$A.enqueueAction(component.get("c.redirectToOpportunity"));
            }
        });
        $A.enqueueAction(action);
    },
    
    refreshEmailList: function(component, event, helper){
        var action1 = component.get("c.getAllNewEmails");
        action1.setCallback(this, function(a) {
            var returnValue = a.getReturnValue();
            component.set("v.newEmails", returnValue);
        });
        $A.enqueueAction(action1);
    },
    
    // user is redirected to opportunity page after assigning the email to opportunity.
    /*redirectToOpportunity: function(component, event, helper){
        var oppId = component.get("v.oppId");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": oppId,
            "slideDevName": "related"
        });
        navEvt.fire();
    },*/
    
    //closes the modal
    closeModal: function(component, event, helper) { 
        component.set("v.isOpen", false);
        component.set("v.errorMessage", 'None');
    }
})