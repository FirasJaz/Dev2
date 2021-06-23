@isTest
public class customLookUpController_test {
    @isTest static void testFetchLookUpValues(){
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;
        customLookUpController.fetchLookUpValues('Test', 'Account');
    }
}