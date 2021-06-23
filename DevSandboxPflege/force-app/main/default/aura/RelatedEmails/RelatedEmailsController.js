({
    // pulls emails from apex-controller
    // sets attributes
    doInit: function(component, event, helper) {
        var action = component.get("c.findAllEmailsByOppId");
        action.setCallback(this, function(a) {
            var returnValue = a.getReturnValue();
            component.set("v.allEmails", returnValue);
            component.set("v.filteredEmails", returnValue);
			component.set("v.toFromAddresses", helper.createToFromAddressesArray(returnValue));
        });
        action.setParams({
            oppId: component.get("v.recordId")
        });
        $A.enqueueAction(action);

        component.set('v.emailMessageDataTableColumns', helper.getDataTableColumns());
    },
    
    //opens the modal and sets the emailsMessageId
    // is called from dataTable with emailMessage-rows
    openModal: function(component, event, helper) {
        var row = event.getParam('row');
        console.log(row);
        var emailMessageId = row.Id;
        component.set("v.emailMessageId", emailMessageId);
        component.set("v.isOpen", true);
        
        var action = component.get("c.getAllEmailAttachments");
        action.setParams({
            messageId: emailMessageId
        });
        action.setCallback(this, function(a) {
            var returnValue = a.getReturnValue();
            component.set("v.emailAttachments", returnValue);
        });
        $A.enqueueAction(action);
    },
    
    // opens email message page. there user can reply or forward an email.
    openEmailMessageRecordPage: function(component, event, helper) {
        var row = event.getParam('row');
        console.log(row);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/lightning/n/EmailMessageView_Badumabu"
        });
        urlEvent.fire();
    },

	//closes the modal
    closeModal: function(component, event, helper) { 
        component.set("v.isOpen", false);
    },
    
    //closes the modal
    closeForawrdModal: function(component, event, helper) { 
        component.set("v.forwardEmailFlag", false);
    },
    
    openAttachment: function(component, event, helper){
        var attId = event.getSource().get("v.value");
        var url="/servlet/servlet.FileDownload?file="+ attId;
        var newWin=window.open(url, 'Popupa','height=500,width=700,left=100,top=100,resizable=no,scrollbars=yes,toolbar=no,status=no');
	},

    //filters the emails
    filterEmails: function(component, event, helper) {
		var allEmails = component.get("v.allEmails");
        var searchString = component.get("v.searchString");
        var selectedToFromAddresses = component.get("v.selectedToFromAddresses");
        // transfer selectedtofromaddresses into simple array so its easier to use later with indexOf
        var onlyEmailsArray = [];
       	for(var i = 0; selectedToFromAddresses.length > i; i++){
            onlyEmailsArray.push(selectedToFromAddresses[i].label);
        }
        // if no searchString is given and no emailaddresses are selected, show all emailmessages
        if(searchString == '' && onlyEmailsArray.length == 0){
        	component.set("v.filteredEmails",allEmails);
            return;
        }
        var filteredEmails = allEmails.filter(function(item){
            return helper.filterEmail(item, onlyEmailsArray, searchString)
        });
        component.set("v.filteredEmails",filteredEmails);
    },
    
    openReplyEmail: function(component, event, helper) {
        component.set("v.isOpen", false);
        component.set("v.replyEmailFlag", true);
        component.set("v.forwardEmailFlag", false);
    },
    
    openForwardEmail: function(component, event, helper) {
        component.set("v.isOpen", false);
        component.set("v.replyEmailFlag", false);
        component.set("v.forwardEmailFlag", true);
    },
    
    //closes reply overlay
    closeReplyModal: function(component, event, helper) { 
        component.set("v.replyEmailFlag", false);
    },
    
    //closes forward overlay
    closeForwardModal: function(component, event, helper) { 
        component.set("v.forwardEmailFlag", false);
    }
    
})