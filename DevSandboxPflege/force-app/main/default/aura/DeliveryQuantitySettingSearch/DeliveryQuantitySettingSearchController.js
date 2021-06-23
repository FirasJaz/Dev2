({
    onInit: function (component, event, helper) { 
        /*
         *	search available curaboxes, set default curabox
         *  and search delivery quantity settings for the default curabox
         */     
        helper.searchCuraboxes(component);         
    },
    
    onCuraboxChange: function(component, event) {   
        var selectedcurabox = component.find('selectCurabox').get('v.value'); 
        component.set("v.curabox", selectedcurabox);        
    },
    
	searchDeliveryQuantitySettings : function(component, event, helper) {               
        var selectedCurabox = component.get("v.curabox"); 
		helper.searchDeliveryQuantitySettings(component, selectedCurabox);      
    },
    
	openUploadWindow : function(component, event, helper) {
		 window.open("/apex/UploadDeliverySetting");
	},
    
   	openCreateDeliveryQuantitySettingWindow : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:CreateDeliveryQuantitySetting"
        });
        evt.fire();
    } 
})