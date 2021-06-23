@isTest
public class Notification_Leads_anzeigen_test {

    static testMethod void leads_anzeigen_test() {
        Notification_Leads_anzeigen nl = new Notification_Leads_anzeigen();
        List<Lead> ll = nl.LDlist;
        Integer i = nl.noOfRecords;
        i = nl.size;
        String s = nl.message_layout;
        s = nl.LD;
        s = nl.message;
   }
   
   static testMethod void leads_anzeigen_TL_test() {
        Notification_Leads_anzeigen_TL nl = new Notification_Leads_anzeigen_TL();
        List<Lead> ll = nl.LDlist;
        Integer i = nl.noOfRecords;
        i = nl.size;
        String s = nl.message_layout;
        s = nl.LD;
        s = nl.message;
   }
   
   static testMethod void leads_anzeigen_BEL_test() {
        Notification_Leads_anzeigen_BEL nl = new Notification_Leads_anzeigen_BEL();
        List<Lead> ll = nl.LDlist;
        Integer i = nl.noOfRecords;
        i = nl.size;
        String s = nl.message_layout;
        s = nl.LD;
        s = nl.message;
   }
   
   static testMethod void leads_anzeigen_HNR_test() {
        Notification_Leads_anzeigen_HNR nl = new Notification_Leads_anzeigen_HNR();
        List<Lead> ll = nl.LDlist;
        Integer i = nl.noOfRecords;
        i = nl.size;
        String s = nl.message_layout;
        s = nl.LD;
        s = nl.message;
   }
   
   static testMethod void leads_anzeigen_PI_test() {
        Notification_Leads_anzeigen_PI nl = new Notification_Leads_anzeigen_PI();
        List<Lead> ll = nl.LDlist;
        Integer i = nl.noOfRecords;
        i = nl.size;
        String s = nl.message_layout;
        s = nl.LD;
        s = nl.message;
   }
   
   static testMethod void leads_anzeigen_WS_test() {
        Notification_Leads_anzeigen_WS nl = new Notification_Leads_anzeigen_WS();
        List<Lead> ll = nl.LDlist;
        Integer i = nl.noOfRecords;
        i = nl.size;
        String s = nl.message_layout;
        s = nl.LD;
        s = nl.message;
   }
    
   static testMethod void leads_anzeigen_Bad_test() {
        Notification_Leads_anzeigen_BAD nl = new Notification_Leads_anzeigen_BAD();
        List<Lead> ll = nl.LDlist;
        Integer i = nl.noOfRecords;
        i = nl.size;
        String s = nl.message_layout;
        s = nl.LD;
        s = nl.message;
   }
}