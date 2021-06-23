({  // rename the uploaded document
  UpdateDocument : function(component,event,Id) {  
      var action = component.get("c.UpdateFiles");
      var documentType = component.find("form_art").get("v.value");
      if (documentType == "frei") {
        var fName = component.find("anderer_art").get("v.value");
      }
      else if((documentType == "Antrag") || (documentType == "Genehmigung")){
        var fName = component.find("form_art").get("v.value") + "_PG"+component.find("form_code").get("v.value");
      }
      else{
        var fName = component.find("form_art").get("v.value");
      }
      action.setParams({
          "documentId":Id,  
          "title": fName,  
          "recordId": component.get("v.recordId")  
      });  
      action.setCallback(this,function(response){  
        var state = response.getState();  
        if(state=='SUCCESS'){  
          var result = response.getReturnValue();  
          console.log('Result Returned by rename document: ' +result);
        }
        else{
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
              title:'Error Message',
              message:'Das Dokument konnte nicht hochgeladen werden. Bitte prüfen ob ein Opportunity oder eine PB-ContactRole vorhanden ist.',
              key:'info_alt',
              type:'Error',
              mode:'pester'
          });
          toastEvent.fire();
        }  
      });  
      $A.enqueueAction(action);
  },

  // set curabox
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

  // checks whether the orders should be created.
  setIsCooperativ: function(component){
      var action = component.get("c.checkIfCreateOrder");
      var contactId = component.get('v.recordId');
      action.setParams({
          "contactId": contactId
      });
      action.setCallback(this, function(response) {
          var state = response.getState();
          if (state == "SUCCESS") {
              var check = response.getReturnValue();
              component.set('v.isCooperativ', check);
          }
          else if (state === "ERROR") {
              var errors = response.getError();
              console.error(errors);
          }
      });
      $A.enqueueAction(action);
  },

    //
  createGenehmigung : function(component, documentId) {  
      var action = component.get("c.newGenehmigung");
      var contactId = component.get('v.recordId');
      var paragraph = component.find("form_code").get("v.value");
      action.setParams({
          "contactId": contactId,  
          "paragraph": paragraph,  
          "documentId": documentId  
      });  
      action.setCallback(this,function(response){  
        var state = response.getState();
        if(state=='SUCCESS'){
          var result = response.getReturnValue();
          if (result == 'OK'){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title:'Success Message',
                message:'Genehmigung successfully created',
                key:'info_alt',
                type:'Success',
                mode:'pester'
            });
            toastEvent.fire(); 
          }
          else if(result == 'Fehler beim Kundenstatus'){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title:'Error Message',
                message:'Error by update Kundenstatus',
                key:'info_alt',
                type:'Error',
                mode:'pester'
            });
            toastEvent.fire(); 
          }
          else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title:'Error Message',
                message:'Error by create Genehmigung',
                key:'info_alt',
                type:'Error',
                mode:'pester'
            });
            toastEvent.fire(); 
          }
        }
        else{
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
              title:'Error Message',
              message:'Error by create Genehmigung',
              key:'info_alt',
              type:'Error',
              mode:'pester'
          });
          toastEvent.fire(); 
        }  
      });  
      $A.enqueueAction(action);
  },
    isTerminated: function (component) {
      let action = component.get("c.isTerminated");
      let contactId = component.get("v.recordId")
        action.setParams({
            "contactId" : contactId
        })
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let res = response.getReturnValue();
                component.set("v.isTerminated54", res.PG54)
                component.set("v.isTerminated51", res.PG51)
            }

        });
        $A.enqueueAction(action);
    },
  getGenehmigungIdPG54: function(component){
      var action = component.get("c.goToGenehmigung");
      var contactId = component.get('v.recordId');
      action.setParams({
        "contactId": contactId,  
        "paragraph": '54' 
      });
      action.setCallback(this, function(response) {
          var state = response.getState();
          if (state == "SUCCESS") {
              var object = response.getReturnValue();
              if(object != null){
                component.set('v.aprovalId54', object);
              }
              else{
                component.set('v.aprovalId54', null);
              }
          }
      });
      $A.enqueueAction(action);
  },

  getGenehmigungIdPG51: function(component){
    var action = component.get("c.goToGenehmigung");
    var contactId = component.get('v.recordId');
    action.setParams({
      "contactId": contactId,  
      "paragraph": '51' 
    });
    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state == "SUCCESS") {
            var object = response.getReturnValue();
            if(object != null){
              component.set('v.aprovalId51', object);
            }
            else{
              component.set('v.aprovalId51', null);
            }
        }
    });
    $A.enqueueAction(action);
  },

  // set curabox
  setContactRole: function(component){
    var action = component.get("c.getContactRole");
    var contactId = component.get('v.recordId');
    action.setParams({
        "contactId": contactId
    });
    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state == "SUCCESS") {
            var role = response.getReturnValue();
            component.set('v.role', role);
        }
        else if (state === "ERROR") {
            var errors = response.getError();
            console.error(errors);
        }
    });
    $A.enqueueAction(action);
  },

  })