@isTest
public class after_update_delivery_note_Test {

    static testMethod void UnitTest(){
        Contact contact = new Contact(LastName ='Alex');
        insert contact;
        Delivery_Note__c dn = new Delivery_Note__c(Contact__c = contact.id);
        insert dn;
        curabox_genehmigung__c g1 = new curabox_genehmigung__c(Contact__c = contact.id, Nach_Paragraph__c = '5X', Status__c = 'Bewilligung', unbefristet_genehmigt__c = true);
        insert g1; 
        delivery_line__c dl = new delivery_line__c (contact__c = contact.id, delivery_note__c = dn.id);
        insert dl;
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Ablieferbeleg_DN.pdf',
            PathOnClient = 'Ablieferbeleg_DN.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        contentVersionInsert.FirstPublishLocationId =dn.Id;
        insert contentVersionInsert;
    }

}