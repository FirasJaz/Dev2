({
    // set default curabox
    setCurabox : function(component) {
        var action = component.get("c.getCuraboxByContact");
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var curabox = response.getReturnValue();
                if(curabox != null){
                    if((curabox == "CB1") || (curabox == "CB2") || (curabox == "CB3") || (curabox == "CB4") || (curabox == "CB5")){
                        component.set('v.isCBFlexibel', false);
                    }
                    else{
                        component.set('v.isCBFlexibel', true);
                    }
                    component.find('cura_box').set('v.value', curabox);
                    component.set('v.selectedCurabox', curabox);
                }
                else{
                    component.find('cura_box').set('v.value', 'CB1');
                    component.set('v.selectedCurabox', 'CB1');
                }
            }
        });
        $A.enqueueAction(action);
    },

    // get all curaboxes to display
    getCuraboxes: function(component){
        var action = component.get('c.getCuraboxes');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res != null){
                    component.set('v.curabox', res);
                }
            }
            else{
                console.log(state);
            }
        });
        $A.enqueueAction(action);
    },

    getGenehmigungDateLine: function(component, curabox){
        var action = component.get('c.setGenehmigungDateline');
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId,
            "curabox": curabox
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res != null){
                    var bisInput = component.find("bisDatum");
                    var date = $A.localizationService.formatDate(res, "YYYY-MM-DD");
                    component.set('v.lastDeliveryDay', date);
                    bisInput.set('v.max', date);
                }
            }
        });
        $A.enqueueAction(action);
    },

    // get all gloves to display
    getGloves: function(component){
        var action = component.get('c.getGloves');
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

    // fill product table by onChange
    fillTable: function (component, curabox) {
        var saveButton = component.find('btn_save');
        var counter = 0;
        var isGenehmigung = component.get('v.toSendMail');
        var action = component.get("c.getProductList");
        var contactId = component.get('v.recordId');
        action.setParams({
            "curabox": curabox,
            "contactId": contactId,
            "isGenehmigung": isGenehmigung
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var rows = response.getReturnValue();
                var lineList =[];
                for(var i in rows){
                    var line = rows[i];
                    if(line.groupe != 'Einmalhandschuhe'){
                        lineList.push(line);
                    }
                    //
                    if(line.genehmigungstatus == 'Inactiv'){
                        counter = counter + 1;
                    }
                }
                component.set('v.product', lineList);
                // set save button visibility
                if(counter > 0){
                    saveButton.set('v.disabled', true);
                }
                else{
                    saveButton.set('v.disabled', false);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
                component.set('v.errors', errors);
            }
        });
        $A.enqueueAction(action);
    },

    // fill gloves informations and set the visibility for the second glove picklist
    fillGloves: function (component, curabox) {
        var action = component.get("c.getGlovesData");
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId,
            "curabox": curabox
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var rows = response.getReturnValue();
                if(curabox == "CB1"){
                    component.set('v.isZweiEH', false);
                    if(rows.length > 0){
                        component.set('v.selectedGlove', rows[0].name);
                        component.find('glove_1').set('v.value', rows[0].name);
                        component.set('v.gloveQuantity1', 1);
                        component.set('v.glovePrice1', rows[0].price);
                        component.set('v.gloveTotal1', rows[0].price);
                    }
                }
                else if(curabox == "CB5"){
                    component.set('v.isErsteEH', false);
                    component.set('v.isZweiEH', false);
                }
                else{
                    component.set('v.isZweiEH', true);
                    if(rows.length >= 1){
                        component.set('v.selectedGlove', rows[0].name);
                        component.find('glove_1').set('v.value', rows[0].name);
                        component.set('v.glovePrice1', rows[0].price);
                        if(rows[0].menge > 2){
                            component.set('v.gloveQuantity1', 2);
                            component.set('v.gloveTotal1', (rows[0].price*2).toFixed(2));
                        }
                        else{
                            component.set('v.gloveQuantity1', rows[0].menge);
                            component.set('v.gloveTotal1', rows[0].summe);
                        }

                        // set Vinyl M as default value
                        if(rows.length == 1){
                            component.set('v.selectedGlove2', rows[0].name);
                            component.find('glove_2').set('v.value', rows[0].name);
                            component.set('v.gloveQuantity2', 0);
                            component.set('v.glovePrice2', rows[0].price);
                            component.set('v.gloveTotal2', 0);
                        }
                        else if(rows.length > 1){
                            if(rows[0].menge >= 2){
                                component.set('v.selectedGlove2', rows[1].name);
                                component.find('glove_2').set('v.value', rows[1].name);
                                component.set('v.gloveQuantity2', 0);
                                component.set('v.glovePrice2', rows[1].price);
                                component.set('v.gloveTotal2', 0);
                            }
                            else if(rows[0].menge == 1){
                                component.set('v.selectedGlove2', rows[1].name);
                                component.find('glove_2').set('v.value', rows[1].name);
                                component.set('v.gloveQuantity2', 1);
                                component.set('v.glovePrice2', rows[1].price);
                                component.set('v.gloveTotal2', rows[1].price);
                            }
                        }
                    }
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
                component.set('v.errors', errors);
            }
        });
        $A.enqueueAction(action);
    },

    // fill product table by onChange
    fillFlexComponent: function (component, curabox) {
        var saveButton = component.find('btn_save');
        var isGenehmigung = component.get('v.toSendMail');
        saveButton.set('v.disabled', false);
        var action = component.get("c.getProductList");
        var contactId = component.get('v.recordId');
        action.setParams({
            "curabox": curabox,
            "contactId": contactId,
            "isGenehmigung": isGenehmigung
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var rows = response.getReturnValue();
                if(curabox == 'KUWV'){
                    component.set('v.orderLines', rows);
                }
                else{
                    var lineList =[];
                    var gloveList =[];
                    for(var i in rows){
                        var product = rows[i];
                        if(product.groupe != 'Einmalhandschuhe'){
                            lineList.push(product);
                        }
                        else{
                            gloveList.push(product);
                            component.set('v.gloveGenehmigt', product.genehmigteMenge);
                        }
                    }
                    component.set('v.orderLines', lineList);
                    if(gloveList.length >= 1){
                        component.set('v.selectedGlove', gloveList[0].name);
                        component.find('glove_1').set('v.value', gloveList[0].name);
                        component.set('v.gloveQuantity1', gloveList[0].menge);
                        component.set('v.glovePrice1', gloveList[0].price);
                        component.set('v.gloveTotal1', gloveList[0].summe);
                        if(gloveList.length == 1){
                            // set default glove details for CB6
                            component.set('v.selectedGlove2', gloveList[0].name);
                            component.find('glove_2').set('v.value', gloveList[0].name);
                            component.set('v.gloveQuantity2', 0);
                            component.set('v.glovePrice2', gloveList[0].price);
                            component.set('v.gloveTotal2', 0);
                        }
                        if(gloveList.length > 1){
                            component.set('v.selectedGlove2', gloveList[1].name);
                            component.find('glove_2').set('v.value', gloveList[1].name);
                            component.set('v.gloveQuantity2', gloveList[1].menge);
                            component.set('v.glovePrice2', gloveList[1].price);
                            component.set('v.gloveTotal2', gloveList[1].summe);
                        }
                    }
                    else{
                        component.set('v.gloveQuantity1', 0);
                        component.set('v.gloveQuantity2', 0);
                        component.set('v.gloveTotal1', 0);
                        component.set('v.gloveTotal2', 0);
                    }
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
         });
         $A.enqueueAction(action);
    },

    //
    createNewOrder : function(component, liefertag, rythmus, glove1, quantity1, glove2, quantity2){
        var contactId = component.get('v.recordId');
        var paragraph = component.get('v.paragraph');
        var curabox = component.find('cura_box').get('v.value');
        var pList = component.get('v.orderLines');
        var bisdatum = component.get('v.lastDeliveryDay');
        var spruehkopf = component.get('v.spruehkopf');
        var action = component.get("c.insertNewOrder");
        action.setParams({
            "contactId": contactId,
            "liefertag": liefertag,
            "rythmus": rythmus,
            "paragraph": paragraph,
            "curabox": curabox,
            "pList": pList,
            "glove1": glove1,
            "quantity1": quantity1,
            "glove2": glove2,
            "quantity2": quantity2,
            "bisDatum": bisdatum,
            "spruehkopf": spruehkopf
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state == "SUCCESS") {
                var result = response.getReturnValue();
                if(result != "Der Auftrag konnte nicht generiert werden"){
                    console.log('Result Returned by create order: ' +result);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Success Message',
                        message:'Auftrag erfolgreich angelegt',
                        key:'info_alt',
                        type:'Success',
                        mode:'pester'
                    });
                    toastEvent.fire();
                    /*** Not needed in Screen Flow 
                    if(component.get('v.toSendMail') == true){
                        var evt = $A.get("e.force:navigateToComponent");
                        evt.setParams({
                        componentDef:"c:Curabox_Bestaetigung_Email",
                        componentAttributes: {
                            "recordId": contactId,
                        }});
                        evt.fire();
                    }
                    else{
                        var evt = $A.get("e.force:navigateToComponent");
                        evt.setParams({
                        componentDef:"c:Order_Overview",
                        componentAttributes: {
                            "recordId": contactId
                        }});
                        evt.fire();
                    }***/
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Error Message',
                        message:'Der Auftrag konnte nicht angelegt werden.',
                        key:'info_alt',
                        type:'Error',
                        mode:'pester'
                    });
                    toastEvent.fire();
                }
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Error Message',
                    message:'Der Auftrag konnte nicht angelegt werden.',
                    key:'info_alt',
                    type:'Error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    // fill the default delivery date
    setDefaultDate: function (component, curabox) {
        var action = component.get("c.checkDeliveryDate");
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId,
            "curabox": curabox
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var date = $A.localizationService.formatDate(response.getReturnValue(), "YYYY-MM-DD");
                console.log('Result Returned: ' +date);
                component.set('v.deliveryDay', date);
            }
        });
        $A.enqueueAction(action);
    },

    // get the contact
    getContact: function (component) {
        var action = component.get("c.getContact");
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var Con = response.getReturnValue();
                console.log('Result Returned: ' + Con.without_temp_product__c);
                component.set('v.contact', Con);
            }
        });
        $A.enqueueAction(action);     
    },

    // handle glove quantity
    handleGloveQuantity: function(component, quantity, price2){
        var curabox = component.find('cura_box').get('v.value');
        var cmp2 = component.find('glove_quantity2');
        var cmp = component.find('glove_quantity');
        if((curabox == 'CB2') || (curabox == 'CB3') || (curabox == 'CB4')){
            if(quantity > 1){
                component.set('v.gloveQuantity2', 0);
                cmp2.set('v.max', 0);
                component.set('v.gloveTotal2', 0);
                component.set('v.gloveTotal1', 2*((price2).toFixed(2)));
            }
            else if(quantity == 1 ){
                component.set('v.gloveQuantity2', 1);
                cmp2.set('v.max', 1);
                component.set('v.gloveTotal2', (price2).toFixed(2));
                component.set('v.gloveTotal1', (price2).toFixed(2));
            }
            else if(quantity == 0){
                component.set('v.gloveQuantity2', 2);
                cmp2.set('v.max', 2);
                component.set('v.gloveTotal2', 2*((price2).toFixed(2)));
                component.set('v.gloveTotal1', 0);
            }
        }
        else if(curabox == 'CB1'){
            cmp.set('v.max', 1);
        }
        else{
            cmp.set('v.max', 10);
            cmp2.set('v.max', 10);
        }
    },

    // get all curaboxes to display
    getSpruehkopfProduct: function(component){
        var action = component.get('c.getSpruehkopf');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res != null){
                    component.set('v.spruehkopf', res);
                }
            }
            else{
                console.log(state);
            }
        });
        $A.enqueueAction(action);
    },

    calculatePriceForCB6: function(component, curabox){
        var total = 0;
        var action = component.get("c.getProductList");
        var contactId = component.get('v.recordId');
        action.setParams({
            "curabox": curabox,
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var productList = response.getReturnValue();
                for(var row in productList){
                    var product = productList[row];
                    if(product.menge > 0){
                        total = total + (product.menge * product.price);
                    }
                }

                var tempVar = component.get('v.contact').without_temp_product__c ;
                if(tempVar != null){
                  if(tempVar == false) {
                
                    for(var row in productList){
                        var product = productList[row];
                        if(product.isTempProduct == true && product.groupe=='Mundschutz'){
                            total = total+ product.price;
                        }
                    }
                  }
                }
                // set price
                component.set('v.totalPrice', total);
                // set color
                var saveButton = component.find('btn_save');
                var outtext = component.find('totalPriceColor');
                if(total >=0 && total <= 47){
                    $A.util.removeClass(outtext , 'greenPriceColor');
                    $A.util.removeClass(outtext , 'redPriceColor');
                    $A.util.addClass(outtext , 'bluePriceColor');
                    //saveButton.set('v.disabled', false);
                }
                 else if(total > 47 && total <= 62.50){
                    $A.util.removeClass(outtext , 'bluePriceColor');
                    $A.util.removeClass(outtext , 'redPriceColor');
                    $A.util.addClass(outtext , 'greenPriceColor');
                    //saveButton.set('v.disabled', false);
                }
                else if(total>62.50) {
                    $A.util.removeClass(outtext , 'bluePriceColor');
                    $A.util.removeClass(outtext , 'greenPriceColor');
                    $A.util.addClass(outtext , 'redPriceColor');
                    //saveButton.set('v.disabled', true);
                }
              
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
         });
         $A.enqueueAction(action);
    },

    fillFrequency: function(component, curabox){
        var rythmus = [];
        if((curabox == "CB1") || (curabox == "CB2") || (curabox == "CB3") || (curabox == "CB4")||(curabox == "CB5")){
            rythmus.push('einmalig');
            rythmus.push('monatlich');
            rythmus.push('zweimonatlich');
            rythmus.push('dritteljährlich');
            rythmus.push('vierteljährlich');
            rythmus.push('halbjährlich');
            component.set('v.deliveryFrequency', rythmus);
            component.find('frequency').set('v.value', 'monatlich');
            setTimeout(function(){
                component.set('v.selectedRythmus', 'monatlich');
            }, 1000);
        }
        else if(curabox == "KUWV") {
            rythmus.push('einmalig');
            rythmus.push('halbjährlich');
            rythmus.push('jährlich');
            component.set('v.deliveryFrequency', rythmus);
            component.find('frequency').set('v.value', 'einmalig');
            setTimeout(function(){
                component.set('v.selectedRythmus', 'einmalig');
            }, 1000);
        }
        else{
            rythmus.push('einmalig');
            rythmus.push('monatlich');
            rythmus.push('zweimonatlich');
            rythmus.push('dritteljährlich');
            rythmus.push('vierteljährlich');
            rythmus.push('halbjährlich');
            component.set('v.deliveryFrequency', rythmus);
            component.find('frequency').set('v.value', 'monatlich');
            setTimeout(function(){
                component.set('v.selectedRythmus', 'monatlich');
            }, 1000);
        }
    }

})