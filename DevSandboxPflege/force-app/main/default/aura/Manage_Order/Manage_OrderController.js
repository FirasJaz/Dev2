({
    init: function(cmp, event, helper) {
       var isConsole = cmp.get("v.isConsole");
       if(isConsole){
        var pageReference = cmp.get("v.pageReference");
        console.log('pagereference'+pageReference);
        cmp.set("v.recordId", pageReference.state.c__recordId);
        cmp.set("v.curabox", pageReference.state.c__curabox);
        cmp.set("v.paragraph", pageReference.state.c__paragraph);
        cmp.set("v.toSendMail", pageReference.state.c__toSendMail);
        cmp.set("v.showChildComponent",true);
       }
       else 
       cmp.set("v.showChildComponent",true);
           
    }
})