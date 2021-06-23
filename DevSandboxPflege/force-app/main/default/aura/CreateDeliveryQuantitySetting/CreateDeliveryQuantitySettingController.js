({
	onInit : function(component, event, helper) {
        component.set('v.editMode', true);
        helper.createDeliveryQuantitySetting(component, true);		
	},
    
    addProduct : function(component, event, helper) {
    	helper.createDeliveryQuantitySetting(component, false);		
	},
    
    removeProduct : function(component, event, helper) {
        var index = event.target.name;;
        helper.removeDeliveryQuantitySetting(component, index);        
    },
    
    openDeliveryQuantityManagerWindow : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:DeliveryQuantityManager"
        });
        evt.fire();
    },
    
    openCreateDeliveryQuantitySettingWindow : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:CreateDeliveryQuantitySetting"
        });
        evt.fire();
    } ,
    
    saveDeliveryQuantitySettings : function(component, event, helper) {
        var error = false;
        var deliveryQuantitySettings = component.get('v.deliveryQuantitySettings');
        
        // validate form data
        if(deliveryQuantitySettings.length == 0) {
               error = true;
               component.find('notifLib').showToast({
                    "title": "Fehler",
                    "variant": "error",
                    "message": "Bitte wählen Sie mindestens ein Produkt aus"
                }); 
        }
        else if(error == false){
            var selectedCurabox = component.get('v.selectedCurabox');
            if(selectedCurabox == null || selectedCurabox == '') {
                error = true;
                component.find('notifLib').showToast({
                    "title": "Fehler",
                    "variant": "error",
                    "message": "Bitte wählen Sie eine Curabox aus"
                }); 
            }
            else {
                for(var i=0; i<deliveryQuantitySettings.length; i++) {
                    var deliveryQuantitySetting = deliveryQuantitySettings[i];
                    if(deliveryQuantitySetting.Menge__c == null || deliveryQuantitySetting.Liefermenge_alt__c == null 
                       || deliveryQuantitySetting.Liefermenge_neu__c == null || deliveryQuantitySetting.valid_from__c == null 
                       || deliveryQuantitySetting.valid_to__c == null || deliveryQuantitySetting.Product__c == null) {
                        error = true;
                        component.find('notifLib').showToast({
                            "title": "Fehler",
                            "variant": "error",
                            "message": "Bitte füllen Sie alle Felder aus."
                        });  
                        break;
                    }
                }
            }
            
            if(error == false) helper.saveDeliveryQuantitySettings(component);
        }                
    }
})