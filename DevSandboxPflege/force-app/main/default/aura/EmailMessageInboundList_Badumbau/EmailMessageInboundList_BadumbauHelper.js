({
	//returns the definition of columns for datatable which lists the emailmessages
	getDataTableColumns : function() {
		return [{ label: 'Von', fieldName: 'FromAddress', type: 'text' },
                { label: 'Betreff', fieldName: 'Subject', type: 'text'},
                { label: 'Datum', fieldName: 'MessageDate', type: 'date',typeAttributes: {
                    weekday: 'short',
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                } },
                { label: 'Öffnen', type: 'button', typeAttributes:
                    { label: 'Öffnen', name: 'view', variant:'base', title: 'Klicken, um die Email anzuzeigen' }}];            
	}
})