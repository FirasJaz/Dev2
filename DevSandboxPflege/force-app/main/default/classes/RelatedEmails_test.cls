/****************************************************************************************************************************
// Created 31.07.2018 von  MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Description:       
//	test class for "RelatedEmails"
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class RelatedEmails_test {

    static testMethod void getAllEmails(){
        
        // create an opportunity to test
        List<RecordType> oppRtList = [select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Opportunity' limit 1];
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId = oppRtList[0].Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Wanne zur Dusche';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        // create a ew message to test
        EmailMessage msg = new EmailMessage();
        //msg.ActivityId = emailTask.Id;
        msg.Incoming = true;
        msg.Subject = 'email subject';
        msg.Badumbau_inbound__c = true;
        msg.relatedToId = opp.Id;
        msg.toAddress = 'ziaei@klosesrockepartner.de';
        msg.textBody = 'email text body';
        msg.HtmlBody = 'email html body';
        msg.status = '0';
        insert msg;
        
        List<EmailMessage> emList = RelatedEmails.findAllEmailsByOppId(opp.Id);
        if(emList!= null && emList.size()>0){
			RelatedEmails.getAllEmailAttachments(emList[0].Id);
        }else{
            RelatedEmails.getAllEmailAttachments(msg.Id);
        }

    }
}