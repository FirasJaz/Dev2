({
    init : function(component, event, helper) {
        // define the order table
        component.set('v.columns', [
            {label: 'Name', fieldName: 'linkName', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank', required: true}},
            {label: 'Curabox', fieldName: 'Description__c', type: 'text', editable: false, typeAttributes: { required: true}},
            {label: 'Positionen', type: 'button', initialWidth: 135, typeAttributes: { label: 'Detailansicht', name: 'view_details', title: 'Klicken Sie hier, um die Auftragspositionen anzuzeigen.'}},
            {label: 'Status', fieldName: 'Status__c', type: 'text', editable: false },
            {label: 'Lieferrhythmus', fieldName: 'Delivery_frequency__c', type: 'text', typeAttributes: { currencyCode: 'EUR'}, editable: false },
            {label: 'Genehmigt von', fieldName: 'Genehmigt_von__c', type: 'date', editable: false },
            {label: 'Genehmigt bis', fieldName: 'Genehmigt_bis__c', type: 'date', editable: false },
            {label: 'Unbefristet', fieldName: 'Unbefristet_genehmigt__c', type: 'boolean', editable: false },
            {type: 'button', typeAttributes: {label: { fieldName: 'Pausieren__c'}, title: 'Pausieren', variant: 'Success', name: 'pausieren_action', alternativeText: 'Pausieren', disabled:{fieldName: 'pausingDisabled__c'}}},
            {type: 'button', typeAttributes: {label: 'Beenden', title: 'Beenden', variant: 'Destructive', name: 'beenden_action', alternativeText: 'beenden', disabled:{fieldName: 'terminateDisabled__c'}}}
        ]);
        helper.fillOrderTable(component);
        helper.setDefaultBox(component);
    },

    //
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'pausieren_action':
                helper.pausingOrder(component, row);
                break;
            case 'beenden_action':
                helper.terminateSelectedOrder(component, row);
                break;
            case 'view_details':
                component.set('v.showLines', true);
                helper.createTabelLines(component);
                helper.setOrderLines(component, row);
                break;
            default:
                break;
        }
    },

    closeModel: function(component, event, helper) {
        component.set("v.isOpen", false);
    },

    closeLines: function(component, event, helper) {
        component.set("v.showLines", false);
    },

    closeExists: function(component, event, helper) {
        component.set("v.ifOrderExists", false);
    },

    save: function(component, event, helper){
        var contactId = component.get('v.recordId');
        var date = component.get('v.lieferdatum');
        var curabox = component.get('v.curabox');
        var action = component.get('c.checkMonthCurrentOrder');
        action.setParams({
            "contactId": contactId,
            "lieferdatum": date,
            "curabox": curabox
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res == false){
                    helper.onSave(component);
                    helper.fillOrderTable(component);
                }
                else if (res == true){
                    component.set('v.ifOrderExists', true);
                }
            }
            else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Message',
                    message:'Fehler bei der Aktivierung des Auftrags',
                    key:'info_alt',
                    type:'Error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    onSaveHinweis: function(component, event, helper) {
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
                    // update table
                    helper.fillOrderTable(component);
                    component.set('v.ifOrderExists', false);
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