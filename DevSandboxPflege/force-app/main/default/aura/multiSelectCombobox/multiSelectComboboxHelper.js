({
    // gets allOptions, compares label with searchString, returns only those who match
    // exluding values which are already selected
    searchHelper : function(component, event, searchString) {
        var options = component.get("v.allOptions");
        var selectedOptions = component.get("v.selectedOptions");
        options = options.filter(function(item){
            return (item.label.toLowerCase().indexOf(searchString.toLowerCase()) != -1 && !selectedOptions.includes(item))
        });
        
        if (options.length == 0) {
            component.set("v.Message", 'No Records Found...');
        } else {
            component.set("v.Message", '');
        }
        
        component.set("v.tmpOptions",options);
    },
    
    //removes an option by a value from an array with the structure [{label:'x',value:'y'},...]
    removeOptionByValue: function(component, optionsArrayName, options, optionValue) {
        for(var i = 0; i < options.length; i++){
            if(options[i].value == optionValue){
                options.splice(i, 1);
            }  
        }
        console.log("optionsarraybname: "+optionsArrayName + " eins entfernt");
        console.log(component.get("v."+optionsArrayName));
        console.log(optionValue + " entfernen");
        component.set("v."+optionsArrayName, options);
        console.log(component.get("v."+optionsArrayName));
        
        var a = component.get("v."+optionsArrayName);
        console.log(a.length);
    },
    
    //closes/hides the listbox/searchresults of the multiselectcombobox
    closeListbox: function(component) {
        var forclose = component.find("multiSelectCombobox");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    //opens/shows the listbox/searchresults of the multiselectcombobox
    openListbox: function(component) {
        var forOpen = component.find("multiSelectCombobox");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
    }
})