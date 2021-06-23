({
    init : function(component, event, helper) {
        helper.fillFlexibel(component);
        helper.getGloves(component);
        helper.setGloveDetails(component);
    },

    // calculate price to display
    calculatePrice: function(component, event, helper){
        var productList = component.get('v.orderLines');
        var total = 0;
        var quantity = component.get('v.gloveQuantity1');
        var quantity2 = component.get('v.gloveQuantity2');
        var price = component.get('v.glovePrice1');
        var price2 = component.get('v.glovePrice2');

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
        // set total price
        component.set('v.totalPrice', total);
        // set color and save button disability 
        var saveButton = component.find('btn_save');
        var outtext = component.find('totalPriceColor');
        if(total <= 30){
            $A.util.removeClass(outtext , 'greenPriceColor');
            $A.util.removeClass(outtext , 'redPriceColor');
            $A.util.addClass(outtext , 'bluePriceColor');
            saveButton.set('v.disabled', false);
        }
        else if(total > 30 && total <= 40){
            $A.util.removeClass(outtext , 'bluePriceColor');
            $A.util.removeClass(outtext , 'redPriceColor');
            $A.util.addClass(outtext , 'greenPriceColor');
            saveButton.set('v.disabled', false);
        }
        else if(total > 40 && total <= 150){
            $A.util.removeClass(outtext , 'bluePriceColor');
            $A.util.removeClass(outtext , 'greenPriceColor');
            $A.util.addClass(outtext , 'redPriceColor');
            saveButton.set('v.disabled', false);
        }
        else if(total > 150){
            $A.util.removeClass(outtext , 'bluePriceColor');
            $A.util.removeClass(outtext , 'greenPriceColor');
            $A.util.addClass(outtext , 'redPriceColor');
            saveButton.set('v.disabled', true);
        }
        helper.handleGloveQuantity(component, quantity, price2);
    },

    //
    onChange: function(component, event, helper){
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

    // close window
    cancelClick: function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    },

    saveClick: function(component, event, helper){
        helper.saveWunschbox(component);
    },


})