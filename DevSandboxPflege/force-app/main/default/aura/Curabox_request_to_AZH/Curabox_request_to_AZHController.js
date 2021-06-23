({
    onSend : function(component, event, helper) {
        var recordId = component.get('v.recordId');
        var action = component.get("c.sentToAZH");
        action.setParams({
            "genehmigungId": recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                if(res != null){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Message',
                        message:'Genehmigung an AZH erfolgreich übertragen!',
                        key:'info_alt',
                        type:'Success',
                        mode:'pester'
                    });
                    toastEvent.fire();
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Message',
                        message:' Fehler bei der Übertragung der Genehmigung an AZH',
                        key:'info_alt',
                        type:'Error',
                        mode:'pester'
                    });
                    toastEvent.fire();
                }
            }
            else if (state == "ERROR") {
                var errors = response.getError();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Message',
                    message:' Fehler bei der Übertragung der Genehmigung an AZH'+ errors,
                    key:'info_alt',
                    type:'Error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
        setTimeout(function(){
            $A.get("e.force:closeQuickAction").fire(); 
        }, 1000);
    }
})