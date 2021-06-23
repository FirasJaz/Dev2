({
    doInit : function(component, event, helper) {
        
        component.set("v.emailSubject", "");
        component.set("v.emailBody", "");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        component.set("v.userId", userId);
        var oppId = component.get("v.relatedToId");
        
        var messageId = component.get("v.messageId");
        var actionType = component.get("v.actionType");
                
        var action = component.get("c.getOriginalEmail");
        action.setParams({
            "messageId":messageId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                var returnValue = response.getReturnValue();
                if( returnValue == null){
                	component.set("v.errorMessage", 'Could not find original email!');
                    component.set("v.emailSubject", "");
                    component.set("v.emailBody", "");
                    component.set("v.emailReceiver", "");
                }else{
                    var historyText = "<br/>";
                    if(actionType == "forward"){
                        component.set("v.emailSubject", "WG: " + returnValue.Subject);
                        historyText = "<br/>--------------- Weitergeleitete Nachricht ---------------";
                        historyText = historyText + "<br/>Von: "+ returnValue.FromAddress +"";
                        historyText = historyText + "<br/>Datum: "+ $A.localizationService.formatDate(returnValue.MessageDate, "MMMM DD YYYY, hh:mm:ss a");
                        historyText = historyText + "<br/>Thema: "+ returnValue.Subject + "<br/>";
                    }else{
                        component.set("v.emailSubject", "Betr.: " + returnValue.Subject);
                    	historyText =  "<br/>Am "+ $A.localizationService.formatDate(returnValue.MessageDate, "MMMM DD YYYY, hh:mm:ss a") + " schrieb " + returnValue.FromAddress + ":<br/>";
                        component.set("v.receiverEmailAddress", returnValue.FromAddress);
                    }
                    
                    // put original email body in the new email
                    if(returnValue.HtmlBody == null){
                    	component.set("v.emailBody", historyText + returnValue.TextBody);
                    }else{
                        component.set("v.emailBody", historyText + returnValue.HtmlBody);
                    }
                    
                    component.set("v.relatedToId", returnValue.RelatedToId);
                    oppId = returnValue.RelatedToId;
                }
            }
        });
        $A.enqueueAction(action);
        
        // if action is reply then fill receiver contact. if forward, then get all contacts with no default
        if(actionType == "forward"){
            $A.enqueueAction(component.get("c.fillContactList"));
        }else{
            $A.enqueueAction(component.get("c.setDefaultReceiverContact"));
        }
        
	},
    
    // get List Of all contacts to forward the email to
    fillContactList: function (component, event, helper) {
        var messageId = component.get("v.messageId");
        var contactOptions = [];
            
        var action2 = component.get("c.getContacts");
        action2.setParams({
            "messageId":messageId
        });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                var contactList = response.getReturnValue();
                for (var i = 0; i < contactList.length; i++) {
                    contactOptions.push({
                        'label': contactList[i].Name + ' [' +contactList[i].Email + ']',
                        'value': contactList[i].Id,
                        'selected':false
                    });
                }
                component.set("v.contactList", contactOptions);
            }
        });
        $A.enqueueAction(action2);
        
    },
    
    // set default receiver based on the sender of original email
    setDefaultReceiverContact: function (component, event, helper) {
        var messageId = component.get("v.messageId");
        var contactOptions = [];
        
        var senderContactId = "";
        var actionGetContactId = component.get("c.getReplyToContactId");
        actionGetContactId.setParams({
            "messageId":messageId
        });
        actionGetContactId.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                senderContactId = response.getReturnValue();
            }
        });
        $A.enqueueAction(actionGetContactId);
                
        var action2 = component.get("c.getContacts");
        action2.setParams({
            "messageId":messageId
        });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                var contactList = response.getReturnValue();
                for (var i = 0; i < contactList.length; i++) {
                    var selected = false;
                    if(senderContactId == contactList[i].Id){
                        selected = true;
                        component.set("v.receiverEmailAddress", "");
                        component.set("v.selectedContact", senderContactId);
                    }
                    contactOptions.push({
                        'label': contactList[i].Name + ' [' +contactList[i].Email + ']',
                        'value': contactList[i].Id,
                        'selected':selected
                    });
                }
                component.set("v.contactList", contactOptions);
            }
        });
        $A.enqueueAction(action2);
        
    },
    
    sendEmail: function (component, event, helper) {
        var action = component.get("c.sendEmailAction"); 
        
        var oppId = component.get("v.relatedToId");
        //var selectedTemplate = component.get("v.selectedTemplate");
        var selectedContact = component.get("v.selectedContact");
        var emailSubject = component.get("v.emailSubject");
        var emailBody = component.get("v.emailBody");
        var selectedAttachmentList = component.get("v.selectedAttachmentList");
        var receiverEmailAddress = component.get("v.receiverEmailAddress");
        alert(selectedContact);
        action.setParams({
            "oppId":oppId,
            "emailSubject":emailSubject,
            "emailBody":emailBody,
            //"templateId":selectedTemplate,
            "contactId":selectedContact,
            "receiverEmailAddress":receiverEmailAddress,
            "documnetIds":selectedAttachmentList
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                var return_value = response.getReturnValue();
                if( return_value == null){
                    component.set("v.errorMessage", 'Unknown error in sending email occured!');
                }
                else if( return_value.search("Error") != -1 ){
                    component.set("v.errorMessage", return_value);
                }
                else{
                    component.set("v.errorMessage", 'None');
                    component.set("v.modalDialogLayout", 'True');
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    closeModalDialog : function(component, event, helper) {
        component.set("v.modalDialogLayout", "false");
        var action = component.get("c.redirectToOpportunity");
        $A.enqueueAction(action);
	},
    
    redirectToOpportunity : function(component, event, helper) {
        var oppId = component.get("v.relatedToId");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": oppId,
            "slideDevName": "related"
        });
        navEvt.fire();
    },
    
    closeAttachmentDialog : function(component, event, helper) {
        component.set("v.attachmentDialogLayout", "false");
	},
    
    closeUploadDialog : function(component, event, helper) {
        component.set("v.uploadDialogLayout", "false");
	},
    
    addSelectedAttachment : function(component, event, helper) {
        var action = component.get("c.addToSelectedList");
        var selectedAttachment = component.get("v.selectedAttachment");
        var selectedAttachmentList = component.get("v.selectedAttachmentList");
        action.setParams({
            "selectedAttachment":selectedAttachment,
            "selectedAttachmentList":selectedAttachmentList
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.attachmentDialogLayout", "false");
                component.set("v.selectedAttachmentList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	},
    
    openAttachmentDialog : function(component, event, helper) {
    	var action = component.get("c.getAllAttachments");
        var oppId = component.get("v.relatedToId");
        action.setParams({
            "oppId":oppId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.attachmentList", response.getReturnValue());
                component.set("v.attachmentDialogLayout", 'True');
            }
        });
        $A.enqueueAction(action);
	},
    
    openUploadDialog : function(component, event, helper) {
    	component.set("v.uploadDialogLayout", 'True');
	},
    
    removeAttachments: function(component, event, helper) {
        var action = component.get("c.getNewAttachmentsList"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.selectedAttachmentList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	},
    
    handleUploadFinished: function(component, event, helper) {
        // This will contain the List of File uploaded data and status
        var uploadedFiles = event.getParam("files");
        //alert(Object.keys(uploadedFiles[0]));name,documentId
        var action = component.get("c.addToSelectedList");
        var selectedAttachment = uploadedFiles[0].documentId;
        var selectedAttachmentList = component.get("v.selectedAttachmentList");
        action.setParams({
            "selectedAttachment":selectedAttachment,
            "selectedAttachmentList":selectedAttachmentList
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.uploadDialogLayout", "false");
                component.set("v.selectedAttachmentList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    
    setReceiverEmailAddress: function(component, event, helper) {
        var selectedContact = component.get("v.selectedContact");
        if(selectedContact != "" && selectedContact != "--keine--"){
            component.set("v.receiverEmailAddress", "");
            component.set("v.disableReceiverEmailAddress", true);
        }else{
            component.set("v.disableReceiverEmailAddress", false);
        }
    }
    
})