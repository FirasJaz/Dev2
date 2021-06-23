({
    doInit : function(component, event, helper) {
        var oppId = component.get("v.recordId");
        var action = component.get("c.onSearchFieldChanged"); 
        $A.enqueueAction(action);
        
        var action2 = component.get("c.getCorrespondenceList"); 
        action2.setCallback(this, function(response){
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.correspondenceOptions", response.getReturnValue());
            }
        });
        $A.enqueueAction(action2);
        
        var action3 = component.get("c.getNewComment");
        action3.setParams({
            "oppId":oppId
        });
        action3.setCallback(this, function(response){
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.oppComment", response.getReturnValue());
            }
        });
        $A.enqueueAction(action3);
        
	},
    
    saveComment : function(component, event, helper) {
        var oppComment = component.get("v.oppComment");
        var action = component.get("c.saveOppComment"); 
        action.setParams({
            "oppComment":oppComment
        });
        action.setCallback(this, function(response){
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
    
    onSearchFieldChanged: function (component, event, helper) {
        var oppId = component.get("v.recordId");
        var srchComment = component.get("v.srchComment");
        var srchCorrespondence = component.get("v.srchCorrespondence");
        var action = component.get("c.searchOnComments"); 
        action.setParams({
            "oppId":oppId,
            "srchCorrespondence":srchCorrespondence,
            "srchComment":srchComment
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.commentList", response.getReturnValue());
                component.set("v.data", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    
    openCommentRecord: function (component, event, helper) {
        var commentId = event.getSource().get("v.value");
        component.set("v.showCommentRecord", true);
        component.set("v.selectedCommentId", commentId);
    },
    
    //closes the modal
    closeCommentDialog: function(component, event, helper) { 
        component.set("v.showCommentRecord", false);
        component.set("v.selectedCommentId", "");
    },

})