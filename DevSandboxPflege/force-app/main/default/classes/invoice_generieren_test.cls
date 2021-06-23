@isTest
public class invoice_generieren_test {
    public static testMethod  void  myUnitTest(){
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde__Mansi', Produktgruppe__c = 'Shop');
        insert k;
        Auftrag__c a = new Auftrag__c();
        a.Kunde__c = k.Id;
        a.Magento_order_id_c__c = '12345';
        insert a;
        Auftragsposition__C ap = new Auftragsposition__C();
        ap.Auftrag__c = a.Id;
        insert ap;
		Lieferschein__c l = new Lieferschein__c();
        l.Kunde__c = k.Id;
        insert l;        
        Lieferscheinposition__c lp = new Lieferscheinposition__c();
        lp.Status__c = 'jetzt liefern';
        lp.Lieferdatum__c = date.today();
        lp.Lieferschein__c = l.Id;
        lp.Auftragsposition__c = ap.Id;
        lp.Kunde__c = k.Id;
        insert lp;        
        
        lp = new Lieferscheinposition__c();
        lp.Status__c = 'jetzt liefern';
        lp.Lieferdatum__c = date.today() - 1;
        lp.Lieferschein__c = l.Id;
        lp.Auftragsposition__c = ap.Id;
        lp.Kunde__c = k.Id;
        insert lp;        
        
        lp = new Lieferscheinposition__c();
        lp.Status__c = 'jetzt liefern';
        lp.Lieferdatum__c = date.today() - 5;
        lp.Lieferschein__c = l.Id;
        lp.Auftragsposition__c = ap.Id;
        lp.Kunde__c = k.Id;
        insert lp;        
        
        k = new Kunde__c(Name__c = 'Testkunde_shop_Mansi', Produktgruppe__c = 'Shop');
        insert k;
        a = new Auftrag__c();
        a.Kunde__c = k.Id;
        a.Magento_order_id_c__c = '23445';
        insert a;
        ap = new Auftragsposition__C();
        ap.Auftrag__c = a.Id;
        insert ap;
		l = new Lieferschein__c();
        l.Kunde__c = k.Id;
        insert l;        
        lp = new Lieferscheinposition__c();
        lp.Status__c = 'jetzt liefern';
        lp.Lieferdatum__c = date.today() - 4;
        lp.Lieferschein__c = l.Id;
        lp.Auftragsposition__c = ap.Id;
        lp.Kunde__c = k.Id;
        insert lp;

        lp = new Lieferscheinposition__c();
        lp.Status__c = 'jetzt liefern';
        lp.Lieferdatum__c = date.today() - 12;
        lp.Lieferschein__c = l.Id;
        lp.Auftragsposition__c = ap.Id;
        lp.Kunde__c = k.Id;
        insert lp;
        
        invoice_generiren ig = new invoice_generiren(l.Id);
             
    }     
}