/****************************************************************************************************************************
//  Erstellt 27.02.2017 von MZ
//      Klose und Srocke Gesellschaft für kreative Konfliktlösungen GmbH
//      Mindelweg 11
//      22393 Hamburg 
//      Tel.:  04064917161
//      Fax.: 04064917162
//      Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:    Neues Familienmitglied hinzufügen
//    the tool may get started from either PlzTool or opportunity view page
//
//****************************************************************************************************************************
//Änderungen:
//    21.06.2017 MZ contact role is mandatory
//****************************************************************************************************************************
*/
public class NewFamilyMember{
    public static String maxContactRoles = 'Opportunities können maximal 2 Kontaktrollen haben.';
    public static String contactRolesDistribution= 'Eine Opportunity kann jeweils nur einen Ansprechpartner und einen Pflegebedürftigen haben.';
    public static String selectRole = 'Bitte wählen Sie die Rolle aus!';
    public Boolean btnDisabled{get; set;} 
    
    public List<SelectOption> bekannteKrankheitenOptions;

    private Id opportunityId;
    public Contact formObj {get; set;}
    public List<OpportunityContactRole> contactRoles {set;get;}
    public Integer totalCurrContacts{get; set;}
    public OpportunityContactRole newRole {get; set;}
    
    public String layout {get; set;}
    public String role_layout{get; set;}
    
    public String primaryContactId {get; set;}
    
    public Boolean showNewMember{get; set;}
    public Boolean inPlzTool{get; set;}
    
    // callFromPlzTool should set to true to initiate the tool from PlzTool 
    public NewFamilyMember(Id oppId, Boolean callFromPlzTool) {
        showNewMember = false;
        layout = 'None';
        role_layout = 'None';
        
        inPlzTool = callFromPlzTool;
        
        opportunityId = oppId;
    }
   
    public Pagereference start(){
        showNewMember = true;
        layout = 'initial';
        
        formObj = new Contact();
        List<RecordType> rtList = [select id, name from recordType where SObjectType = 'Contact' and developerName = 'Familienangeh_rige' limit 1];
        if(rtList.isEmpty()){
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No "Familienangehörige" recordType found for Contact!'));
             return null;
        }
        formObj.recordTypeId = rtList[0].Id;
        List<Opportunity> oppList = [select id, accountId from Opportunity where Id = :opportunityId limit 1];
        if(oppList.isEmpty()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No Opportunity found with Id '+ opportunityId  +'!'));
            return null;
        }
        formObj.AccountId = oppList[0].accountId ;
        btnDisabled = false;
        contactRoles = [select id, contactId, role, isPrimary, contact.Name from OpportunityContactRole where opportunityId =:opportunityId ];
        totalCurrContacts = contactRoles.size();
        if(totalCurrContacts >= 2){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, maxContactRoles ));
            btnDisabled = true;
        }
        
        return null;
    }
    
    public Pagereference abbruch(){
        showNewMember = false;
        layout = 'none';
        
        if( !inPlzTool ){
            return zuOpportunity();
        }
        
        return null;
    }
    
    public PageReference zuOpportunity(){
        PageReference returnPage = new PageReference('/' + opportunityId);
        returnPage.setRedirect(true);
        return returnPage ;
    } 
    
    public PageReference speichern(){
        formObj.Bekannte_Krankheiten__c = formatValue(formObj.Bekannte_Krankheiten__c);
        formObj.Id = null;
        insert formObj;
        
        role_layout = 'initial';
        initiateContactRoles();
        return null;
    }
    
    public void initiateContactRoles(){
            newRole = new OpportunityContactRole();
            if(formObj.Id != null){
                newRole.OpportunityId = opportunityId;
                newRole.ContactId = formObj.Id;
            }
            contactRoles = [select id, contactId, role, isPrimary, contact.Name from OpportunityContactRole where opportunityId =:opportunityId ];
            totalCurrContacts = contactRoles.size();
            for(OpportunityContactRole cr : contactRoles){
                if(cr.isPrimary){
                    primaryContactId = cr.contactId;
                }
            }
    }
    
    public pageReference updateContactRoles() {
        system.debug('mansi: updateContactRoles');
        Integer aspCount = 0;
        Integer pbCount = 0;
        List<String> roles = new List<String>();
        roles.add(newRole.role);
        System.debug('mansi:::primaryContactId :::'+ primaryContactId );
        if(primaryContactId == String.valueOf(newRole.contactId)){
            newRole.isPrimary = true;
        }
        for(OpportunityContactRole ocr : contactRoles){
            roles.add(ocr.Role);
            if(primaryContactId == String.valueOf(ocr.contactId)){
                ocr.isPrimary = true;
            }
        }
        for(String r : roles){
            if(r == 'ASP'){
                aspCount = aspCount + 1;
            }
            if(r == 'PB'){
                pbCount = pbCount + 1;
            }
            if(r == 'PB = ASP'){
                aspCount = aspCount + 1;
                pbCount = pbCount + 1;
            }
            if(r == null || r == '--None--'){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, selectRole));
                return null;
            }
        }
        if(aspCount == 0 || aspCount >1 || pbCount > 1){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, contactRolesDistribution));
            return null;
        }
        
        //contactRolesDistribution
        insert newRole;
        update contactRoles;
        
        if(!inPlzTool ){
            PageReference returnPage = new PageReference('/' + opportunityId);
            returnPage.setRedirect(true);
            return returnPage;
        }
        
        showNewMember = false;
        layout = 'none';
        role_layout = 'none';
        
        return null;
       
    }
    
    public void setPrimary() {
        primaryContactId = System.currentPageReference().getParameters().get('contactId'); 
    }
    
    public List<Selectoption> getBekannteKrankheitenOptions(){
         List<SelectOption> options = new List<SelectOption>();
         Schema.DescribeFieldResult fieldResult = Contact.Bekannte_Krankheiten__c.getDescribe();
         List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
         for( Schema.PicklistEntry f : ple){
             options.add(new SelectOption(f.getValue(), f.getLabel()));
         }
         return options;
    }
    
    public String formatValue(String inputStr){
        String outputStr = '';
        if(inputStr == null || inputStr == '[]' || inputStr == ''){
            return null;        
        }
        else{
            inputStr = inputStr.subString(1, inputStr.length()-1);
            System.debug('mansi:::'+ inputStr);
            String[] values = inputStr.split(', ');
            if(values.size()>1){
                for(String v : values){
                    outputStr += v + ';';
                }
                outputStr = outputStr.subString(0, outputStr.length()-1);
            }
            else{
                outputStr = inputStr;
            }
        }
        return outputStr;
    }
}