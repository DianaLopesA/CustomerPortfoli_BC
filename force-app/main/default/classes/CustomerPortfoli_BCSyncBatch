global class CustomerPortfolioAccessSyncBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, User__c, Customer__c, Source__c, ExternalId__c,
                   User__r.UserRoleId
            FROM Customer_Portfolio__c
            WHERE Source__c = 'External'
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Customer_Portfolio__c> externalRecords) {
        Map<Id, Set<Id>> customerToUsersMap = new Map<Id, Set<Id>>();

        for (Customer_Portfolio__c cp : externalRecords) {
            customerToUsersMap.putIfAbsent(cp.Customer__c, new Set<Id>());
            customerToUsersMap.get(cp.Customer__c).add(cp.User__c);
        }

        Map<Id, Id> userToRole = new Map<Id, Id>();
        Set<Id> roleIds = new Set<Id>();
        for (Customer_Portfolio__c cp : externalRecords) {
            userToRole.put(cp.User__c, cp.User__r.UserRoleId);
            roleIds.add(cp.User__r.UserRoleId);
        }

        Map<Id, Set<Id>> roleToManagersMap = buildRoleToManagersMap();

        List<Customer_Portfolio__c> toUpsert = new List<Customer_Portfolio__c>();
        List<Customer_Portfolio__c> toDelete = new List<Customer_Portfolio__c>();

        Set<Id> allManagerRoleIds = new Set<Id>();
        for (Id roleId : roleIds) {
            if (roleToManagersMap.containsKey(roleId)) {
                allManagerRoleIds.addAll(roleToManagersMap.get(roleId));
            }
        }

        Map<Id, List<User>> roleIdToUsers = new Map<Id, List<User>>();
        for (User u : [SELECT Id, UserRoleId FROM User WHERE UserRoleId IN :allManagerRoleIds AND IsActive = true]) {
            if (!roleIdToUsers.containsKey(u.UserRoleId)) {
                roleIdToUsers.put(u.UserRoleId, new List<User>());
            }
            roleIdToUsers.get(u.UserRoleId).add(u);
        }

        for (Customer_Portfolio__c ext : externalRecords) {
            Set<Id> managerRoleIds = roleToManagersMap.get(ext.User__r.UserRoleId);
            if (managerRoleIds == null) continue;

            for (Id managerRoleId : managerRoleIds) {
                for (User mgr : roleIdToUsers.get(managerRoleId)) {
                    String externalId = mgr.Id + '_' + ext.Customer__c;
                    toUpsert.add(new Customer_Portfolio__c(
                        User__c = mgr.Id,
                        Customer__c = ext.Customer__c,
                        Source__c = 'Internal',
                        ExternalId__c = externalId
                    ));
                }
            }
        }

        List<Customer_Portfolio__c> internalRecords = [
            SELECT Id, User__c, Customer__c, ExternalId__c
            FROM Customer_Portfolio__c
            WHERE Source__c = 'Internal'
        ];

        for (Customer_Portfolio__c cp : internalRecords) {
            Set<Id> subordinates = getAllSubordinateUsers(cp.User__c);
            Boolean hasAccess = false;
            for (Id sub : subordinates) {
                if (customerToUsersMap.get(cp.Customer__c)?.contains(sub) == true) {
                    hasAccess = true;
                    break;
                }
            }
            if (!hasAccess) {
                toDelete.add(cp);
            }
        }

        if (!toUpsert.isEmpty()) upsert toUpsert ExternalId__c;
        if (!toDelete.isEmpty()) delete toDelete;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('CustomerPortfolioAccessSyncBatch finished execution.');
    }

    private Map<Id, Set<Id>> buildRoleToManagersMap() {
        Map<Id, Set<Id>> roleHierarchy = new Map<Id, Set<Id>>();
        List<UserRole> allRoles = [SELECT Id, ParentRoleId FROM UserRole];
        Map<Id, UserRole> roleMap = new Map<Id, UserRole>(allRoles);

        for (UserRole role : allRoles) {
            Set<Id> ancestors = new Set<Id>();
            Id current = role.ParentRoleId;
            while (current != null) {
                ancestors.add(current);
                current = roleMap.get(current)?.ParentRoleId;
            }
            roleHierarchy.put(role.Id, ancestors);
        }
        return roleHierarchy;
    }

    private Set<Id> getAllSubordinateUsers(Id userId) {
        User u = [SELECT Id, UserRoleId FROM User WHERE Id = :userId];
        Set<Id> subordinateRoleIds = getChildRoles(u.UserRoleId);
        Set<Id> subordinates = new Set<Id>();

        for (User usr : [SELECT Id FROM User WHERE UserRoleId IN :subordinateRoleIds AND IsActive = true]) {
            subordinates.add(usr.Id);
        }
        return subordinates;
    }

    private Set<Id> getChildRoles(Id roleId) {
        Set<Id> childRoles = new Set<Id>();
        List<UserRole> allRoles = [SELECT Id, ParentRoleId FROM UserRole];

        Map<Id, List<Id>> parentToChildren = new Map<Id, List<Id>>();
        for (UserRole role : allRoles) {
            parentToChildren.putIfAbsent(role.ParentRoleId, new List<Id>());
            parentToChildren.get(role.ParentRoleId).add(role.Id);
        }

        collectChildRoles(roleId, parentToChildren, childRoles);
        return childRoles;
    }

    private void collectChildRoles(Id parentRoleId, Map<Id, List<Id>> parentToChildren, Set<Id> collector) {
        if (parentToChildren.containsKey(parentRoleId)) {
            for (Id childId : parentToChildren.get(parentRoleId)) {
                collector.add(childId);
                collectChildRoles(childId, parentToChildren, collector);
            }
        }
    }
}
