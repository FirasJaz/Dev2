/****************************************************************************************************************************
//  Erstellt 25.04.2017 von MZ
//      Klose und Srocke Gesellschaft für kreative Konfliktlösungen GmbH
//      Mindelweg 11
//      22393 Hamburg 
//      Tel.:  04064917161
//      Fax.: 04064917162
//      Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:    Controller to start "new family member" from opportunity view page
//
//****************************************************************************************************************************
//Änderungen:
//****************************************************************************************************************************
*/
public class NewFamilyMember_Opp{

public NewFamilyMember newMemberController{set;get;}

public NewFamilyMember_Opp(){
    Id opportunityId = ApexPages.currentPage().getParameters().get('id');
    newMemberController = new NewFamilyMember(opportunityId, false);
}

}