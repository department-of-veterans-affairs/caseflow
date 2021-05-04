# Death Dismissal Task Blocking

### Jira Epic
 - [Caseflow-656: Distribution & Processing appeals for Deceased Veterans identified during Intake](https://vajira.max.gov/browse/CASEFLOW-656)

## Background

The ability to intake AMA forms for deceased veteran appellants was unblocked in Caseflow Intake for Board Appeals in December, 2020 [GitHub Pull Request](https://github.com/department-of-veterans-affairs/caseflow/pull/15718).  This feature notifies the intake user that the veteran is deceased, and allows them to proceed. Once the claim is intaken, tasks are created depending on factors like docket type.

A Direct Review docket without a VSO Informal Hearing Presentation is available for distribution and can immediately go through the regular judge checkout flow. Evidence submission dockets first have to wait until 90 days after the receipt date to allow for additional evidence to be submitted and received before continuing.  Hearing dockets first get a hearing scheduled and held before being distributed to the judge checkout flow.

When a veteran is deceased, the Board would like to reduce the delays added by these additional tasks so that the case can proceed directly to a death dismissal decision after confirming the veteran's death.

## Current behavior
When an AppealIntake is completed, it uses `create_tasks_on_intake_success!` to do the following:
 - InitialTasksFactory.new(self).create_root_and_sub_tasks!
 - create_business_line_tasks!
 - maybe_create_translation_task

The Business Line tasks are for receiving relevant tasks from other lines of business connected to issues on the appeal. For example, if there was an education issue, the Education line of business would send over the veteran's documents to the Board.

The translation task creates a Translation Task, depending on whether the veteran's state code is in STATE_CODES_REQUIRING_TRANSLATION_TASK.

The InitialTaskFactory workflow handles several things, including (but not limited to):
 - Creates the Root Task and Distribution Task for all appeals upon intake completion
 - If the claimant has a VSO, it creates the TrackVeteranTask which allows the VSO to access the veteran's records
 - It creates an InformalHearingPresentationTask for the VSO if the VSO is configured to have IHPs.
- If the appeal is a direct review docket and does not have IHP tasks, it gets marked as ready for distribution
 - It creates additional tasks for the Evidence Submission and Hearing dockets

Appeals that are ready for distribution upon intake:
 - Direct review docket
 - Does not have an InformalHearingPresentationTask

Appeals that are not ready for distribution upon intake:
 - Evidence submission or hearing dockets
 - Appeals with a VSO who performs informal hearing presentations

## Goals
Reduce processing timelines for death dismissals by allowing appeals with a deceased veteran claimant to get distributed and proceed to the judge checkout flow without tasks that are no longer needed to process a death dismissal.

## Proposed updates
The proposal is for appeals with deceased veteran claimant to be immediately ready for distribution by a judge so that it can be processed as a death dismissal. The veteran's death must first be verified and confirmed by a VLJ, and if it is determined that the veteran has not passed away, the appeal would be re-docketed.  This work has been scoped to the next phase can be found in [Jira Epic 1321: Redocketing Appeals where the Veterans Death may have been wrongly indicated during Intake](https://vajira.max.gov/browse/CASEFLOW-1321).

Certain tasks would still be needed for processing, including the Business Line tasks for getting the veteran's documentation from other lines of business, and the Translation task for veteran's with a state code indicating that translation would be required.

**Tasks to block _if the veteran has a date_of_death present_:**
 - EvidenceSubmissionWindowTask
 - ScheduleHearingTask
 - InformalHearingPresentationTask

## Approach
Due to uncertainty and unfamiliarity with the task tree and appeals processing flow, the team decided to start this Epic with additional testing and research, including research on the next phase of re-docketing appeals if they were intaken as a deceased veteran claimant, but upon review are determined to not be deceased.

### Jira Issues

#### Testing
See [Processing death-dismissed appeals](https://docs.google.com/document/d/1T8J53ZtrbWWaUSbTAiIzNHKFeUpTJsvu5_SdXH9RRr0/edit#) for testing documentation.

 - [Caseflow-1329: Mock Blocking of Tasks](https://vajira.max.gov/browse/CASEFLOW-1329)
   - Confirms a way to mimic the blocking of these tasks to test if we can proceed through the judge checkout flow
 - [Caseflow-925: VLJ Distribution Task](https://vajira.max.gov/browse/CASEFLOW-925)
   - Tests that the appeal is ready for distribution and the judge can assign the case to an attorney
 - [Caseflow-927: Attorney Decision Draft Task](https://vajira.max.gov/browse/CASEFLOW-927)
  - Tests that the assigned attorney can submit a draft decision
 - [Caseflow-929: VLJ Decision Review Task](https://vajira.max.gov/browse/CASEFLOW-929)
   - Tests that the judge can submit the decision and complete judge checkout, sending the appeal to be dispatched

#### Engineering

 - [Caseflow-895: Claims with date of death to have docket tasks creation blocked when intaken](https://vajira.max.gov/browse/CASEFLOW-895)
   - Engineering implementation of task blocking

## Risks
In rare edge cases, the veteran may have a date of death in the Corporate Database, but may not actually be deceased. If the veteran's date of death is removed, we do not currently have a way to detect what the veteran's date of death was at the time of intake. However, we would be able to detect whether an appeal intake was processed this way by comparing the docket type to the task tree for the Evidence Submission and Hearing docket types.

This behavior will also happen not during intaken when the InitialTaskFactory is used. This is one potential area for side effects. One current example is when creating tasks on a new appeal stream for a Motion to Vacate.
