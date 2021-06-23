({
    onDeliveryQuantitySettingsLoaded: function( component, event, helper ) {
        component.set( 'v.deliveryQuantitySettings', event.getParam( 'deliveryQuantitySettings' ) );
    },
    
    saveDeliveryQuantitySettings : function(component, event, helper) {       
        var action = component.get("c.updateDeliveryQuantitySettings");   
        action.setParams({
            "deliveryQuantitySettings" : component.get('v.deliveryQuantitySettings')          
        }); 
        action.setCallback(this, function(response) {
            var success = response.getReturnValue();
            if (success === true) {                
                component.find('notifLib').showToast({
                    "title": "Bestätigung",
                    "variant": "info",
                    "message": "Daten wurden erfolgreich gespeichert."
                });     
            } 
            else {
                component.find('notifLib').showToast({
                    "title": "Fehler",
                    "variant": "error",
                    "message": "Daten konnten nicht gespeichert werden."
                }); 
            }
        });        
        $A.enqueueAction(action);   
    }
})