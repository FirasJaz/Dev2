// 16.09.2019 AM eventListener on 'Enter' deaktiviert
// 17.09.2019 WDS/BT setting der Lieferrythmen anonSavegepasst siehe Comments im Code bei onChangeCurabox
({
    init : function(component, event, helper) {
        helper.getContact(component);
        helper.getCuraboxes(component);
        helper.setCurabox(component);
        helper.getGloves(component);
        
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set('v.today', today);

        // define the order line table
        component.set('v.columns', [
            {label: 'Artikelgruppe', fieldName: 'groupe', type: 'text', editable: false, typeAttributes: { required: true }, cellAttributes: {class: { fieldName: 'genehmigungstatus' }} },
            {label: 'Artikel', fieldName: 'name', type: 'text', editable: false, cellAttributes: { alignment: 'left', class: { fieldName: 'genehmigungstatus' } } },
            {label: 'Einzelpreis', fieldName: 'price', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: false, typeAttributes: { required: true }, cellAttributes: { alignment: 'left', class: { fieldName: 'genehmigungstatus' } } },
            {label: 'Menge', fieldName: 'menge', type: 'number', editable: false, cellAttributes: { alignment: 'left', class: { fieldName: 'genehmigungstatus' } } },
            {label: 'Preis', fieldName: 'summe', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: false, cellAttributes: { alignment: 'left', class: { fieldName: 'genehmigungstatus' } }}
        ]);

        var curabox = component.get('v.wunschbox');
        // set 'Liefertag von' date
        helper.setDefaultDate(component, curabox);
        // set 'bestellt bis' date
        helper.getGenehmigungDateLine(component, curabox);
        if(curabox == "KUWV"){
            component.set('v.isCBFlexibel', true);
            component.set('v.isErsteEH', false);
            component.set('v.isZweiEH', false);
            component.set('v.isSpruehkopf', false);
            component.set('v.isPumpaufsatz', false);
            // set frequency
            helper.fillFrequency(component, curabox);
            // fill curabox
            helper.fillFlexComponent(component, curabox);
            helper.calculatePriceForCB6(component, curabox);
        }
        else{
            component.set('v.isSpruehkopf', true);
            component.set('v.isPumpaufsatz', true);
            helper.getSpruehkopfProduct(component);
            helper.getPumpaufsatzProduct(component);

             // set frequency
            helper.fillFrequency(component, curabox);

            if((curabox == "CB1") || (curabox == "CB2") || (curabox == "CB3") || (curabox == "CB4") || (curabox == "CB5")){
                component.set('v.isCBFlexibel', false);
                helper.fillTable(component, curabox);
                helper.fillGloves(component, curabox);
                if(curabox == "CB1"){
                    var cmp1 = component.find('glove_quantity');
                    cmp1.set('v.max', 1);
                    cmp1.set('v.min', 1);
                }
            }
            else if(curabox == null){
                helper.fillTable(component, 'CB1');
                helper.fillGloves(component, 'CB1');
                var cmp1 = component.find('glove_quantity');
                cmp1.set('v.max', 1);
                cmp1.set('v.min', 1);
            }
            else{
                component.set('v.isCBFlexibel', true);
                helper.fillFlexComponent(component, curabox);
                helper.calculatePriceForCB6(component, curabox);
                //helper.fillGloves(component, curabox);
                var cmp1 = component.find('glove_quantity');
                var cmp2 = component.find('glove_quantity2');
                cmp1.set('v.max', 10);
                cmp2.set('v.max', 10);
            }
        }
        // set keydown function
        window.addEventListener("keydown", function(event) {
            if(event.key =='Enter' || event.code =='Enter'){
                var isorder = component.get('v.ifOrderExists');
                if(isorder == false){
                    // 16.09.2019 AM deaktiviert
                    // $A.enqueueAction(component.get('c.onSave'));
                }
                else if (isorder == true){
                    // 16.09.2019 AM deaktiviert
                    // $A.enqueueAction(component.get('c.onSaveHinweis'));
                }
            }
        }, true);
    },

    // set order exists
    onSave: function(component, event, helper){
        var check = false;
        var aproval = true;
        var StatusPG51 = component.get('v.contact').Status_PG51__c ;
        var StatusPG54 = component.get('v.contact').Status_PG54__c ;
        var curabox = component.find('cura_box').get('v.value');
        var orderLines = component.get('v.orderLines');
        // Save attributes
        var liefertag = component.get('v.deliveryDay');
        var rythmus = component.find('frequency').get('v.value');
        var glove1 = '';
        var quantity1 = 0;
        var glove2 = '';
        var quantity2 = 0;
        if(component.get('v.isErsteEH') == true){
            glove1 = component.find('glove_1').get('v.value');
            quantity1 = component.get('v.gloveQuantity1');
        }
        if(component.get('v.isZweiEH') == true){
            glove2 = component.find('glove_2').get('v.value');
            quantity2 = component.get('v.gloveQuantity2');
        }
        //
        if((curabox == "KUWV" && StatusPG51 =='Kündigung') ||(curabox != "KUWV" && StatusPG54 =='Kündigung')){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title:'Error Message',
                message:$A.get("$Label.c.Prevent_Create_Order_Error"),
                key:'info_alt',
                type:'Error',
                mode:'pester'
            });
            toastEvent.fire();

     }
     else {
        var action = component.get('c.checkMonthCurrentOrder');
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId,
            "lieferdatum":component.get('v.deliveryDay'),
            "curabox": component.find('cura_box').get('v.value')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                component.set('v.ifOrderExists', res);
                if(res == false){
                    if(component.get('v.isCBFlexibel') == true){
                        for(var i in orderLines){
                            var line = orderLines[i];
                            if(line.menge > 0){
                                check = true;
                                if(line.menge > line.genehmigteMenge){
                                    aproval = false; 
                                }
                            }
                        }
                        var gloveQuantity = parseInt(quantity1) + parseInt(quantity2);
                        if((check == true) || (quantity1 > 0) || (quantity2 > 0)){
                            if(aproval == false){
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    title:'Error Message',
                                    message:'Keine ausreichende genehmigte Menge vorhanden. Bitte Positionen prüfen!',
                                    key:'info_alt',
                                    type:'Error',
                                    mode:'pester'
                                });
                                toastEvent.fire();
                            }
                            else if( gloveQuantity > component.get('v.gloveGenehmigt')){
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    title:'Error Message',
                                    message:'Keine ausreichende genehmigte Menge vorhanden. Bitte Positionen prüfen!',
                                    key:'info_alt',
                                    type:'Error',
                                    mode:'pester'
                                });
                                toastEvent.fire();
                            }
                            else{
                               helper.createNewOrder(component, liefertag, rythmus, glove1, quantity1, glove2, quantity2);
                            }
                        }
                        else{
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                title:'Error Message',
                                message:'Es kann keinen leeren Auftrag erstellt werden.',
                                key:'info_alt',
                                type:'Error',
                                mode:'pester'
                            });
                            toastEvent.fire();
                        }
                    }
                    else{
                        helper.createNewOrder(component, liefertag, rythmus, glove1, quantity1, glove2, quantity2);
                    }
                }
            }
        });
        $A.enqueueAction(action);  
     }
    },
    
    onSaveHinweis: function(component, event, helper){
        var check = false;
        var aproval = true;
        var orderLines = component.get('v.orderLines');
        //
        var liefertag = component.get('v.deliveryDay');
        var rythmus = component.find('frequency').get('v.value');
        var glove1 = '';
        var quantity1 = 0;
        var glove2 = '';
        var quantity2 = 0;
        if(component.get('v.isErsteEH') == true){
            glove1 = component.find('glove_1').get('v.value');
            quantity1 = component.get('v.gloveQuantity1');
        }
        if(component.get('v.isZweiEH') == true){
            glove2 = component.find('glove_2').get('v.value');
            quantity2 = component.get('v.gloveQuantity2');
        }

        // check before insert
        

         if(component.get('v.isCBFlexibel') == true){
            for(var i in orderLines){
                var line = orderLines[i];
                if(line.menge > 0){
                    check = true;
                    if(line.menge > line.genehmigteMenge){
                        aproval = false; 
                    }
                }
            }
            var gloveQuantity = parseInt(quantity1) + parseInt(quantity2);
            if((check == true) || (quantity1 > 0) || (quantity2 > 0)){
                 if(aproval == false){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Error Message',
                        message:'Keine ausreichende genehmigte Menge vorhanden. Bitte Positionen prüfen!',
                        key:'info_alt',
                        type:'Error',
                        mode:'pester'
                    });
                    toastEvent.fire();
                }
                else if( gloveQuantity > component.get('v.gloveGenehmigt')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Error Message',
                        message:'Keine ausreichende genehmigte Menge vorhanden. Bitte Positionen prüfen!',
                        key:'info_alt',
                        type:'Error',
                        mode:'pester'
                    });
                    toastEvent.fire();
                }
                else{
                    helper.createNewOrder(component, liefertag, rythmus, glove1, quantity1, glove2, quantity2);
                }
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Error Message',
                    message:'Es kann keinen leeren Auftrag erstellt werden.',
                    key:'info_alt',
                    type:'Error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
        }
        else{
            helper.createNewOrder(component, liefertag, rythmus, glove1, quantity1, glove2, quantity2);
        }
    },

    onChangeCurabox: function(component, event, helper){
        component.set('v.totalPrice', 0);
        var curabox = component.find('cura_box').get('v.value');
        // set 'Liefertag von' date
        helper.setDefaultDate(component, curabox);
        // set 'Bestellt bis'
        helper.getGenehmigungDateLine(component, curabox);
        // fill frequency
        helper.fillFrequency(component, curabox);
        if((curabox == "CB1") || (curabox == "CB2") || (curabox == "CB3") || (curabox == "CB4")){
            component.set('v.isCBFlexibel', false);
            component.set('v.isErsteEH', true);
            component.set('v.isSpruehkopf', true);
            component.set('v.isPumpaufsatz', true);
            
            
            helper.fillTable(component, curabox);
            helper.fillGloves(component, curabox);
            helper.getSpruehkopfProduct(component);
            helper.getPumpaufsatzProduct(component);

            var cmp1 = component.find('glove_quantity');
            if(curabox == "CB1"){
                cmp1.set('v.max', 1);
                cmp1.set('v.min', 1);
            }
            else{
                cmp1.set('v.max', 2);
            }
        }
        else if(curabox == "CB5"){
            component.set('v.isCBFlexibel', false);
            component.set('v.isErsteEH', false);
            component.set('v.isZweiEH', false);
            component.set('v.isSpruehkopf', true);
            component.set('v.isPumpaufsatz', true);
            
            helper.fillTable(component, curabox);
            helper.getSpruehkopfProduct(component);
            helper.getPumpaufsatzProduct(component);
        }
        else if(curabox == "KUWV") {
            component.set('v.isCBFlexibel', true);
            component.set('v.isErsteEH', false);
            component.set('v.isZweiEH', false);
            component.set('v.isSpruehkopf', false);
            component.set('v.isPumpaufsatz', false);
            helper.fillFlexComponent(component, curabox);
            helper.calculatePriceForCB6(component, curabox);
        }
        else{
            component.set('v.isCBFlexibel', true);
            component.set('v.isErsteEH', true);
            component.set('v.isZweiEH', true);
            component.set('v.isSpruehkopf', true);
            component.set('v.isPumpaufsatz', true);
           
            helper.fillFlexComponent(component, curabox);
            helper.calculatePriceForCB6(component, curabox);
            helper.getSpruehkopfProduct(component);
            helper.getPumpaufsatzProduct(component);
            var cmp1 = component.find('glove_quantity');
            var cmp2 = component.find('glove_quantity2');
            cmp1.set('v.max', 10);
            cmp2.set('v.max', 10);
        }                
    },

    // calculate price to display
    calculatePrice: function(component, event, helper){
        var curabox = component.find('cura_box').get('v.value');
        var productList = component.get('v.orderLines');
        var total = 0;
        if (curabox != 'KUWV'){
            var quantity = component.get('v.gloveQuantity1');
            var quantity2 = component.get('v.gloveQuantity2');
            var price = component.get('v.glovePrice1');
            var price2 = component.get('v.glovePrice2');
        }
        //
        if((curabox != "CB1") && (curabox != "CB2") && (curabox != "CB3") && (curabox != "CB4") && (curabox != "CB5")){ 
            for(var row in productList){
                var product = productList[row];
                if(product.menge > 0){
                    total = total + (product.menge * product.price);
                    product.summe = (product.menge * product.price).toFixed(2);
                }
                else{
                    product.summe = 0;
                }
            }
            component.set('v.orderLines', productList);

            if (curabox != 'KUWV'){
                if(quantity > 0){
                    var glovetotal1 = quantity*price;
                    component.set('v.gloveTotal1', (quantity*price).toFixed(2));
                    total = total + glovetotal1;
                }
                else{
                    component.set('v.gloveTotal1', 0);
                }

                if(quantity2 > 0){
                    var glovetotal2 = quantity2*price2;
                    component.set('v.gloveTotal2', (quantity2*price2).toFixed(2));
                    total = total + glovetotal2;
                }
                else{
                    component.set('v.gloveTotal2', 0); 
                }
            }
            // set total price
            var tempVar = component.get('v.contact').without_temp_product__c ;
            if(tempVar != null){
              if(tempVar == false) {
                var productList = component.get('v.orderLines');
                console.table(productList);
                for(var row in productList){
                    var product = productList[row];
                    if(product.isTempProduct == true && product.groupe=='Mundschutz'){
                        total = total+ product.price;
                    }
                }
              }
            }
            component.set('v.totalPrice', total);
            // set color and save button disability 
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
            else if(total > 62.50){
                $A.util.removeClass(outtext , 'bluePriceColor');
                $A.util.removeClass(outtext , 'greenPriceColor');
                $A.util.addClass(outtext , 'redPriceColor');
                //saveButton.set('v.disabled', true);
            }
        }
        if (curabox != 'KUWV'){
            helper.handleGloveQuantity(component, quantity, price2);
        }
    },

    //
    onChangeGlove1: function(component, event, helper){
        var gloveList = component.get('v.gloves');
        var selected = component.find('glove_1').get('v.value');
        for(var row in gloveList){
            var glove = gloveList[row];
            if(glove.Name == selected){
                component.set('v.glovePrice1', glove.Price__c);
            }
            else if(selected == ''){
                component.set('v.glovePrice1', 0);
            }
        }
    },

    onChangeGlove2: function(component, event, helper){
        var gloveList = component.get('v.gloves');
        var selected = component.find('glove_2').get('v.value');
        for(var row in gloveList){
            var glove = gloveList[row];
            if(glove.Name == selected){
                component.set('v.glovePrice2', glove.Price__c);
            }
            else if(selected == ''){
                component.set('v.glovePrice2', 0);
            }
        }
    },

    closeModel: function(component, event, helper) { 
        component.set("v.ifOrderExists", false);
    },

})