({
    // fill product without gloves
    fillFlexibel: function (component) {
        var action = component.get("c.fillWunschboxComponent");
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var rows = response.getReturnValue();
                if(rows.length > 0){
                    component.set('v.isFlexibel', true);
                    component.set('v.orderLines', rows);
                }
                else{
                    component.set('v.isFlexibel', false);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
         });
         $A.enqueueAction(action);
    },

    // set gloves informations.
    setGloveDetails: function(component){
        var contactId = component.get('v.recordId');
        var action = component.get('c.getGloveDetails');
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                component.set('v.selectedGlove', res.name);
                component.find('glove_1').set('v.value', res.name);
                component.find('glove_2').set('v.value', res.name);
                component.set('v.gloveQuantity1', res.menge);
                component.set('v.glovePrice1', res.price);
                component.set('v.gloveTotal1', res.summe);
                component.set('v.glovePrice2', res.price);
                if(res.menge == 1){
                    component.set('v.isZweiEH', false);
                    var number = component.find('glove_quantity');
                    var btnSave = component.find('btn_save');
                    var glove1 = component.find('glove_1');
                    number.set('v.disabled', true);
                    btnSave.set('v.disabled', true);
                    glove1.set('v.disabled', true);
                }
                else{
                    component.set('v.isZweiEH', true);
                }
            }
            else{
                console.log(state);
            }
        });
        $A.enqueueAction(action);   
    },
    
    // get all gloves to display
    getGloves: function(component){
        var action = component.get('c.getGloveList');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res != null){
                    component.set('v.gloves', res);
                }
            }
            else{
                console.log(state);
            }
        });
        $A.enqueueAction(action);   
    },

    saveWunschbox: function(component){
        var productList = component.get('v.orderLines');
        var contactId = component.get('v.recordId');
        var glove1 = component.find('glove_1').get('v.value');
        var glove2 = component.find('glove_2').get('v.value');
        var quantity1 = component.get('v.gloveQuantity1');
        var quantity2 = component.get('v.gloveQuantity2');
        var action = component.get("c.insertWunschbox");
        action.setParams({
            "contactId": contactId,
            "productList": productList,
            "glove1": glove1,
            "glove2": glove2,
            "quantity1": quantity1,
            "quantity2": quantity2,  
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state == "SUCCESS") {
              var res = response.getReturnValue();
              if(res != null){
                var toastEvent = $A.get("e.force:showToast");
                      toastEvent.setParams({
                      title:'Success Message',
                      message:'Wunschbox wurde erfolgreich gespeichert',
                      key:'info_alt',
                      type:'Success',
                      mode:'pester'
                });
                  toastEvent.fire();
                  $A.get("e.force:closeQuickAction").fire();
              
                }  
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                title:'Success Message',
                message:'Fehler bei der Speicherung des Wunschboxes',
                key:'info_alt',
                type:'Error',
                mode:'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
                
    },

    // handle glove quantity
    handleGloveQuantity: function(component, quantity, price2){
        var isFlex = component.get('v.isFlexibel');
        var isZwei = component.get('v.isZweiEH');
        var cmp2 = component.find('glove_quantity2');
        var cmp = component.find('glove_quantity');
        if(isFlex == true){
            cmp.set('v.max', 10);
            cmp2.set('v.max', 10);
        }
        else{
            if(isZwei == true){
                if(quantity > 1){
                    component.set('v.gloveQuantity2', 0);
                    cmp2.set('v.max', 0);
                    component.set('v.gloveTotal2', 0);
                }
                else if(quantity == 1 ){
                    component.set('v.gloveQuantity2', 1);
                    cmp2.set('v.max', 1);
                    component.set('v.gloveTotal2', (price2).toFixed(2));
                }
                else if(quantity == 0){
                    component.set('v.gloveQuantity2', 2);
                    cmp2.set('v.max', 2);
                    component.set('v.gloveTotal2', 2*((price2).toFixed(2)));
                }
            }
            else{
                cmp.set('v.max', 1);
            }
        }
    },

})