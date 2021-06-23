({
    init : function(component, event, helper) {
        var action = component.get('c.getContactById');
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res != null){
                    component.set('v.contact', res);   
                }  
            }
            else{
                console.log(state);
            }
        });
        $A.enqueueAction(action);
    },

    zuruck : function(component, event, helper){
        var contactId = component.get('v.recordId');
        var sObectEvent = $A.get("e.force:navigateToSObject");
        sObectEvent .setParams({
        "recordId": contactId
        });
        sObectEvent.fire();
    },

    showOrders : function( component, event, helper ) {
        var contactId = component.get('v.recordId');
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
        componentDef:"c:Order_Overview",
        componentAttributes: {
            "recordId": contactId
        }});
        evt.fire();
    },

})