({
    doInit : function(component, event, helper) {
        component.set("v.disableCustomEmail", false);
        component.set("v.emailSubject", "");
        component.set("v.emailBody", "");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        component.set("v.userId", userId);
        
        var oppId = component.get("v.recordId");
        
        var action = component.get("c.getTemplates"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.templateList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        
        var action2 = component.get("c.getContacts");
        action2.setParams({
            "oppId":oppId,
            "templateId":""
        });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.contactList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action2);
        
        var action3 = component.get("c.removeAttachments");
        $A.enqueueAction(action3);
	},
    
    onTemplateChange: function (component, event, helper) {
        var selectedTemplate = component.get("v.selectedTemplate");
        if(selectedTemplate != "--keine--"){
            component.set("v.disableCustomEmail", true);
            
            var action = component.get("c.getTemplateBody");
            action.setParams({
                "templateId":selectedTemplate
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (component.isValid() && state == "SUCCESS"){
                    var t = response.getReturnValue();
                    component.set("v.emailSubject", t.Subject);
            		component.set("v.emailBody", t.HtmlValue);
                }
            });
            $A.enqueueAction(action);

        }else{
            component.set("v.disableCustomEmail", false);
            component.set("v.emailSubject", "");
            component.set("v.emailBody", "");
        }
	},
    
    sendEmail: function (component, event, helper) {
        var action = component.get("c.sendEmailToContact"); 
        
        var oppId = component.get("v.recordId");
        var selectedTemplate = component.get("v.selectedTemplate");
        var selectedContact = component.get("v.selectedContact");
        var emailSubject = component.get("v.emailSubject");
        var emailBody = component.get("v.emailBody");
        var selectedAttachmentList = component.get("v.selectedAttachmentList");
        
        action.setParams({
            "oppId":oppId,
            "emailSubject":emailSubject,
            "emailBody":emailBody,
            "templateId":selectedTemplate,
            "contactId":selectedContact,
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
        var action = component.get("c.doInit");
        $A.enqueueAction(action);
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
        var oppId = component.get("v.recordId");
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
    }
    
})