/****************************************************************************************************************************
// Erstellt 06.06.2019 von AD
//  					   Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//						   Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Lead
//
//****************************************************************************************************************************
//
// Beschreibung:
// Automatische Konvertierung von Curabox Leads zu Opportunities 
// Hinweis: Die automatische Konvertierung bezieht sich auf Mail Leads.             
//
//****************************************************************************************************************************
// Changes:
//
//****************************************************************************************************************************
*/
public with sharing class Curabox_Auto_Lead_Konvertierung {

    public static void convertLead (List<Lead> leadList){
        if (leadList != null && leadList.size()>0) {
            for (Lead lead : leadList) {
                if (!checkContact(lead)) {
                    insertFamilieAndContact(lead);
                }
            }
        }
    }

    public static void insertFamilieAndContact(Lead lead){
        Account familie = createNewFamilie(lead);
        Savepoint sp = Database.setSavepoint();
        try {
            insert familie;
        } catch (Exception e) {
            System.debug('Familie: ' + e);
        }
        if (familie.Id != null && !String.isEmpty(familie.Id)) {
            System.debug('#####################  Fam Alex D ######################');
            Contact contact = createNewContact(lead, familie);
            try {
                insert contact;
            } catch (Exception e) {
                Database.rollback(sp);
                System.debug('Contact: ' + e);
            }
            // insert Opportunity
            if (contact.Id != null && !String.isEmpty(contact.Id)) {
                System.debug('#####################  Con Alex D ######################');
                Opportunity opportunity = createNewOpportunity(lead, contact);
                try {
                    insert opportunity;
                } catch (Exception e) {
                    Database.rollback(sp);
                    System.debug('opportunity: ' +e);
                }
                // insert Contact Role
                if (opportunity.Id != null && !String.isEmpty(opportunity.Id)) {
                    System.debug('#####################  Role Alex D ######################');
                    OpportunityContactRole role = newContactRole(contact, opportunity);
                    try {
                        insert role;
                    } catch (Exception e) {
                        Database.rollback(sp);
                        System.debug('ContactRole: ' +e);
                    }
                    updateLead(lead, contact, familie);
                }
            }
        }else {
            Database.rollback(sp);
        }
    }

    public static Contact createNewContact(Lead lead, Account familie){
        Contact contact = new Contact();
        List<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name ='Familienangehörige' and sObjectType = 'Contact'];
        contact.Salutation = lead.Salutation;
        contact.FirstName = lead.FirstName;
        contact.LastName = lead.LastName;
        contact.Email = lead.Email;
        contact.Lead__c = lead.Id;
        contact.Art_des_Kontakts__c = 'Pflegebedürftige(r)';
        if (lead.OM_Wizzard_Name2__c != null) {
            contact.Ursprungsanfrage__c = lead.OM_Wizzard_Name2__c;
        }
        contact.AccountId = familie.Id;
        contact.RecordTypeId = rtList[0].Id;
        return contact;
    }

    public static Account createNewFamilie(Lead lead){
        List<RecordType> recordTypeList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];
         Account familie = new Account();
        if(recordTypeList != null && recordTypeList.size() != 0) {                   
            familie.Name = lead.LastName;
            familie.Familien_Name__c = lead.LastName;
            familie.RecordTypeId = recordTypeList[0].Id;
        }
        else {
            system.debug('Es wurde kein Recordtype für Familien gefunden !');
        }
        return familie;                             
    }

    public static Opportunity createNewOpportunity(Lead lead, Contact contact){
        Opportunity opportunity = new Opportunity();
        List<RecordType> recordTypList = [SELECT Id, sObjectType FROM RecordType WHERE Name = 'Curabox' and sObjectType = 'Opportunity'];
        opportunity.StageName = 'Offen';
        opportunity.Curabox_automatically_converted__c = true;
        opportunity.AccountId = contact.AccountId;
        opportunity.Lead_Date__c = date.newinstance(lead.CreatedDate.year(), lead.CreatedDate.month(), lead.CreatedDate.day());
        opportunity.CloseDate = date.today();
        // opportunity.N_chster_Schritt__c = lead.next_step__c;
        opportunity.Name = 'curabox_auto';
        if (lead.OM_Tracking_Order_ID__c != null && !String.isEmpty(lead.OM_Tracking_Order_ID__c)) {
            opportunity.OM_Tracking_Order_ID__c = lead.OM_Tracking_Order_ID__c;
        }
        if (lead.OM_Wizard_Version__c != null && !String.isEmpty(lead.OM_Wizard_Version__c)) {
            opportunity.OM_Wizard_Version__c = lead.OM_Wizard_Version__c;
        }
        if (lead.OM_Wizzard_Name2__c != null && !String.isEmpty(lead.OM_Wizzard_Name2__c)) {
            opportunity.CampaignId = lead.OM_Wizzard_Name2__c;
        }
        opportunity.RecordTypeId = recordTypList[0].Id;
        opportunity.Urspr_nglicher_Lead__c = lead.Id;

        return opportunity;
    }

    public static OpportunityContactRole newContactRole(Contact contact, Opportunity opportunity){
        OpportunityContactRole oppContactRole = new OpportunityContactRole();
        oppContactRole.ContactId = contact.Id;
        oppContactRole.OpportunityId = opportunity.Id;
        oppContactRole.Role = 'PB';
        oppContactRole.IsPrimary = true;
        return oppContactRole;
    }

    // salesfprce auto convert.
    public static void updateLead(Lead lead, Contact contact, Account familie){
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(lead.Id);
        leadConvert.setDoNotCreateOpportunity(true);
        leadConvert.setAccountId(familie.Id);
        leadConvert.setContactId(contact.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Qualified' LIMIT 1];
        leadConvert.setConvertedStatus(convertStatus.MasterLabel);
        Database.convertLead(leadConvert);

    }

    //
    public static Boolean checkContact(Lead lead){
        Boolean returnValue = false;
        List<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name ='Familienangehörige' and sObjectType = 'Contact'];     
        List<Contact> contactList = new List<Contact>();   
        if(rtList != null && rtList.size()>0){
            contactList = [select Id, Name
                                from Contact where ((Email =: lead.Email and Email != null) 
                                or (Phone=: lead.Phone and Phone != null) 
                                or (firstname =: lead.firstname and lastname =: lead.lastname and firstname != null and lastname != null)) 
                                and RecordTypeId =: rtList[0].Id];  
                                             
        }
        else {
            System.debug('Es wurde kein Recordtype für Familienangehörige gefunden !');
        }

        if(contactList != null && contactList.size() > 0) {
            returnValue = true;
        }
        return returnValue;
    }

}