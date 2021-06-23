({
    init: function(component, event, helper){
        helper.setDefaultBox(component);
        helper.setContactRole(component);
        helper.setIsCooperativ(component);
        helper.getGenehmigungIdPG51(component);
        helper.getGenehmigungIdPG54(component);
        helper.isTerminated(component);
    },

    handleChange: function (cmp, event) {
        var selectedOptionValue = event.getParam("value");
        var textField = cmp.find('anderer_art');
        if (selectedOptionValue == "frei") {
            textField.set('v.disabled', false);
        }
        else {
            textField.set('v.disabled', true);
        }
        let pg54 = cmp.get('v.isTerminated54')
        let pg51 = cmp.get('v.isTerminated51')
        let valArt = cmp.find('form_art').get("v.value")
        let valCode = cmp.find('form_code').get("v.value")
        // Status Kunde auf Kündigung PG54 - Antrag_2 PG54 kann man nicht hochladen
        if (pg54 && pg51) {
            if (valArt ==  "Antrag" && valCode == "5X") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Hinweis',
                    message: "PG54 & PG51 Kontaktstatus steht auf 'Kündigung'. Upload deaktiviert. Bitte überprüfe den Kontaktstatus.",
                    type:'warning',
                    mode:'pester',
                    duration: 15000 // 15 sek
                });
                toastEvent.fire();
                cmp.set('v.disableUpload', true)
                return

            }
        }
        if (pg54) {
            if (valArt ==  "Antrag" && valCode == "54") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Hinweis',
                    message: "PG54 Kontaktstatus steht auf 'Kündigung'. Upload deaktiviert. Bitte überprüfe den Kontaktstatus.",
                    type:'warning',
                    mode:'pester',
                    duration: 15000 // 15 sek
                });
                toastEvent.fire();

                cmp.set('v.disableUpload', true)
                return

            }
        }
        if (pg51) {
            if (valArt ==  "Antrag" && valCode == "51") {
                // Status Kunde auf Kündigung PG51 - Antrag_2 PG51 kann man nicht hochladen
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Hinweis',
                    message: "PG51 Kontaktstatus steht auf 'Kündigung'. Upload deaktiviert. Bitte überprüfe den Kontaktstatus.",
                    type:'warning',
                    mode:'pester',
                    duration: 15000 // 15 sek
                });
                toastEvent.fire();
                cmp.set('v.disableUpload', true)
                return
            }
        }
        cmp.set('v.disableUpload', false)


    },
    fireToast: function (text) {

    },
	//   
    UploadFinished : function(component, event, helper) {  
        var uploadedFiles = event.getParam("files"); 
        // wird eventuell für xml benötigt 
        var documentId = uploadedFiles[0].documentId;
        var curabox = component.get("v.curabox"); 
        helper.UpdateDocument(component,event,documentId);
        var isCooperativ = component.get('v.isCooperativ');
        var role = component.get('v.role');
          
        var contactId = component.get("v.recordId");
        var paragraph = component.find("form_code").get("v.value");
        var document = component.find("form_art").get("v.value");
        if(document == "Antrag"){
            if(role != null && role == 'ASP'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Message',
                    message:'Dieser Kontakt ist kein Pflegebedürftiger, sondern ein Ansprechpartner. Bitte löschen Sie das hochgeladene Dokument. Dies ist unter Note & Attachment zu finden',
                    key:'info_alt',
                    type:'Error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
            else{
                helper.createGenehmigung(component, documentId);
                if(isCooperativ == true){
                    var evt = $A.get("e.force:navigateToComponent");
                    evt.setParams({
                    componentDef:"c:Manage_Order",
                    componentAttributes: {
                        "recordId": contactId,
                        "paragraph": paragraph,
                        "curabox": curabox,
                        "toSendMail": true
                    }});
                    evt.fire();
                }
                else{
                    var evt = $A.get("e.force:navigateToComponent");
                    evt.setParams({
                    componentDef:"c:Curabox_Bestaetigung_Email",
                    componentAttributes: {
                        "recordId": contactId
                    }});
                    evt.fire();
                }
            }
        }
        else if(document == "Genehmigung"){
            if(role != null && role == 'ASP'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title:'Message',
                    message:'Dieser Kontakt ist kein Pflegebedürftiger, sondern ein Ansprechpartner. Bitte löschen Sie das hochgeladene Dokument. Dies ist unter Note & Attachment zu finden',
                    key:'info_alt',
                    type:'Error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
            else{
                if((paragraph == '54') || (paragraph == '5X')){
                    var genId = component.get('v.aprovalId54');
                    if(genId != null){
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                        "recordId": genId,
                        "slideDevName": "related"
                        });
                        navEvt.fire();
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title:'Error Message',
                            message:'Es wurde keine Genehmigung für PG54 gefunden',
                            key:'info_alt',
                            type:'Error',
                            mode:'pester'
                        });
                        toastEvent.fire(); 
                    }
                }
                else if(paragraph == '51'){
                    var genId = component.get('v.aprovalId51');
                    if(genId != null){
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                        "recordId": genId,
                        "slideDevName": "related"
                        });
                        navEvt.fire();
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title:'Error Message',
                            message:'Es wurde keine Genehmigung für PG51 gefunden',
                            key:'info_alt',
                            type:'Error',
                            mode:'pester'
                        });
                        toastEvent.fire(); 
                    }
                }
                else{}
            }
        }
        else {
            // andere document
        }

        // close the window
        $A.get("e.force:closeQuickAction").fire() 
    },
        
})