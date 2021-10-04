# Tech Spec: Same-Appeal Substitutions

### Overview

Our existing logic for appellant substitutions creates a new appeal stream, the target appeal, which is separate from the original appeal stream, the source appeal.  We need to implement a new structure where the appeal remains the same when a substitution occurs, however, the appellant information changes from veteran to substitute.

Due to logistical reasons and metrics requirements, we need to maintain the existing functionality for death dismissal substitutions. Since the death dismissal completes the source appeal, it's logical to create a second appeal stream for the target appeal.

#### Services involved
- BGS: Where Caseflow retrieves POA information for all appellants, including substitute appellants
- CorpDB: the database that stores POA information


#### Relevant Issues/Epics
-[1702: Technical Research how to support Same-Appeal Substitutions](https://vajira.max.gov/browse/CASEFLOW-1702)

#### Stakeholder: Clerk of the Board (only Clerk of the Board users can do appellant substitutions)


### Considerations
- Death Dismissal Substitutions
- Existing Data in Production
- Front-end display of appellant substitution banners
- Determining if a substitution is a death dismissal

- Death Dismissal Substitutions
    - As previously noted, we need to maintain the existing functionality for death dismissal substitutions.  
    - We can do this by having validation methods that confirm if an appellant substitution is a death dismissal, and then ensuring that death dismissal substitutions use the existing functionality.
    - I don't think we'll need to have separate routes for the old and new functionality - we can distinguish between subsitution type at the model level.
- Existing Data in Production
    - There are only ten or eleven appellant substitutions already in production, and all of them are death dismissal appellant substitutions.
    - As a result, we don't have to do any data migration for existing substitution data.
- Front-end display of appellant substitution banners
    - The front-end conditionally renders alerts that indicate an appeal is an appellant substitution.
    - Some of this conditional logic will have to be adapted to fit the new same appeal substitution logic.
- Determining if a substitution is a death dismissal
    - Since we need to retain the existing flow for death dismissal substitutions, it's important that we reliably distinguish between death dismissal and non-death dismissal appellant substitutions.  I think we can draw this distinction based on decision issues' dispositions and the presence of a veteran date of death, but I will confirm this with other Echo team members.


### Non goals
- As previously noted, we won't have to do any migration for existing data in prod.
- As previously noted, we don't want to change the flow for death dismissal appellant substitutions.
- Even though the use of the term "appeal stream" is out of sorts with the more broadly accepted technical meaning of "stream," it is not in scope to change that terminology for this work.

### Implementation Options
#### Option 1: Use the Existing Appellant Substitution Code and Have The Appeal and Source Appeal Be the Same Appeal
The appellant substitution model states that the appellant substitution [belongs to a source appeal and target appeal](https://github.com/department-of-veterans-affairs/caseflow/pull/16786/files#diff-95a868016007a8bc1f2c36361ce09d7b360f79ce400d2e8c39f8ca2221af9865L7-L8), however, it does not require that these appeals be different entities.  I wrote [a unit test](https://github.com/department-of-veterans-affairs/caseflow/pull/16786/files#diff-38bc178f66ffdd5aabbd76beeff2c5035d6e35a3d6c6dd1f1f82070562cfdcb5R363) for a scenario where the source appeal and target appeal are the same appeal.  It passed!*
I propose that we use the existing approach, where an appellant substitution has both a source and target appeal, then make the source and target appeal point at the same appeal.  This way, we won't have to make as many changes to the existing codebase.  We should still review the front-end conditional rendering of appellant substitution alerts.
#### Option 2: Add a boolean trait, is_appellant_substitution, to the appeal model.
We can leave the existing appellant substitution model for death dismissal appellant substitutions, but take a different approach for non-death dismissal appellant substitutions.  First, we will add a new boolean field to the appeals table, `is_appellant_substitution`.  When a same appeal substitution occurs, in addition to updating the appellant information, we will set `is_appellant_substitution` to true.
I don't recommend this approach.  It would require us to change the logic for front-end conditional rendering of appellant substitution banners.  Additionally, the appeals table already has about 25 fields in it. I think it would be unwise to add an unnecessary field to this table, which is already fairly large.


### Recommendation
I recommend Option 1, using the existing appellant substitution code and having the appeal and source appeal be the same appeal.  I've already written a test to prove that this approach is sustainable.  Also, it doesn't require any changes to the database, and it would require minimal, if any, changes to the front-end logic around conditional rendering of alerts.

### Additional Options From Team Discussion of Tech Spec
TBA



`*` I want to acknowledge that other tests on the draft PR failed.  I didn't fix all of the breaking tests because I thought that would venture into actual implementation of the proposed change, which is not in scope for working on a tech spec.  A note on the failing tests: 24 tests failed, 1 of which was a bva dispatch return flow feature test that had already been marked as flaky.  The remaining 23 failing tests were appellant substitution model tests, which I expected to fail due to the change in model validations. I (Eileen) personally think the tests about task creation will be trickier to fix than the tests about AOD/CAVC status and copying issues to the target appeal, however, that may be a reflection of which area of the codebase I personally know better.

23 appellant substitution model tests