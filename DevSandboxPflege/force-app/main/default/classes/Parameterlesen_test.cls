@isTest
private class Parameterlesen_test {

    static testMethod void myUnitTest() {
    	String s = Parameterlesenclass.read_string_param('admin');
    	System.assert(s == '');
        s = Parameterlesenclass.read_string_param('Administrator');
        decimal d = Parameterlesenclass.read_decimal_param('Liefertag');
        System.assert(d == 0);
        d = Parameterlesenclass.read_decimal_param('Liefertage vor Bedarf');
        String n = Parameterlesenclass.read_name_of_param('Admi');
        System.assert(n == '');
        n = Parameterlesenclass.read_name_of_param('Liefertage vor Bedarf');
    }
}