({
    doInit: function(component, event, helper) {
        helper.getDefaultReceiver(component);
        helper.setButtonVisibility(component);
        helper.getFile(component);
    },
    
    onChange: function (component, event, helper) {
        helper.setReceiverEmail(component);
        helper.getReceiverId(component);
    },
   
    sendMail: function (component, event, helper){
        var msg = component.get('v.blankoPostMsg');
        if(msg == 'Anschreiben für PG54 und PG51 ausdrucken'){
            helper.sendAntrag(component);
        }
        else if(msg == 'Eingangsbestätigung ausdrucken') {
            helper.sendBestaetigung(component);
        }
    },

    sendFilledMail: function (component, event, helper){
        var msg = component.get('v.blankoPostMsg');
        if(msg == 'Anschreiben für PG54 und PG51 ausdrucken'){
            helper.sendFilledAntrag(component);
        }
    },

    ausPost: function(component, event, helper){
        component.set('v.hasModalOpen', true);
       //var url = '/lightning/r/ContentDocument/' + component.get("v.selectedDocumentId") + '/view';  
       //window.open(url, "_blank");
    },

    blankoPost: function(component, event, helper){
        var msg = component.get('v.blankoPostMsg');
        var receiver = component.get('v.receiverId');
        var recordId = component.get('v.recordId');
        
        if(receiver == 'None'){
            receiver = component.get('v.recordId');
        }
        else{
            receiver = receiver;
        }
        if(msg == 'Anschreiben für PG54 und PG51 ausdrucken'){
            var mainPageName = 'Anschreiben_Formular_Neu';
            var pdfFormPageName = 'PdfFormPage';
            var url2 = '/apex/' + pdfFormPageName + '?id=' + receiver;   
            window.open(url2, "_blank");   
            var url = '/apex/' + mainPageName + '?id=' + receiver + '&rcpt=' + receiver;   
            window.open(url, "_blank");
        }
        else if(msg == 'Eingangsbestätigung ausdrucken') {
            var mainPageName = 'Curabox_Empfangsschreiben';
            // 10.10.2019 BT  recordId as page parameter	
            var url = '/apex/' + mainPageName + '?id=' + receiver + '&rcpt=' + receiver + '&recordId=' + recordId;   
            window.open(url, "_blank");
        }
    },

    closeModel: function(component, event, helper) {
        // for Close Model, set the "hasModalOpen" attribute to "FALSE"  
        component.set("v.hasModalOpen", false);
    },

})