# CustomerPortfoli_BC
This solution automates customer access control based on the users' Role Hierarchy in Salesforce, using records in the `Customer_Portfolio__c` object.

## How to Test

1. Clone the repository
2. Authenticate using `sfdx auth:web:login`
3. Create or connect to an org
4. Deploy the source using `sfdx force:source:push`
5. Run the tests with `sfdx force:apex:test:run`

## Components

- `CustomerPortfolioAccessSyncBatch`: Main batch class
- `CustomerPortfolioAccessSyncBatchTest`: Unit tests
- `Customer_Portfolio__c`: Custom object containing access logic
