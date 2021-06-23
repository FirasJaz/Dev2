trigger Before_delete_Anschrift_trigger on Anschrift__c (before delete) {
    for(Anschrift__c A : trigger.old){
        if(A.Art_der_Anschrift__c == 'Kundenadresse'){
            A.addError('Sie können diese Anschrift nicht löschen, da sie als Kundenadresse markiert ist.');
        }
    }
    Adressverwaltung_class.delete_adressen(trigger.old);
}