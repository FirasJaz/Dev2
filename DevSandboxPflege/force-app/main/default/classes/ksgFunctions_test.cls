@isTest
private class ksgFunctions_test {

    static testMethod void myUnitTest() {
        string mon = ksgFunctions.getMonat();
        mon = ksgFunctions.getMonat(1);
        mon = ksgFunctions.getMonat(2);
        mon = ksgFunctions.getMonat(3);
        mon = ksgFunctions.getMonat(4);
        mon = ksgFunctions.getMonat(5);
        mon = ksgFunctions.getMonat(6);
        mon = ksgFunctions.getMonat(7);
        mon = ksgFunctions.getMonat(8);
        mon = ksgFunctions.getMonat(9);
        mon = ksgFunctions.getMonat(10);
        mon = ksgFunctions.getMonat(11);
        mon = ksgFunctions.getMonat(12);
        
        string zahl = ksgFunctions.formatCurrency(1.99);
        zahl = ksgFunctions.formatCurrency(-1.99);
        
        ksgFunctions.selectMonate();
        decimal d = 22303;
        ksgFunctions.formatPLZ(d);
        
        ksgFunctions.addr testAddress = new ksgFunctions.addr();
        testAddress.anrede = 'Herr';
        testAddress.nachname = 'ziaei';
        testAddress.Anredeformelsetzen();
        testAddress.anrede = 'Frau';
        testAddress.nachname = 'ziaei';
        testAddress.Anredeformelsetzen();
        
    }
}