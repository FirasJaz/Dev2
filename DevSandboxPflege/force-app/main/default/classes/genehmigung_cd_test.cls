@isTest
public class genehmigung_cd_test {

    static testMethod void testGen() {
       list<RecordType> fam_rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien']; 
        
        Account testFamilie = new Account(RecordTypeId = fam_rtList[0].id,
                                          Name = 'testFamilie');
                                          
        insert testFamilie;

        // contact
        Contact testContact = new Contact( 
                                    lastname = 'test_lastname',
                                    firstname = 'test_firstname',
                                    AccountId = testFamilie.Id,
                                    Email = 'test@test.de',
                                    Phone = '0123456789',
                                    MailingStreet = 'contactstreet',
                                    MailingPostalCode='23456',
                                    MailingCity='contactcity',
                                    
                                    Versicherungsnummer__c='VERSNR01234567',
                                    Birthdate=date.today().addYears(-60)
                                    //Art_Von_Handschuhe__c=p1.id
                                    );
        insert testContact;
        
        // Genehmigung
        Curabox_Genehmigung__c gen = new Curabox_Genehmigung__c(contact__c=testContact.id, Nach_Paragraph__c='54', kvnr_azh__c='1234');
        insert gen;  
        
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Genehmigung_PG54.pdf',
            PathOnClient = 'Genehmigung_PG54.pdf',
            //VersionData = Blob.valueOf('Test Content Data'),
            VersionData =  EncodingUtil.base64Decode(EncodingUtil.urlEncode('Unit Test Attachment Body','UTF-8')),
            FirstPublishLocationId = testContact.id
        );
    //  insert contentVersionInsert; 
//       ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
//        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId=testContact.id, ContentDocumentId=contentVersionSelect.ContentDocumentId, 
//                                            ShareType='I');
//        insert cdl;  
        
        id bid = database.executeBatch(new genehmigung_cd(), 1);
          
    } 

}