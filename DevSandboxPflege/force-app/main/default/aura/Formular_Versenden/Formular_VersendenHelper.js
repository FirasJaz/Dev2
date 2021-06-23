({
    //
    getDefaultReceiver: function(component){
        var perEmail = component.find("bla_per_mail");
        var msg = component.get('v.blankoPostMsg');
        var contactId = component.get('v.recordId');
        var action = component.get("c.setDefaultReceiver");
        action.setParams({
            "contactId": contactId,
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
            if (state == "SUCCESS") {
                var result = response.getReturnValue();
                if(result != 'Keine ContactRole'){
                    var data = result.split(',');
                    var receiver = data[0];
                    var email = data[1];
                    var options = [];
                    if(receiver == 'PBASP'){
                        options.push('Pflegebedürftiger');
                        if(data.length == 3){
                            var rec2 = data[2];
                            if(rec2 == 'AJ'){
                                options.push('AnsprechpartnerIn');
                            }
                            else if(rec2 == 'PJ'){
                                options.push('Pflegedienst');
                            }
                        }
                        component.set('v.options', options);
                        setTimeout(function(){
                            component.set('v.selectedValue', 'Pflegebedürftiger');
                        }, 1000);
                    }
                    else if(receiver == 'AnsprechpartnerIn'){
                        options.push('AnsprechpartnerIn');
                        if(data.length == 3){
                            options.push('Pflegedienst');
                        }
                        component.set('v.options', options);
                        setTimeout(function(){
                            component.set('v.selectedValue', 'AnsprechpartnerIn');
                        }, 1000);
                    }
                    else{
                        options.push('Pflegebedürftiger');
                        if(data.length == 3){
                            var rec2 = data[2];
                            if(rec2 == 'AJ'){
                                options.push('AnsprechpartnerIn');
                            }
                            else if(rec2 == 'PJ'){
                                options.push('Pflegedienst');
                            }
                        }
                        else if(data.length > 3) {
                            options.push('AnsprechpartnerIn');
                            options.push('Pflegedienst');
                        }
                        component.set('v.options', options);
                        setTimeout(function(){
                            component.set('v.selectedValue', receiver);
                        }, 1000);
                    }
                    // check email address.
                    if(email == 'null'){
                        perEmail.set('v.disabled', true);
                        component.set('v.hasEmail', false);
                        component.set('v.blankoEmailMsg', 'Es wurde keine Email Adresse gefunden!');
                    }
                    else {
                        perEmail.set('v.disabled', false);
                        component.set('v.hasEmail', true);
                        component.set('v.emailAddress', email);
                        if(msg == 'Anschreiben für PG54 und PG51 ausdrucken'){
                            component.set('v.blankoEmailMsg', 'Email mit Anhang an '+ email);
                            component.set('v.ausEmailMsg', 'Vorausgefüllt per Email an '+ email);
                        }
                        else if(msg == 'Eingangsbestätigung ausdrucken') {
                            component.set('v.blankoEmailMsg', 'Eingangsbestätigung per Email an '+ email);
                        }
                    }
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title:'Message',
                        message:'Es wurde keine Role beim Opportunity gefunden.',
                        key:'info_alt',
                        type:'Error',
                        mode:'pester'
                    });
                    toastEvent.fire();
                    setTimeout(function(){
                        $A.get("e.force:closeQuickAction").fire(); 
                    }, 1000);
                }
            }
        });
        $A.enqueueAction(action);
    },

    //
    setReceiverEmail: function(component){
        //
        var hasAttachment = component.get('v.hasAttachment');
        var blanPerEmail = component.find("bla_per_mail");
        var perPost = component.find("aus_per_post");
        var perEmail = component.find("aus_per_mail");
        //
        var msg = component.get('v.blankoPostMsg');
        var contactId = component.get('v.recordId');
        var receiver = component.find('select').get('v.value');
        var action = component.get("c.getReceiverEmail");
        action.setParams({
            "contactId": contactId,
            "receiver": receiver
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var result = response.getReturnValue();
                if (result != null){
                    component.set('v.emailAddress', result);
                    blanPerEmail.set('v.disabled', false);
                    if(msg == 'Anschreiben für PG54 und PG51 ausdrucken'){
                        if(hasAttachment == true){
                            perEmail.set('v.disabled', false);
                            perPost.set('v.disabled', false);
                        }
                        else{
                            perEmail.set('v.disabled', true);
                            perPost.set('v.disabled', true);
                        }
                        component.set('v.blankoEmailMsg', 'Email mit Anhang an '+ result);
                        component.set('v.ausEmailMsg', 'Vorausgefüllt per Email an '+ result);
                    }
                    else if(msg == 'Eingangsbestätigung ausdrucken') {
                        component.set('v.blankoEmailMsg', 'Eingangsbestätigung per Email an '+ result);
                    }
                }
                else{
                    blanPerEmail.set('v.disabled', true);
                    component.set('v.blankoEmailMsg', 'Es wurde keine Email Adresse gefunden');
                    if(msg == 'Anschreiben für PG54 und PG51 ausdrucken'){
                        perEmail.set('v.disabled', true);
                        component.set('v.ausEmailMsg', 'Es wurde keine Email Adresse gefunden');
                        if(hasAttachment == true){
                            perPost.set('v.disabled', false);
                        }
                        else{
                            perPost.set('v.disabled', true);
                        }
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    //
    sendAntrag: function(component){
        var contactId = component.get('v.recordId');
        var receiver = component.find('select').get('v.value');
        var action = component.get("c.sendMailToClient");
        action.setParams({
            "contactId": contactId,
            "receiver": receiver
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state == "SUCCESS") {
              var result = response.getReturnValue();
              if (result == 'Email wurde erfolgreich Versendet!'){
                    var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                            title:'Message',
                            message: result,
                            key:'info_alt',
                            type:'success',
                            mode:'pester'
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire()
                }
                else {
                    var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        title:'Message',
                        message: 'Error by sending Email',
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
                    title:'Message',
                    message: 'Error by sending Email',
                    key:'info_alt',
                    type:'Error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    sendFilledAntrag: function(component){
        var contactId = component.get('v.recordId');
        var receiver = component.find('select').get('v.value');
        var action = component.get("c.sendFilledFormular");
        action.setParams({
            "contactId": contactId,
            "receiver": receiver
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state == "SUCCESS") {
              var result = response.getReturnValue();
              if (result == 'Email wurde erfolgreich Versendet!'){
                    var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                            title:'Message',
                            message: result,
                            key:'info_alt',
                            type:'success',
                            mode:'pester'
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire()
                }
                else {
                    var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        title:'Message',
                        message: 'Error by sending Email',
                        key:'info_alt',
                        type:'error',
                        mode:'pester'
                    });
                    toastEvent.fire();
                }
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    title:'Message',
                    message: 'Error by sending Email',
                    key:'info_alt',
                    type:'error',
                    mode:'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    //
    sendBestaetigung: function(component){
        var contactId = component.get('v.recordId');
        var receiver = component.find('select').get('v.value');
        var action = component.get("c.sendConfirmationToClient");
        action.setParams({
            "contactId": contactId,
            "receiver": receiver
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state == "SUCCESS") {
              var result = response.getReturnValue();
              if (result == 'Email wurde erfolgreich Versendet!'){
                    var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                            title:'Message',
                            message: result,
                            key:'info_alt',
                            type:'success',
                            mode:'pester'
                    });
                    toastEvent.fire();
                    var sObectEvent = $A.get("e.force:navigateToSObject");
                    sObectEvent .setParams({
                    "recordId": contactId
                    });
                    sObectEvent.fire();
                }
                else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                    title:'Message',
                    message: 'Fehler beim Emailversand',
                    key:'info_alt',
                    type:'error',
                    mode:'pester'
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    },

    //
    setButtonVisibility: function(component){
        var msg = component.get('v.blankoPostMsg');
        var contactId = component.get('v.recordId');
        var perPost = component.find("aus_per_post");
        var perEmail = component.find("aus_per_mail");
        var action = component.get("c.setFilledButton");
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state == "SUCCESS") {
                var result = response.getReturnValue();
                if(msg == 'Anschreiben für PG54 und PG51 ausdrucken'){
                    component.set('v.showButton', true);
                    if(result == true){
                        component.set('v.hasAttachment', true);
                        perEmail.set('v.disabled', false);
                        perPost.set('v.disabled', false);
                    }
                    else{
                        component.set('v.hasAttachment', false);
                        perEmail.set('v.disabled', true);
                        perPost.set('v.disabled', true);
                    }
                }
                else{
                    component.set('v.showButton', false);
                }
            }
            else{
                if(msg == 'Anschreiben für PG54 und PG51 ausdrucken'){
                    perEmail.set('v.disabled', true);
                    perPost.set('v.disabled', true);
                }
                else{
                    component.set('v.showButton', false);
                }
            }
        });
        $A.enqueueAction(action);
    },

    //
    getFile: function(component){
        var contactId = component.get('v.recordId');
        var action = component.get("c.fetchContentDocument");
        action.setParams({
            "contactId": contactId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.selectedDocumentId", result.ContentDocumentId);
            }
        });
        $A.enqueueAction(action);
    },

    getReceiverId: function(component){
        var contactId = component.get('v.recordId');
        var receiver = component.find('select').get('v.value');
        var action = component.get("c.getReceiverId");
        action.setParams({
            "contactId": contactId,
            "receiver": receiver
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.receiverId', result);
            }
        });
        $A.enqueueAction(action);
    },

})