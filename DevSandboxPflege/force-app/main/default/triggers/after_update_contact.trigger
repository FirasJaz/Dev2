trigger after_update_contact on Contact (after update) {
    Set<Id> ContIdset = new Set<Id>();
    Set<Id> KdIdset = new Set<Id>();
    Map<Id, Contact> ContMap = new Map<Id, Contact>();
    
     for (Contact Cont: Trigger.new){
         ContIdset.add(Cont.Id);
         ContMap.put(Cont.Id, Cont);
     }   
     
     List<Kunde__c> Kdlist = [SELECT Id, Betreuer__c FROM Kunde__c WHERE Betreuer__c IN :ContIdset];     
     
     if((Kdlist!= null) && (Kdlist.size() > 0)) {
         for(Kunde__c Kd: Kdlist) { 
            KdIdset.add(Kd.Id); 
         }
      }   
     
     List<Anschrift__c> Anlist = [SELECT Id, Kunde__c, Kunde__r.Betreuer__c, Name, Art_der_Anschrift__c, e_mail__c, 
                                    Fax__c, Ort__c, PLZ__c, Stra_e__c, Telefon__c FROM Anschrift__c WHERE Kunde__c IN :KdIdset AND Art_der_Anschrift__c = 'Betreuer']; 

     if((Anlist != null) && (Anlist.size() > 0)) {
         for(Anschrift__c AnVorl : Anlist) {  
            if(!AnVorl.Name.contains('weitere Adresse')) {       
                AnVorl.e_mail__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).Email;
                AnVorl.Fax__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).Fax;           
                AnVorl.Ort__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).MailingCity;
                AnVorl.PLZ__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).MailingPostalCode;
                AnVorl.Stra_e__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).MailingStreet;
                AnVorl.Telefon__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).Phone;
             
             } else {
                AnVorl.e_mail__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).Email;
                AnVorl.Fax__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).Fax;           
                AnVorl.Ort__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).OtherCity;
                AnVorl.PLZ__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).OtherPostalCode;
                AnVorl.Stra_e__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).OtherStreet;
                AnVorl.Telefon__c = ContMap.get(AnVorl.Kunde__r.Betreuer__c).Phone; 
             }
             
             try{
                 update AnVorl;
             } catch (System.Exception e) {}
        }
     }  
     
     if((Kdlist!= null) && (Kdlist.size() > 0)) {
         for(Kunde__c Kd: Kdlist) { 
             try{
                 update Kd;
             } catch (System.Exception e) {}   
          }
      } 

      // AM 06.06.2019
      map<id, string> wrongAddrContactSet = addressHelper.onUpdateContact(trigger.new, trigger.oldMap) ;      
      if(!wrongAddrContactSet.isEmpty()) {
          for(contact c : trigger.new) {
              if(wrongAddrContactSet.containsKey(c.id)) {
                  c.addError('Adresse konnte nicht geändert werden. ' + wrongAddrContactSet.get(c.id));
              }
          }
      }                     
}