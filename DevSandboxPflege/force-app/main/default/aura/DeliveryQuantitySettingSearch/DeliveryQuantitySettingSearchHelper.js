({
    searchCuraboxes: function( component) {
        var action = component.get( "c.getCuraboxes" );
        action.setCallback( this, function( response ) {            
            var curaboxes = response.getReturnValue();
            component.set('v.curaboxes', curaboxes); 
            if(curaboxes.length > 0) {
                var defaultCurabox = curaboxes[0];
                component.set('v.curabox', defaultCurabox);
            	this.searchDeliveryQuantitySettings(component, defaultCurabox);
            }
        });
        $A.enqueueAction( action );
    },
    
    searchDeliveryQuantitySettings: function( component, selectedCurabox) {
        var searchKey = component.get("v.searchKey");
        var action = component.get( "c.getDeliveryQuantitySettings" );
        action.setParams({
        	"curabox": selectedCurabox,
            "key": searchKey
    	});
        action.setCallback( this, function( response ) {
            var event = $A.get( "e.c:DeliveryQuantitySettingsLoaded" );
            var deliveryQuantitySettings = response.getReturnValue();               
            event.setParams({
                "deliveryQuantitySettings": deliveryQuantitySettings                
            });
            event.fire();
        });
        $A.enqueueAction( action );
    }
})