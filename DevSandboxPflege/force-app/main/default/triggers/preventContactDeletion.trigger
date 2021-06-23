/********************************************************************************************************************************************
//  Erstellt 03.01.2018 von MZ
//                      Klose und Srocke Gesellschaft fÃ¼r kreative KonfliktlÃ¶sungen mbH
//                      Mindelweg 11
//                      22393 Hamburg 
//                      Tel.:  04064917161
//                      Fax.: 04064917162
//                      Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Beschreibung: because of error in lead conversion (#153815493) we need to grant modifyAll contact permission to ZWB users. 
//  As they are not permitted to delete the contact, the trigger stops the contact from being deleted.
//
//********************************************************************************************************************************************
//  Änderungen:
//********************************************************************************************************************************************
*/
trigger preventContactDeletion on Contact (before delete) {
    String profileId = Userinfo.getProfileId(); 
    String profileName =[Select Id,Name from Profile where Id=:profileId].Name;
    
        
    if(profileName == 'ZWB - Teamlead' || profileName == 'ZWB - Standardbenutzer')
    {
        for (Contact preventDelete: trigger.old)
        {       
             preventDelete.addError('Sie sind nicht berechtigt, Kontakte zu löschen.');                
        }
    }
}