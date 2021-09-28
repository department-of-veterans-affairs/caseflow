---
title: Workflows
menu:
  navmenu:
    identifier: workflows
    collapsible: true
weight: 4
---

# Workflows

{{< pages_list >}}

## Workflows with respect to Data Model

### Case Distribution workflow
* Distribution, CaseDistribution, Task
* [Case Distribution tables diagram](https://dbdiagram.io/d/5f7928353a78976d7b763d6d)

### Judge and Attorney Checkout workflow
* RequestIssue, DecisionIssue, RequestDecisionIssue
* SpecialIssuesList
* JudgeCaseReview, AttorneyCaseReview
* [JudgeTeam Checkout tables diagram](https://dbdiagram.io/d/5f790c8f3a78976d7b763c75)

## Workflows that Create New Appeals

### Motion-To-Vacate workflow
* A PostDecisionMotion record is created with these possible [`dispositions`](https://github.com/department-of-veterans-affairs/caseflow/blob/a7af6b0742413eaa137e6e04e592e960ce136e6d/app/models/post_decision_motion.rb#L15-L21), the `vacated_decision_issue_ids` (which reference DecisionIssue records), and a `task_id` (which references a Task record, which is associated to an appeal).

### Docket Switch workflow (for AMA appeals)
* A DocketSwitch record is created with these possible [`dispositions`](https://github.com/department-of-veterans-affairs/caseflow/blob/1c0cf3417ebc050bee6045a7443a4660dbcd081b/app/models/docket_switch.rb#L15-L19) and list of `granted_request_issue_ids` (which reference RequestIssue records).
* Each DocketSwitch record references the original and new appeals via `old_docket_stream_id` and `new_docket_stream_id` respectively.
  * Both appeals have the same docket number and appellant.
  * The two appeals can have different docket type, request issues, tasks, etc.
* Why create a new appeal? See [this Google Doc](https://docs.google.com/document/d/1rHpGtoJmoAy0KBqUxzzxr7-0rEj1QLDACM6IFzNPNrA/edit#)
* [More Google docs](https://drive.google.com/drive/u/0/folders/1V9Q0s-YDdoRBi5qymouneRHfZcUUxi3u)

### CAVC Remand workflow (for AMA appeals)
* A CavcRemand record is created with [details from CAVC](https://github.com/department-of-veterans-affairs/caseflow/blob/13f4fdaee95342d392ec5b7a96b87d7b364232ea/db/schema.rb#L290-L293) and list of `decision_issue_ids` (which reference DecisionIssue records).
* Each CavcRemand record references the source and new appeals via `source_appeal_id` and `remand_appeal_id` respectively.
  * Both appeals have the same docket number and appellant. The new appeal has docket type = `court_remand`.
  * The two appeals can have different request issues, tasks, etc.
* [CAVC Remand wiki page](https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands)

### Appellant Substitution workflow (for AMA appeals)
* An AppellantSubstitution record is created with [details for creating the new appeal](https://github.com/department-of-veterans-affairs/caseflow/blob/13f4fdaee95342d392ec5b7a96b87d7b364232ea/db/schema.rb#L131-L141).
* Each AppellantSubstitution record references the source and new appeals via `source_appeal_id` and `target_appeal_id` respectively.
  * Both appeals have the same docket type, docket number, and request issues, but different appellant.
  * The request issues on the source appeal has associated decision issues with `death_dismissal` dispositions.
  * The two appeals can have different tasks, etc.
