({
    //returns the definition of columns for datatable which lists the emailmessages
	getDataTableColumns : function() {
		return [{ label: 'Von', fieldName: 'FromAddress', type: 'text' },
                { label: 'An', fieldName: 'ToAddress', type: 'text' },
                { label: 'Betreff', fieldName: 'Subject', type: 'text'},
                { label: 'Datum', fieldName: 'MessageDate', type: 'date',typeAttributes: {
                    weekday: 'short',
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                } },
                //{ label: 'Betreff', fieldName: 'Subject', type: 'url', typeAttributes: { label: { fieldName: 'Subject' }, target: '_self', value: { fieldName: 'Id' } } } ];
                { label: 'Öffnen', type: 'button', typeAttributes:
                 { label: 'Öffnen', name: 'view', variant:'base', title: 'Klicken, um die Email anzuzeigen' }}];            
	},
    
    //creates an array with the format [{label:'x',value:'x'},...] with unique values of to/from addresses
    // of the emailmessages, so it can be used in a multi-select box (e.g. multiselect combobox or duallist box)
    createToFromAddressesArray : function(emailMessages){
        var emails = [];
        for (var i = 0; i < emailMessages.length; i++) {
            emails.push(emailMessages[i].FromAddress);
            emails.push(emailMessages[i].ToAddress);
        }
        var uniqueEmails = emails.filter(function(item, i, ar) {
            return (ar.indexOf(item) === i && item != undefined);
        });
        var toFromAddresses = [];
        for (i = 0; i < uniqueEmails.length; i++) {
            toFromAddresses.push({
                'label': uniqueEmails[i],
                'value': uniqueEmails[i]
            });
        }
        return toFromAddresses;
    },
    
    // takes one email and returns true, if it meets the criteria:
    // onlyEmailsArray contains the emails to which the email shall match (email.ToAddress OR email.FromAddress)
    // searchString contains the string which email.Subject OR email.TextBody shall contain
    // if both values are given, both email and searchstring need to be matched!
    // comment: the idea is, that when one selects a few emails, that person then most probably
    // wants to narrow the results then by searching the text or subject!
    filterEmail : function(email, onlyEmailsArray, searchString){
        var r = false;
        var tA = false;
        var fA = false;
        var tB = false;
        var s = false;
        if(onlyEmailsArray.indexOf(email.ToAddress) != -1){tA = true;}
        if(onlyEmailsArray.indexOf(email.FromAddress) != -1){fA = true;}
        if(email.TextBody != undefined){
            if(email.TextBody.toLowerCase().indexOf(searchString.toLowerCase()) != -1){tB = true;}
        }
        if(email.Subject != undefined){
            if(email.Subject.toLowerCase().indexOf(searchString.toLowerCase()) != -1){s = true;}
        }
        if(onlyEmailsArray.length > 0 && searchString != ''){
            return ((tA || fA) && (tB || s));
        } else if (onlyEmailsArray.length > 0 && searchString == '') {
            return (tA || fA);
        } else {
            return (s || tB);
        }
    }
})