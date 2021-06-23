({
    // on mouse leave clear tmpOptions & hide the search result component 
    onmouseleave : function(component, event, helper){
        component.set("v.tmpOptions", null);
        helper.closeListbox(component);
    },
    // onfocus search input, open listbox/searchresults and pass input to searchHelper
    onfocus : function(component, event, helper){
        component.set("v.tmpOptions", null);
        helper.openListbox(component);
        // check if searchKeyWord is empty, then pass empty string, otherwise error due to undefined value
        var getInputkeyWord = (component.get("v.searchKeyWord") == undefined) ? '' : component.get("v.searchKeyWord");
        helper.searchHelper(component, event, getInputkeyWord);
    },
    // when key is pressed, check if searchKeyWord has value (size > 0), then pass to searchHelper
    // otherwise: close listbox
    keypressed : function(component, event, helper) {
        var getInputkeyWord = component.get("v.searchKeyWord"); 
        if(getInputkeyWord.length > 0){
        	helper.openListbox(component);
        	helper.searchHelper(component, event, getInputkeyWord);
        }
        else{  
            component.set("v.tmpOptions", null); 
        	helper.closeListbox(component);
        }
    },
    
    
    // removes option from selected options
    removeOption: function(component,event,helper){
        var optionToRemove = event.getSource().get("v.name");
        var selectedOptions = component.get("v.selectedOptions");

        helper.removeOptionByValue(component, "selectedOptions", selectedOptions, optionToRemove); 
    },
    
    // adds the selected option to the selectedOptions-array
    // clears searchKey Word
    // remove selected option from options in listbox
    selectOption : function(component, event, helper){
       component.set("v.searchKeyWord",null);
       var selectedOptionValue = event.currentTarget.dataset.optionvalue;
       var allOptions = component.get("v.allOptions");
       var selectedOption = allOptions.filter(function(item){return item.value == selectedOptionValue;})[0];

       var tmpOptions = component.get("v.tmpOptions");
        
       helper.removeOptionByValue(component, "tmpOptions", tmpOptions, selectedOptionValue);
       
       var selectedOptions =  component.get("v.selectedOptions");
       selectedOptions.push(selectedOption);
       component.set("v.selectedOptions", selectedOptions);
      
       helper.closeListbox(component);
	 
       var forclose = component.find("lookup-pill");
       $A.util.addClass(forclose, 'slds-show');
       $A.util.removeClass(forclose, 'slds-hide');
        
    },
})