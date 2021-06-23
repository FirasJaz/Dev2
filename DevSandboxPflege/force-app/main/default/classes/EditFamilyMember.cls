/****************************************************************************************************************************
//      Erstellt 08.05.2017 von MZ
//      Klose und Srocke Gesellschaft für kreative Konfliktlösungen GmbH
//      Mindelweg 11
//      22393 Hamburg 
//      Tel.:  04064917161
//      Fax.: 04064917162
//      Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:    Familienmitglied bearbeiten
//
//****************************************************************************************************************************
//Änderungen:
//    16.06.2017 BT Vorauswahl von bekannten Krankheiten beim Bearbeiten des Kontakts
//    21.06.2017 MZ selecting contact role is mandatory
//****************************************************************************************************************************
*/
public class EditFamilyMember{
    public static String noContactRoles = 'Die Opportunity hat keinen Kontakt!';
    public static String contactRolesDistribution= 'Eine Opportunity kann jeweils nur einen Ansprechpartner und einen Pflegebedürftigen haben.';
    public static String selectRole = 'Bitte wählen Sie die Rolle aus!';
    public Boolean btnDisabled{get; set;} 
    
    public List<SelectOption> contactOptions;
    public List<SelectOption> bekannteKrankheitenOptions;

    private Id opportunityId;
    public Contact formObj {get; set;}
    public List<OpportunityContactRole> contactRoles {set;get;}
    public Integer totalCurrContacts{get; set;}
    
    public String layout {get; set;}
    public String role_layout{get; set;}
    
    public String primaryContactId {get; set;}
    
    public Boolean showEditMember{get; set;}
    public Boolean inPlzTool{get; set;}
    
    public Id selectedContact{get; set;}
    
    public String[] krankheitenArray { get; set; }
    
    public EditFamilyMember(Id oppId) {
        showEditMember = false;
        layout = 'None';
        role_layout = 'None';
        
        opportunityId = oppId;
    }
   
    public Pagereference start(){
        showEditMember = true;
        layout = 'initial';
        
        btnDisabled = false;
        contactRoles = [select id, contactId, role, isPrimary, contact.Name from OpportunityContactRole where opportunityId =:opportunityId ];
        System.debug('mansi::contactRoles::'+ contactRoles);
        if(contactRoles == null || contactRoles.size() == 0 ){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noContactRoles ));
            btnDisabled = true;
            showEditMember = false;
            layout = 'None';
            role_layout = 'None';
            return null;
        }
        
        totalCurrContacts = contactRoles.size();
        selectedContact = contactRoles[0].contactId;
        setSelectedContact();
        
        krankheitenArray = new String[]{};
        
        if(formObj != null && formObj.Bekannte_Krankheiten__c != null && formObj.Bekannte_Krankheiten__c != ''){
           krankheitenArray = formObj.Bekannte_Krankheiten__c.split('[;]{1}[\\s]?');
        }
        
        return null;
    }
    
    public void setSelectedContact(){
        formObj = [select    id,
                             Salutation,
                             FirstName,
                             Phone,
                             LastName,
                             OtherPhone,
                             Title,
                             MobilePhone,
                             Art_des_Kontakts__c,
                             Familien_Zugeh_rigkeit__c,
                             Email,
                             von__c,
                             MailingStreet,
                             Description,
                             MailingCity,
                             MailingState,
                             MailingPostalCode,
                             MailingCountry,
                             Pflegegrad__c,
                             Versicherungsnummer__c,
                             Pflegestufe__c,
                             Kranken_Pflegekasse__c,
                             Pflegestufe_beantragt__c,
                             Birthdate,
                             Geburtsjahr__c,
                             Bekannte_Krankheiten__c,
                             Sonstige_Krankheiten__c
                        from Contact where Id =: selectedContact limit 1];
                        
        krankheitenArray = new String[]{};
        
        if(formObj.Bekannte_Krankheiten__c != null && formObj.Bekannte_Krankheiten__c != ''){
           krankheitenArray = formObj.Bekannte_Krankheiten__c.split('[;]{1}[\\s]?');
        }                        
    }
    
    public Pagereference abbruchRoles(){
        role_layout = 'None';
        return null;
    }
    
    public Pagereference abbruch(){
        showEditMember = false;
        layout = 'none';
        
        return null;
    }
    
    public PageReference zuOpportunity(){
        PageReference returnPage = new PageReference('/' + opportunityId);
        returnPage.setRedirect(true);
        return returnPage ;
    } 
    
    public PageReference speichern(){
        formObj.Bekannte_Krankheiten__c = '';   
        if(krankheitenArray.size() > 0) {
            for(String kh: krankheitenArray) {
                if(formObj.Bekannte_Krankheiten__c == ''){
                    formObj.Bekannte_Krankheiten__c = kh + ';';
                }
                else {
                    formObj.Bekannte_Krankheiten__c += kh + ';';
                }
            }
        }

        update formObj;
        
        role_layout = 'initial';
        initiateContactRoles();
        return null;
    }
    
    public void initiateContactRoles(){
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
            system.debug('mansi::role::'+r);
            if(r == null || r == '--None--'){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, selectRole));
                return null;
            }
        }
        if(aspCount == 0 || aspCount >1 || pbCount > 1){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, contactRolesDistribution));
            return null;
        }
        
        update contactRoles;
        
        showEditMember = false;
        layout = 'none';
        role_layout = 'none';
        
        return null;
       
    }
    
    public void setPrimary() {
        primaryContactId = System.currentPageReference().getParameters().get('contactId'); 
    }
    
    public List<Selectoption> getContactOptions(){
         List<SelectOption> options = new List<SelectOption>();
         for( OpportunityContactRole cr : contactRoles ){
             options.add(new SelectOption(cr.contactId, cr.contact.Name));
         }
         return options;
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