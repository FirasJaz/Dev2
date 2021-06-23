({
    // fill orders table for a contact
    fillOrderTable: function (component) {
        var action = component.get("c.getOrders");
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var rows = response.getReturnValue();
                var data = [];
                for(var i in rows){
                    var row = rows[i];
                    if(row.Status__c == 'beendet'){
                        row.pausingDisabled__c = true;
                        row.terminateDisabled__c = true;
                    }
                    data.push(row);
                }
                data.forEach(function(record){
                    record.linkName = '/'+record.Id;
                });
                component.set('v.order', data);
            }
            else if (state == "ERROR") {
                var errors = response.getError();
                console.error(errors);
                component.set('v.errors', errors);
            }
        });
        $A.enqueueAction(action);
    },

    // get order lines to display
    setOrderLines: function (component, row) {
        var action = component.get("c.getOrderLines");
        action.setParams({
            "orderId": row.Id
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var lines = response.getReturnValue();
                for(var i in lines){
                    var position = lines[i];
                    if(position.Product__c) position.productName = position.Product__r.Name;
                    if(position.Product__c) position.price = position.Product__r.Price__c;
                }
                component.set('v.line', lines);
            }
            else if (state == "ERROR") {

            }
        });
        $A.enqueueAction(action);
    },

    setDefaultBox: function(component){
        var action = component.get("c.getWunschCB");
        var contactId = component.get('v.recordId');
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var curabox = response.getReturnValue();
                component.set('v.curabox', curabox);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    },

    terminateSelectedOrder: function(component, row){
        var action = component.get("c.terminateOrder");
        action.setParams({
            "order": row
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res != null){
                    console.error(res);
                }
            }
            else if (state == "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
        // update view
        var data = component.get('v.order');
        data = data.map(function(rowData) {
            if (rowData.Name == row.Name) {
                if(rowData.Status__c == 'beendet'){
                    rowData.pausingDisabled__c = true;
                    rowData.terminateDisabled__c = true;
                }
                else{
                    rowData.Status__c = 'beendet';
                    rowData.pausingDisabled__c = true;
                    rowData.terminateDisabled__c = true;
                }
            }
            return rowData;
        });
        component.set("v.order", data);
    },

    pausingOrder: function(component ,row){
        var data = component.get('v.order');
        data = data.map(function(rowData) {
            if (rowData.Name == row.Name) {
                switch(row.Pausieren__c) {
                    case 'Pausieren':
                        rowData.Status__c = 'pausiert';
                        rowData.Pausieren__c ='Aktivieren';
                        var action = component.get("c.pausingOrder");
                        action.setParams({
                            "order": row
                        });
                        action.setCallback(this, function(response) {
                            var state = response.getState();
                            if (state == "SUCCESS") {
                                var res = response.getReturnValue();
                                if(res != null){
                                    console.error(res);
                                }
                            }
                            else if (state == "ERROR") {
                                var errors = response.getError();
                                console.error(errors);
                            }
                        });
                        $A.enqueueAction(action);
                        break;
                    case 'Aktivieren':
                        component.set("v.isOpen", true);
                        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
                        component.set('v.lieferdatum', today);
                        component.set('v.minDate', today);
                        component.set('v.rowToPausing', row);
                        rowData.Status__c = 'aktiv';
                        rowData.Pausieren__c ='Pausieren';
                        break;
                    default:
                        break;
                }
            }
            return rowData;
        });
        component.set("v.order", data);
    },

    createTabelLines: function(component){
        component.set('v.positions', [
            {label: 'Artikel', fieldName: 'productName', type: 'text', initialWidth: 500, editable: false },
            {label: 'Einzelpreis', fieldName: 'price', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: false, cellAttributes: { alignment: 'left' } },
            {label: 'Menge', fieldName: 'Gen_Menge_Stk_Mon__c', type: 'number', editable: false, cellAttributes: { alignment: 'left' } },
            {label: 'Preis', fieldName: 'Price__c', type: 'currency', typeAttributes: { currencyCode: 'EUR'}, editable: false, cellAttributes: { alignment: 'left' } },
        ]);
    },

    onSave: function(component) {
        var row = component.get('v.rowToPausing');
        var date = component.get('v.lieferdatum');
        var action = component.get("c.activateOrder");
        action.setParams({
            "order": row,
            "datum": date
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var errors = response.getError();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res != 'OK'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Message',
                        message:'Fehler bei der Aktivierung des Auftrags.',
                        key:'info_alt',
                        type:'Error',
                        mode:'pester'
                    });
                    toastEvent.fire();
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Success Message',
                        message:'Auftrag erfolgreich aktiviert.',
                        key:'info_alt',
                        type:'Success',
                        mode:'pester'
                    });
                    toastEvent.fire();
                    component.set("v.isOpen", false);
                }
            }
            else if (state == "ERROR") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Message',
                    message:'Fehler bei der Aktivierung des Auftrags.',
                    key:'info_alt',
                    type:'Error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

})