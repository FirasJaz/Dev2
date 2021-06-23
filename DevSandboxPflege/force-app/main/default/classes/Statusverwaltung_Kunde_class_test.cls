@isTest(SeeAllData=true)
private class Statusverwaltung_Kunde_class_test {  
    static testMethod void myTest1(){
        set<id> kdSet = new set<id>();
        set<id> kdSet2 = new set<id>();
        
        Kunde__c Kd1 = new Kunde__c( name__c ='testkunde1',
                                    produktgruppe__c = 'Inko');
        insert kd1;
        kdSet.add(kd1.id);
        Kunde__c Kd2 = new Kunde__c( name__c ='testkunde2',
                                    produktgruppe__c = 'PG51');
        insert kd2;
         kdSet.add(kd2.id);
        Kunde__c Kd3 = new Kunde__c( name__c ='testkunde3', e_mail__c = 'testKunde3@testtesttesttest.de',
                                    anrede__c = 'Herr', produktgruppe__c = 'PG54');
        insert kd3;
         kdSet.add(kd3.id);
         kdSet2.add(kd3.id);
        Kunde__c Kd4 = new Kunde__c( name__c ='testkunde4',
                                    produktgruppe__c = 'Shop');
        insert kd4;     
         kdSet.add(kd4.id);
         
        //Kunde__c kd5 = new Kunde__c( name__c ='testkunde5', e_mail__c = 'test@test.com',
                                //    anrede__c = 'Frau', produktgruppe__c = 'PG54');       
        
        //insert kd5;
        //kdSet2.add(kd5.id);  
        
        Statusverwaltung_Kunde_class.attachmentUpload(kdSet, 'PG54', 'Kandidat');
        Statusverwaltung_Kunde_class.updateKS(kdSet2,'Kandidat','PG54');              
    }
    
    static testmethod void myUnitTest2(){
       Mail_versenden_class.setKdRecipientFields('testStr', 'Curabox_ist_PG51_gew_nscht',
                                                   'Herr', 'Wolgang, Stefan');

       Mail_versenden_class.setKdRecipientFields('testStr', 'Curabox_ist_PG51_gew_nscht',
                                                   'Frau', 'Wolgang, null');    
                                                   
       Mail_versenden_class.setKdRecipientFields('testStr', 'Curabox_Ablehnung_kein_Pflegegrad',
                                                   'Frau', 'Wolgang, null');        
                                                   
       Mail_versenden_class.setKdRecipientFields('testStr', 'Curabox_Ablehnung_kein_Pflegegrad',
                                                   'Herr', 'Wolgang, null');   
                                                   
       Mail_versenden_class.setKdRecipientFields('testStr', 'Curabox_Ablehnung_anderer_LE',
                                                   'Herr', 'Wolgang, null'); 
                                                   
       Mail_versenden_class.setKdRecipientFields('testStr', 'Curabox_Ablehnung_anderer_LE',
                                                   'Frau', 'Wolgang, null'); 
                                                   
       Mail_versenden_class.setKdRecipientFields('testStr', 'Curabox_Ablehnung_keine_Pflegeperson',
                                                   'Herr', 'Wolgang, null'); 
                                                   
       Mail_versenden_class.setKdRecipientFields('testStr', 'Curabox_Ablehnung_keine_Pflegeperson',
                                                   'Frau', 'Wolgang, null');                                                                                                                                                                                                                                                                                                                                                                 
                                                   
    }    
}