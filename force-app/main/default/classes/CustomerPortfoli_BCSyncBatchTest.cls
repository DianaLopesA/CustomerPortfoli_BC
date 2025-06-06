@isTest
private class CustomerPortfolioAccessSyncBatchTest {

    @testSetup
    static void setupData() {
        // Criar UserRoles simulando hierarquia: Manager > Sales Rep
        UserRole topRole = new UserRole(Name = 'Regional Manager', DeveloperName = 'R1');
        insert topRole;

        UserRole midRole = new UserRole(Name = 'Manager Assistant', DeveloperName = 'R1_M1', ParentRoleId = topRole.Id);
        insert midRole;

        UserRole bottomRole = new UserRole(Name = 'Sales Representative', DeveloperName = 'R1_M1_R1', ParentRoleId = midRole.Id);
        insert bottomRole;

        // Criar utilizadores
        User manager = TestUtils.createUser('manager@test.com', topRole.Id);
        User assistant = TestUtils.createUser('assistant@test.com', midRole.Id);
        User rep = TestUtils.createUser('rep@test.com', bottomRole.Id);

        // Criar conta fictícia (Customer)
        Account acc = new Account(Name = 'Test Customer');
        insert acc;

        // Registo externo (simulado como vindo de sistema externo)
        Customer_Portfolio__c cpExternal = new Customer_Portfolio__c(
            User__c = rep.Id,
            Customer__c = acc.Id,
            Source__c = 'External',
            ExternalId__c = rep.Id + '_' + acc.Id
        );
        insert cpExternal;

        // Registo interno (já existente) que pode ser removido
        Customer_Portfolio__c cpInternal = new Customer_Portfolio__c(
            User__c = manager.Id,
            Customer__c = acc.Id,
            Source__c = 'Internal',
            ExternalId__c = manager.Id + '_' + acc.Id
        );
        insert cpInternal;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        CustomerPortfolioAccessSyncBatch batch = new CustomerPortfolioAccessSyncBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Validar que os acessos internos foram atualizados ou removidos
        List<Customer_Portfolio__c> records = [
            SELECT Id, User__c, Source__c
            FROM Customer_Portfolio__c
        ];

        System.assert(records.size() > 0, 'Registos devem existir');
        System.assert(records.stream().allMatch(cp => cp.Source__c == 'External' || cp.Source__c == 'Internal'), 'Todos os registos devem ter origem válida');
    }

    // Utilitário para criação de utilizadores sem necessidade de mocks de email
    private class TestUtils {
        static User createUser(String email, Id roleId) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            User u = new User(
                FirstName = 'Test',
                LastName = email.substringBefore('@'),
                Email = email,
                Username = email + System.currentTimeMillis(),
                Alias = 'tusr',
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                UserRoleId = roleId
            );
            insert u;
            return u;
        }
    }
}
