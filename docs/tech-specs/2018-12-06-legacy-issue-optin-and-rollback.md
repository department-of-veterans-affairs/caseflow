This document was moved from [appeals-team](https://github.com/department-of-veterans-affairs/appeals-team/blob/main/Project%20Folders/Caseflow%20Projects/Intake/Tech%20Specs/legacy-issue-optin-and-rollback.md).

# Legacy issue opt-in and rollback

## Context
We need to be able to opt in legacy issues into AMA, and if a user removes the issue from a Decision Review during edit, then we need to be able to rollback the legacy issue opt-in.  This document proposes how to handle the different types of legacy issues, and the objective is to come to identify an approach, particularly for remanded issues.

## Undecided issues
Undecided issues do not have a disposition code.  To opt it in, we will assign it a disposition code of "O".

If the issue's parent appeal no longer has any open issues, we will close the appeal.  This means that the appeal has no issues missing a disposition, and if it is in ACT status, it does not have issues that have dispositions 1-9 which can be draft dispositions, if it is in REM status, it does not have any issues with a disposition of "3" (more on remanded issues later).

To rollback, we will remove the disposition and disposition from the issue, and re-open the appeal if it is closed using the reopen_undecided_appeal logic.

## Issues with "whitelisted" dispositions
Some closed issues can still be opted-in.  These can have dispositions that are whitelisted.  These are currently planned to be the two "Failure to respond" dispositions, G and X.  We are going to check in with AMO to confirm that this satisfies their desire to be able to opt-in issues that are already closed, which we believe may be due to possible errors in VACOLS or with processing.

When a whitelisted issue is opted in, we will overwrite the current disposition with "O", and store the original disposition.  These are likely to be on an appeal that is already in HIS status.  However, if the appeal is still open, and after this change there are no more open issues on the appeal, we will close the appeal.

To rollback, we will revert the disposition from "O" back to the original disposition, and not re-open the appeal.

This requires overwriting the existing disposition.

## Remanded issues
We still need to determine how to approach remanded issues.  Here are three proposals.

### 1
Create a different follow up post-remand appeal for each issue closed (one appeal for each issue).  Store which post-remand appeal gets created for each issue.

If all of the issues on the appeal are closed, close the appeal.  This would mean that all of the issues on the appeal are closed, or if the issue has a disposition of "3", then it is associated with a post-remand appeal.

To rollback delete the post-remand appeal and its issue, re-open the original appeal with REM status if it has been closed.

We don't know if this is possible because the follow up appeals currently get the original appeal id, plus the "P", so we don't know if one original appeal can map to many post-remand appeals.

This may have the problem of the opted-in issue still appearing active on the original appeal.

### 2
Put the closed issue onto a post-remand appeal, store the issue's the new issseq.
If all issues on the original appeal are closed or if they have a disposition of "3" and they exist on the post-remand appeal (we'll need the new issseq to check), close the appeal.
To roll back, delete the follow up issue on the post-remand appeal. If the original appeal is closed, re-open it with REM status. If all issues on the follow up appeal are removed, delete the follow up appeal.

This may have the problem of the issue still appearing active on the original appeal.

We are also wondering if the issseq has to start with 1, instead of mapping directly to an issue's original issseq.

### 3
Overwrite the disposition on the original appeal from "3" to "O", store the original disposition.

If all of the issues on the original appeal are closed, meaning that all have a disposition that is not "3", create a post-remand appeal with all of the issues that were originally "3", with the disposition "O" on the follow up appeal. Revert the dispositions on the original appeal back to "3", and then close it.

To rollback a single issue that didn't close the appeal, change the "O" disposition back to "3". To rollback if the entire appeal got closed, re-open the original appeal to remand, convert the original dispositions back to "O" except for the rolled back issue which would stay at "3". Delete the follow up appeal and its issues.

This requires overwriting dispositions.
