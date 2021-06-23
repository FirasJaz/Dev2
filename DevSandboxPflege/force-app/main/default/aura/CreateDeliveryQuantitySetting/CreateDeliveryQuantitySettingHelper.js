({
    createDeliveryQuantitySetting : function(component, defaultSetting) {
        var action = component.get( "c.getNewDeliveryQuantitySetting" );
        action.setCallback( this, function( response ) {            
            var newDeliveryQuantitySetting = response.getReturnValue();
            if(defaultSetting == true) component.set('v.defaultDeliveryQuantitySetting', newDeliveryQuantitySetting); 
            var deliveryQuantitySettings = component.get('v.deliveryQuantitySettings');
            deliveryQuantitySettings.push(newDeliveryQuantitySetting);
            component.set('v.deliveryQuantitySettings', deliveryQuantitySettings);
        });
        $A.enqueueAction( action );
    },
    
    removeDeliveryQuantitySetting : function(component, index) {        
        var deliveryQuantitySettings = component.get('v.deliveryQuantitySettings');        
        deliveryQuantitySettings.splice(index, 1);
        component.set('v.deliveryQuantitySettings', deliveryQuantitySettings);
    },
    
    saveDeliveryQuantitySettings : function(component) {
        var selectedCuraboxName = component.get('v.selectedCuraboxName');
        var selectedCurabox = component.get('v.selectedCurabox');
        var deliveryQuantitySettings = component.get('v.deliveryQuantitySettings'); 
        var deliveryQuantitySettingKey = component.get('v.deliveryQuantitySettingKey');
        var action = component.get( "c.insertDeliveryQuantitySettings" );
        action.setParams({
            "curaboxId" : selectedCurabox,
            "curaboxName" : selectedCuraboxName,
            "deliveryQuantitySettingKey" : deliveryQuantitySettingKey,
            "deliveryQuantitySettings" : component.get('v.deliveryQuantitySettings')          
        }); 
        action.setCallback( this, function( response ) {            
            var md5Key = response.getReturnValue();
            if(md5Key != null) {
                component.set('v.md5Key', md5Key);
                component.set('v.editMode', false);
                component.find('notifLib').showToast({
                    "title": "Bestätigung",
                    "variant": "info",
                    "message": "Lieferscheinstellung wurde erfolgreich gespeichert"
                });                         
            }
            else {
                 component.find('notifLib').showToast({
                    "title": "Fehler",
                    "variant": "error",
                    "message": "Lieferscheinstellung konnte nicht gespeichert werden"
                }); 
            }
        });
        $A.enqueueAction( action );
    }
})