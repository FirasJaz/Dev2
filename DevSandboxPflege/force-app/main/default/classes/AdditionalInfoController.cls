/****************************************************************************************************************************
// Erstellt 11.04.2017 von MZ
//      Klose und Srocke Gesellschaft für kreative Konfliktlösungen GmbH
//      Mindelweg 11
//      22393 Hamburg 
//      Tel.:  04064917161
//      Fax.: 04064917162
//      Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:    Controller for additional info HNR / Direktvertrieb / Bankdaten + Versandadresse
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************
*/
public class AdditionalInfoController{
    public static String Produkte_sollen_versendet_werden_an = 'Alternative Versandadresse';
    public static String Kontoinhaber_ASP = 'ASP';
    public static String Kontoinhaber_PB = 'PB';
    
    public String layout{get; set;}
    public Boolean showAdditionalInfo {get; set;}
    public Boolean showBankdata {get; set;}
    public Boolean showSendingAddress {get; set;}
     
    public Opportunity opp {get; set;}
    public Contact cont {get; set;}
    
    public AdditionalInfoController(){
        showAdditionalInfo = false;
        showBankdata = false;
        showSendingAddress = false;
        layout = 'none';
    }
    
    // toAddress for Versandadressen
    // accountOwner and useBankData for BankDaten
    public Boolean start(Id oppId, String toAddress, String accountOwner, Boolean useBankData){
        
        if(toAddress == Produkte_sollen_versendet_werden_an){    
            showSendingAddress = true;
            List<Opportunity> opp_list = [select id,
                                                 Versandadresse_Anrede__c,
                                                 Versandadresse_Vorname__c,
                                                 Versandadresse_Name__c,
                                                 Versandadresse_Stra_e__c,
                                                 Versandadresse_Ort__c,
                                                 Versandadresse_PLZ__c
                                          from Opportunity
                                          where id = :oppId
                                          limit 1];
            if(opp_list != null && opp_list.size()>0){
                opp = opp_list[0];
            }
        }
        
        if(! String.isBlank(accountOwner) && useBankData){
            
            Id contactId;
            if(accountOwner == Kontoinhaber_ASP){
                List<OpportunityContactRole> contactRoleList = [select id,
                                                                      ContactId
                                                              from OpportunityContactRole 
                                                              where OpportunityId = :oppId
                                                                      and IsDeleted = false
                                                                      and (Role = :PLZTool_Basis.contactRoleContact
                                                                      or Role = :PLZTool_Basis.contactRoleSame )
                                                              limit 1];
                if( contactRoleList != null && contactRoleList.size()>0){
                    contactId = contactRoleList[0].ContactId;
                }
            }
            if(accountOwner == Kontoinhaber_PB){
                List<OpportunityContactRole> contactRoleList = [select id,
                                                                      ContactId
                                                              from OpportunityContactRole 
                                                              where OpportunityId = :oppId
                                                                      and IsDeleted = false
                                                                      and (Role = :PLZTool_Basis.contactRoleInsured
                                                                      or Role = :PLZTool_Basis.contactRoleSame )
                                                              limit 1];
                if( contactRoleList != null && contactRoleList.size()>0 ){
                    contactId = contactRoleList[0].ContactId;
                }
            }
            List<Contact> contact_list = [select Id, 
                                                 Kreditinstitut__c,
                                                 IBAN__c, 
                                                 BIC__c
                                         from Contact
                                         where Id = :contactId
                                         limit 1];
            if(contact_list != null && contact_list.size()>0){
                cont = contact_list[0];
                showBankdata = true;
            }
        }
        if(!showSendingAddress && !showBankdata){
            return false;
        }
        showAdditionalInfo = true;
        layout = 'initial';
        
        return true;       
    }
    
    public void saveAI(){
        if(showSendingAddress && opp!= null){
            update opp;
        }
        if(showBankdata && cont != null){
            update cont;
        }
    }
      
    public PageReference abbruch(){
        showSendingAddress = false;
        showBankdata = false;
        showAdditionalInfo = false;
        layout = 'none';
        
        return null;
    }
}