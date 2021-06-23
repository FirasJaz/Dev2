trigger split_mailingstreet on Contact (before insert, before update) {
    Set<Id> ContIdset = new Set<Id>();
    String digitBoundary = '09'; 
    for (Contact Cont: Trigger.new){
        ContIdset.add(Cont.Id);
        Cont.house_number__c = '';
        Cont.Street_name__c = '';
        if(cont.mailingstreet != null){
            try{
                String[] strArray = cont.mailingstreet.split(' ');
                if(strArray.size()>1){
                    String secondPart = strArray [strArray.size()-1];
                    if(secondPart.length()<12){
                        Cont.house_number__c = secondPart;
                    }
                }
                Cont.Street_name__c = cont.mailingstreet.removeEnd(' ' + Cont.house_number__c);
            }catch(Exception e){
                System.debug('mansi:: in exception');
                Cont.addError('Bitte geben Sie die Hausnummer in der Adresse an!');
            }
            /*
            if(strArray.size() == 2){
                Cont.Street_name__c = strArray [0];
                Cont.house_number__c = strArray [1];
                
            }
            else{
                Cont.Street_name__c = '';
                Cont.house_number__c = '';
                Boolean houseNumberStarted = false;
                Boolean addToHouseNumber = false;
                for(String s: strArray ){
                    System.debug('mansi:::infor:::s ::'+ s);
                    if( addToHouseNumber){
                        Cont.house_number__c += ' ' + s;
                    }
                    if( !houseNumberStarted ){
                        System.debug('mansi::: s.charAt(0)'+ s.charAt(0));
                        System.debug('mansi::: digitBoundary.charAt(0)'+ digitBoundary.charAt(0));
                        System.debug('mansi::: digitBoundary.charAt(1)'+ digitBoundary.charAt(1));
                        if(s.charAt(0) >= digitBoundary.charAt(0) && s.charAt(0) <= digitBoundary.charAt(1)){
                            houseNumberStarted = true;
                            addToHouseNumber = true;
                            Cont.house_number__c = s;
                        }
                    }
                    if( !addToHouseNumber ){
                        if(Cont.Street_name__c == ''){
                            Cont.Street_name__c = s;
                        }else{
                            Cont.Street_name__c += ' ' +s;
                        }
                    }
                }
                
            }
            */
        }
    }
       
}