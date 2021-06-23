({
    zuruck : function(component, event, helper){
        var contactId = component.get('v.recordId');
        var sObectEvent = $A.get("e.force:navigateToSObject");
        sObectEvent .setParams({
        "recordId": contactId
        });
        sObectEvent.fire();
    },
})