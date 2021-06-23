@IsTest
private  class ContactStatusTriggerHandler_Test {
    public static Id ACCOUNT_RECORDTYPEID_03_KOSTENTRAEGER =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('X03_Kostentr_ger').getRecordTypeId();
    public static Id CONTACT_RECORDTYPEID_FAMILIENANGEHOERIGE =  Schema.SObjectType.CONTACT.getRecordTypeInfosByDeveloperName().get('Familienangeh_rige').getRecordTypeId();
    public static Id OPPORTUNITY_RECORDTYPEID_CURABOX =  Schema.SObjectType.OPPORTUNITY.getRecordTypeInfosByDeveloperName().get('Curabox').getRecordTypeId();
    @TestSetup
    public static void setupTestdata() {
     //create Pflegekasse gesetzlich Account
      Account KK = new Account(name='Testpflegekasse', Industry = 'Krankenkassen', type = 'Test');
      KK.RecordTypeId = ACCOUNT_RECORDTYPEID_03_KOSTENTRAEGER;
      KK.IK_Nummer__c = '12345678';
      KK.Kanal_Unterpunkt__c = 'gesetzlich';
      KK.PG51_Abrechnungs_Methode__c = '10% Zuzahlung';
      KK.Hilfsmittel_Kennzeichen__c = 'HM';     
      KK.AC__c = 'AC';
      KK.TK__c = 'TK';   
      KK.Medifox_Ausschluss__c = false;
      KK.BillingStreet = 'Teststrasse';
      KK.Billingcity = 'Testort';
      KK.BillingPostalCode = '12345';
      KK.Fax = '04012345678';
      insert KK;
     //Create Contact
     Contact testContact = new Contact( 
                                RecordTypeId = CONTACT_RECORDTYPEID_FAMILIENANGEHOERIGE,
                                lastname = 'MustermannTest' ,
                                firstname = 'testfirstname',
                                AccountId = kk.id,
                                Email = 'test'  + '@test.de',
                                Phone = '0123456789',
                                MailingStreet = 'contactstreet',
                                MailingPostalCode='23456',
                                MailingCity='contactcity',
                                Kranken_Pflegekasse__c=KK.id,
                                Versicherungsnummer__c='VERSNR01234567',
                                Birthdate=date.today().addYears(-60),
                                Art_des_Kontakts__c = 'Pflegebedürftige');
     insert testContact ;
     
     //Create Opportunity
     opportunity opp = new opportunity();
     opp.name = 'CuraboxOpp';
     opp.accountid = kk.id;
     opp.OM_Referrer__c ='Curabox';
     opp.RecordTypeId =OPPORTUNITY_RECORDTYPEID_CURABOX;
     opp.StageName = 'Closed Won';          
     opp.CloseDate = date.today();
     insert Opp ;
     //Create Orders 
     List<Order__c> orders = new List<Order__c>();
     Order__c order1 = new Order__c(Opportunity__c=opp.id);
    order1.Contact__c=testContact.id;
    order1.Status__c = Constants.ORDER_ENDED_STATUS;
    order1.Liefertag__c = date.today();
    order1.Nach_Paragraph__c = '51'; 
    order1.Delivery_frequency__c = 'jährlich';
    order1.Description__c = 'KUWV'; 
    orders.add(Order1);
    Order__c order2 = new Order__c(Opportunity__c=opp.id);
    order2.Contact__c=testContact.id;
    order2.Status__c = Constants.ORDER_PAUSED_STATUS;
    order2.Liefertag__c = date.today();
    order2.Nach_Paragraph__c = '54'; 
    order2.Delivery_frequency__c = 'monatlich';
    Orders.add(Order2);
    insert Orders ;                   


    }


    @isTest
    static void PreventStatusCancellationToUpdate_NoActiveOrders_UpdateOfStatus()  {
    //SETUP
     Contact c = [select Status__c from contact where lastname='MustermannTest' limit 1 ];
     contact_status__c cs = new contact_status__c(Contact__c = c.id);
     cs.Status__c = 'Interessent';
     cs.Productgroup__c ='PG54';
     cs.delivery_address__c = 'customer address';
     insert cs ;    
    // ACTION
    Test.startTest();
    cs.Status__c = Constants.CONTACT_KUENDIGUENG_STATUS ;
    update cs ;
    Test.stopTest();
    // VERIFY
    System.assertEquals(cs.Status__c, Constants.CONTACT_KUENDIGUENG_STATUS, 'Can not Update the Status of Contact');

    }

    @isTest
    static void PreventStatusCancellationToUpdate_ActiveOrders_PreventUpdateOfStatus()  {
    //SETUP
     Contact c = [select Status__c from contact where lastname='MustermannTest' limit 1 ];    
     contact_status__c cs = new contact_status__c(Contact__c = c.id);
     cs.Status__c = 'Interessent';
     cs.Productgroup__c ='PG51';
     cs.delivery_address__c = 'customer address';
     insert cs ;    
    
     Order__c order =[select status__c from Order__c where Nach_Paragraph__c ='54'];
     order.status__c =Constants.ORDER_ACTIVE_STATUS;
     update order ;
    // ACTION
     cs.Status__c = Constants.CONTACT_KUENDIGUENG_STATUS ;
    try{
    update cs ;
    }
    catch(Exception e){
    // VERIFY
    System.AssertEquals(e.getMessage().contains(System.Label.Status_Cancellation_Contact_Error), true);
        
    }
    

    }
    
}