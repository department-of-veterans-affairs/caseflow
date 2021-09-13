---
parent: DB Schema
nav_order: 2
---

## Data Model &amp; Dictionary

This page provides information about Caseflow's data model, data dictionary, and resources to help understand Caseflow's database contents ([terminology](https://dataedo.com/blog/data-model-data-dictionary-database-schema-erd) and [example data-dictionaries](https://www.usgs.gov/products/data-and-tools/data-management/data-dictionaries)).
The main audience are Caseflow engineers, BVA's Reporting Team, those who know SQL, and onboarders.

This page consists of these major sections:
   * [By product](#by-product)
   * [By workflow](#by-workflow)
   * [By page](by-page)
   * (Feel free to add another section if desired)

Also check out [[Caseflow Database Schema Documentation]].

**Instructions:**
* Document any non-obvious semantics or logic that would be useful when interpreting database tables and constituent data.
   * Reference other relevant wiki pages to provide context/background.
   * Link to relevant code (in case it changes in the future).
* To create tables diagram, go to http://dbdiagram.io/, click "Import", and paste table definition excerpts from [`schema.rb`](https://github.com/department-of-veterans-affairs/caseflow/blob/master/db/schema.rb); then add cross-table links using the mouse and move the boxes around to your liking. Click "Save" and copy the URL to this page. 
   * Note: you can only import once; try it a couple of times to get a hang of it before spending too much time.
   * Table columns with `***` in the name are used to designate categories of columns. In the Certifications diagram, you will see a column titled `_initial ***` in the Form8s table. The Form8s table has twelve columns beginning with "_initial": `_initial_appellant_name`, `_initial_appellant_relationship`, etc. To keep the diagram and tables more tidy we grouped these categories together.  
   * Pro-tip: Open another browser tab, paste the new excerpt, then copy-and-paste the resulting Table definition into the original tab.
   * To insert a screenshot of the diagram, paste the image into a comment on [ticket #15510](https://github.com/department-of-veterans-affairs/caseflow/issues/15510), which will upload the image to GitHub and provide a URL for the image, which can then be linked from this page.

# By product

## Caseflow Certification
* [Certification tables diagram](https://dbdiagram.io/d/5fc6a0143a78976d7b7e2059)

### Certifications
Caseflow Certification ensures accurate Veteran and appeal information are transferred from the Veterans Benefits Administration (VBA) to the Board of Veterans Appeals (BVA). The Certifications table facilitates this process by ensuring necessary documentation has been submitted with an Appeal and is consistent between [VBMS](https://github.com/department-of-veterans-affairs/caseflow/wiki/Data%3A-where-and-why) and [VACOLS](https://github.com/department-of-veterans-affairs/caseflow/wiki/VACOLS-DB-Schema). Caseflow Certification is also responsible for verifying the veteran's representation and hearings request are accurate and ready to be sent to the Board. 
* `poa_correct_in_bgs`
* `poa_correct_in_vbms`
* `nod_matching`
* `soc_matching`
* `already_certified`

### Form8s
Once an Appeal has been certified, the information on a Form8 form will be sent to the Board and the representation and hearing information will be updated in VACOLS accordingly.
* `hearing_requested`
* `hearing_held`: `nil` if `hearing_requested` set to `No`
* `certification_date`
* `soc_date`

* `power_of_attorney` information pulled from [BGS](https://github.com/department-of-veterans-affairs/caseflow/wiki/Data%3A-where-and-why)

### LegacyAppeals
The [LegacyAppeals](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#legacyappeal) table stores records of non-AMA appeals, appeals which originated in VACOLS, that are worked by Caseflow. 
* `changed_request_type` is either the value of `R` representing a virtual hearing or `V` representing a video hearing. Those are the only two options when updating a hearing request
* `vbms_id` is either the Veteran's file number + "C" or the Veteran's SSN + "S"

### CertificationCancellations
The CertificationCancellations table stores instances of cancelled certifications.
* `cancellation_reason` can be one of the following:
   * `VBMS and VACOLS dates didn't match and couldn't be changed`
   * `Missing document could not be found`
   * `Pending FOIA request`
   * `Other`

### Relationships
In the diagram below you will see the `certifications` table's `id` is stored on the `certification_cancellations` table as well as the `form8s` table. 

The `form8s` table connects with the `certifications` table through the `certification_date`, `representative_name`, `representative_type`, and `vacols_id`, which also connects it with the `legacy_appeals` table. It is connected with a Veteran by storing the `veteran_file_number`. 

<br/>[<img src=https://user-images.githubusercontent.com/63597932/116123748-6468f180-a691-11eb-86bd-9dc6012f7be9.png>](https://user-images.githubusercontent.com/63597932/116123748-6468f180-a691-11eb-86bd-9dc6012f7be9.png)


## eFolder Express
* [eFolder Express tables diagram](https://dbdiagram.io/d/5ed6741c39d18f555300202a)

Caseflow eFolder Express (EE) serves the specific role of allowing users to bulk download all of a Veteran's files at once. It is the only Caseflow product that has a separate [code repository](https://github.com/department-of-veterans-affairs/caseflow-efolder) and runs on separate servers. 

### Records
When mentioning a Veteran's files in EE, those can vary between PDFs, TIFFs, and IMGs. The Records table exists to store references to these files

 
### Manifests
As mentioned above, the purpose of EE is to allow users to download all of a Veteran's files at once. The reasoning for this is to reduce the need for the user to select and download files individually. A `Manifest` represents the collection of all of a Veteran's files and consists of a `ManifestSource` for each file, pointing to its source. 

### ManifestSources
The sources for files made available for download in EE are [VBMS](https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/VA-API-services#vbms) and [Virtual VA (VVA)](https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/VA-API-services#vva). A `ManifestSource` groups a set of `Records` to allow all of a Veteran's files to be downloaded at the same time. 
* `name`: Either "VBMS" or "VVA"
* `status`: Stores whether a `Record` was successfully added to a `Manifest`

### FileDownloads
When a user searches for the Veteran they are looking for in EE, they are presented with a view of all files available for download. The FileDownloads table stores each time a user downloads all of a Veteran's files.

### Relationships
In the diagram below you can see that every `FileDownload` will store a `manifest_id`, as well as every `ManifestSource`. This makes sense given the fact that a `Manifest` is a collection of `ManifestSources`, with each `ManifestSource` containing a `Record`. The files indirectly referenced by a `Manifest` can be downloaded as many times as needed. 

  <br/>[<img src="https://user-images.githubusercontent.com/63597932/101203241-64137f80-3638-11eb-98b7-ebdc95a39533.png" width=800>](https://user-images.githubusercontent.com/63597932/101203241-64137f80-3638-11eb-98b7-ebdc95a39533.png)


## Caseflow Dispatch
* [Caseflow Dispatch](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Dispatch)
* [BVA Dispatch](https://github.com/department-of-veterans-affairs/caseflow/wiki/BVA-Dispatch)
* [Dispatch tables diagram](https://dbdiagram.io/d/5f790ba03a78976d7b763c6d)

Caseflow Dispatch exists to create [EndProducts](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#endproduct) in VBMS from completed cases in VACOLS. Users of Dispatch, VBA Office of Administrative Review (OAR) employees, are presented with VACOLS cases that have received a decision and need to be routed to the correct VBA entity to update a Veteran's benefits. 

### LegacyAppeals
The LegacyAppeals table is utilized by numerous Caseflow products. A [description](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Data-Model-and-Dictionary#legacyappeals) can be found above in the Certification section. 

### DispatchTasks
Caseflow [tasks](https://github.com/department-of-veterans-affairs/caseflow/wiki/Tasks) designate what action needs to be taken on an appeal and who is responsible for taking said action. There are a wide variety of tasks across Caseflow products, but the Dispatch::Tasks table currently only stores EstablishClaim task records which are used to create the EndProduct in VBMS. You can read more about tasks [here](https://docs.google.com/presentation/d/1Cc84GH7giWHTNxUe3zixH7O-QT77STlptYfud9X8P1Y/edit#slide=id.g5ee8a20194_1_406). 
* `aasm_state`
* `user_id` gets assigned upon clicking "Establish Next Claim" in Dispatch

### Users
[Caseflow users](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/roles/role-overview.md) are distinguished by their role, with different roles having different permissions and thus different capabilities made available to them. 
* `roles`: All of the user's roles
* `css_id`: A unique identifier for VA employees or contractors

### Relationships
In the diagram below, you will see that the `dispatch_tasks` tables stores the `id` of the `user` assigned to the task as well as the `id` of the `legacy_appeal`. The `legacy_appeals` tables does not store any `dispatch_task` `ids` because each appeal can have many `dispatch_tasks`.

<br/>[<img src="https://user-images.githubusercontent.com/63597932/116123231-c2e1a000-a690-11eb-9097-a8f48d223a0b.png" width=800>](https://user-images.githubusercontent.com/63597932/116123231-c2e1a000-a690-11eb-9097-a8f48d223a0b.png


## Caseflow Intake
* [Intake](https://github.com/department-of-veterans-affairs/appeals-team/wiki/Intake)
* [Caseflow Intake](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Intake)
* [Intake Data Model](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model)
* [Intake tables diagram](https://dbdiagram.io/d/5fc9027b3a78976d7b7e6700)

### Decision Reviews
Intake is the source of all AMA decision review request submissions. There are three decision review lanes: Appeals, HigherLevelReviews, and SupplementalClaims. 

Class diagram of relevant terminology:
* [DecisionReview](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#decisionreview)
   - [Appeal](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#appeal)
   - [ClaimReview](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#claimreview) 
      - [SupplementalClaim](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#supplementalclaim)
      - [HigherLevelReview](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#higherlevelreview)

#### Appeals
[Appeals](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#appeal) represent an AMA review that gets filed with the Board of Veterans' Appeals (BVA). Refer to Intake tables diagram below.
* `docket_type` can be one of the following:
   * `direct_review` - No new evidence and not requesting a hearing 
   * `evidence_submission` - New evidence but not requesting a hearing
   * `hearing` - Submit new evidence and want to testify before a VLJ
* `poa_participant_id`: Power of Attorney (POA) is connected to legacy appeals in VACOLS and Veterans in BGS. Since this model represents AMA appeals, we are getting this data from [BGS](https://github.com/department-of-veterans-affairs/caseflow/wiki/Data%3A-where-and-why)
* `veteran_is_not_claimant`: A claimant on an appeal does not have to be the Veteran. It can be a spouse, child, or even an attorney.

### Claim Reviews (i.e., HigherLevelReviews and SupplementalClaims)
A [HigherLevelReview](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#higher-level-review) and [SupplementalClaim](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#supplementalclaim) are a type of [ClaimReviews](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#claimreview). These ClaimReviews are sent to the Veterans Benefit Administration (VBA) and differentiate from Appeals in that they include a benefit type. Benefit types of `compensation` and `pension` are processed in VBMS, where as the rest are processed in Caseflow. 

### RequestIssues
[RequestIssues](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#requestissue) are submitted as part of a DecisionReview and represent a specific issue a Veteran is facing, such as hearing loss or sleep apnea. There are three categories of RequestIssues: `rating`, `non-rating`, and `unidentified`. 
 
### EndProductEstablishments
The [EndProductEstablishment](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#endproductestablishment) model exists in Caseflow to represent [EndProducts](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#endproduct) created in VBMS. End Products are created for Higher Level Reviews and Supplemental Claims that are compensation or pensions and for Board Grant Effectuations that have granted compensation and pension issues on appeals. 

### Relationships
In the diagram below you can see that the `appeals`, `supplemental_claims`, and `higher_level_reviews` table's `id` will correspond with the `request_issues` table's `decision_review_id` as well as the `end_product_establishments` table's `source_id`. 

Also note that the `request_issues` table's `id` is referenced by the `end_product_establishments` table. The `end_product_establishments` table's `source_type` is the same as the `request_issues` table's `decision_review_type`.

  <br/>[<img src="https://user-images.githubusercontent.com/63597932/116121937-223eb080-a68f-11eb-9625-fa9cca7c9201.png" width=800>](https://user-images.githubusercontent.com/63597932/116121937-223eb080-a68f-11eb-9625-fa9cca7c9201.png)


## Caseflow Hearings
* [Caseflow Hearings](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings)
* [Hearing Request Type](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#hearing-request-type)
* [Hearings tables diagram](https://dbdiagram.io/d/5f98b2073a78976d7b796fa2)

### Hearings
>
Veterans have the option to have a hearing with a Veterans Law Judge (VLJ) as part of the appeals process. At these hearings, a VLJ meets with a veteran or representative to go over the case. It is not a defense but a chance for a Veteran to provide additional details. After a hearing is conducted, the recordings are sent to the transcription office, and then entered into VBMS.
>
There are four types of hearings:
* Central Hearing: An in-person hearing at BVA's central office (425 I st.)
* Video Hearing: A hearing over video conference conducted between a regional office or alternate hearing location and central office
* Virtual Hearing: a hearing over video conference conducted between any location (sometimes the representative's office) and central office
* Travel Board: An in person hearing where the VLJ travels to the regional office. These are not currently supported by Caseflow and are handled in VACOLS. If Caseflow serves Travel Board hearings it will be only through converting them to video or virtual hearings.

### HearingDays
>
A `HearingDay` organizes `Hearings` and `LegacyHearings` by regional office and hearing room.
* A hearing day is assigned to one judge, although hearing coordinators have the ability to override the hearing day's judge on the [Hearings table](https://github.com/department-of-veterans-affairs/caseflow/blob/622210e52cff4b468385b2396bf4ca105546a04b/db/schema.rb#L628) or in [VACOLS](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/repositories/hearing_repository.rb#L177) by editing the [hearing details](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#for-hearing-coordinators).
* Each room / HearingDay has a maximum number of hearings that can be held (slots) that are determined by the regional office's [timezone](https://github.com/department-of-veterans-affairs/caseflow/blob/622210e52cff4b468385b2396bf4ca105546a04b/app/models/hearing_day.rb#L27-L39). If a hearing day's slots are filled, the coordinator will receive a warning when scheduling a Veteran ("You are about to schedule this Veteran on a full docket. Please verify before scheduling") but will still be able to schedule if they so choose.
* `request_type` : `R` for virtual, `V` for video, `C` for central
* `regional_office`: If the `request_type` is `V`, then the `HearingDay` will be associated to a regional office
* `judge_id`
* `scheduled_for`

### LegacyHearings
Legacy Hearings are hearings for cases that originated inside of VACOLS.  On a judge's Hearing Worksheet, they can edit Legacy hearing issues directly on the workbook page (for AMA cases, they would need to go to the Case Details page). 

### Task
All appeals on the hearing docket have a series of tasks that can be divided into five groups.  Here is a brief summary of what those are, full description can be found [here](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#hearings-task-model).
* Initial tasks - these include creating a `HearingTask` with a child `ScheduleHearingTask`. For AMA cases, the initial hearing tasks are created as a children of the `DistributionTask` after intake. For Legacy cases, a geomatching job finds all appeals in VACOLS that are ready to be scheduled and creates a hearing task tree as a child of the `RootTask`.
* Schedule Veteran tasks - schedule hearing tasks are shown on the assign hearings page (see this [page](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#hearings-pages-overview). A coordinator can block scheduling by adding a `HearingAdminActionTask` and can also withdraw the hearing.  After scheduling, a `AssignHearingDispositionTask` and a new hearing is created and that hearing is associated to the `HearingTask` with an `HearingTaskAssociation`.
* Assign a Disposition - Postponing cancels the current hearing task and recreates the initial hearing task tree. If a coordinator or judge changes the hearing's disposition on the daily docket, the `HearingDispositionChangeJob` finds all appeals with hearings in the last 24 hours and creates a `AssignHearingDispositionTask` and completes the task based on the disposition.  No-show hearings are given a `NoShowHearingTask`.
* Transcription/Evidence submission - After a disposition is assigned, AMA appeals must complete a `TranscriptionTask` and an `EvidenceSubmissionWindowTask`. The evidence task gives the Veteran an additional 90 days to submit evidence before the case is distributed.
* Case Distribution - When all other hearing tasks are completed, a case is ready for distribution to judge because its `DistributionTask` is moved from on_hold to assigned (AMA cases) or the case is in case storage location 81 (legacy cases). See also [automatic case distribution](https://github.com/department-of-veterans-affairs/caseflow/wiki/Automatic-Case-Distribution).

### VirtualHearings
Once a virtual hearing is scheduled, the associated record in `hearing_days` is not changed because a record in the `hearing_days` table represents the whole day. In other words, many hearing types are associated with that `hearing_days` record, so `hearing_days.request_type` should not be changed. This is an artifact of how the virtual hearings feature was introduced into Caseflow, i.e., as a conversion of video hearings into virtual hearings.
 
[`virtual_hearings`, `virtual_hearing_establishments`, and `sent_hearing_email_events` table descriptions](https://github.com/department-of-veterans-affairs/caseflow/issues/14067#issuecomment-620792309)

### Relationships
In the diagram below you can see the following relationships between various hearing-related tables:
* The `hearings` and `legacy_hearings` table's `id` corresponds with the `hearings_tasks_assocations` and `virtual_hearings` table's `hearing_id`.
* The `hearings` and `legacy_hearings` table's `hearing_day_id` corresponds with the `hearing_days` table's `id`.
* The `hearings_tasks_assocations` table's hearing_task_id corresponds with the `tasks` table's `id`.

<br/>[<img src="https://user-images.githubusercontent.com/63597932/105734269-760af380-5f00-11eb-8766-cc8fea5ba437.png">](https://user-images.githubusercontent.com/63597932/105734269-760af380-5f00-11eb-8766-cc8fea5ba437.png)


## Caseflow Queue
* [Caseflow Queue](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Queue)
  * [Organizations](https://github.com/department-of-veterans-affairs/caseflow/wiki/Organizations)
  * [Tasks](https://github.com/department-of-veterans-affairs/caseflow/wiki/Tasks)
    * [Tasks talk](https://github.com/department-of-veterans-affairs/caseflow/wiki/2019-12-04-Wisdom-Wednesday---Tasks-and-their-Trees)
* [Queue tables diagram](https://dbdiagram.io/d/5f790a8f3a78976d7b763c61)
  * Appeal, Task
  * User, OrganizationsUser, Organization, JudgeTeam organizations

### Appeals
Queue is the portion of Caseflow users utilize when an appeal has reached the [Decision](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/tasks-overview.md#decision-phase) phase and is ready to be reviewed by judges and attorneys for processing. Queue services both AMA and Legacy appeals, the behavior of each varying slightly. One of the main differences is that AMAs are contained within Caseflow whereas much of the data for Legacy appeals is extracted from [VACOLS](https://github.com/department-of-veterans-affairs/caseflow/wiki/VACOLS-DB-Schema).

### Tasks
User interaction with specific appeals is dependent on the type of task on the appeal that's been assigned to them. For instance, a [`JudgeAssignTask`](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/JudgeAssignTask_User.md) is given to a judge so that they may assign an [`AttorneyTask`](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/AttorneyTask_User.md) to an attorney on their team to draft a decision.

A more thorough breakdown of Queue tasks can be found in the Decision phase portion of the task tree [documentation](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/tasks-overview.md#decision-phase)

### Organizations
Users can be added to organizations so that we can control the types of permissions and task action options alotted to them.  For instance, [`JudgeTeams`](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/organizations/judge_team.rb) are comprised of a judge along with their team of attorneys.  This allows the judge to assign cases to these individuals in the same flow mentioned in the Task description.   

### Relationships
In the following diagram, you can see that an `id` on an AMA or Legacy appeal will correspond with the `appeal_id` on a task created on that appeal.  

An `assigned_by_id` or `assigned_to_id` will correspond with the `id` of the user who has either assigned or been assigned a task

Finally, `organization_users` is representative of a users relationship to a particular type of organization.  Therefore the users table's `id` will correspond with the `user_id` and the organizations table's `id` will correspond with the `organization_id`. 
  <br/>[<img src="https://user-images.githubusercontent.com/63597932/116123110-9c236980-a690-11eb-9482-add90c31e4f9.png">](https://user-images.githubusercontent.com/63597932/116123110-9c236980-a690-11eb-9482-add90c31e4f9.png)


## Caseflow Reader
* [Caseflow Reader](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Reader) and [Reader Backend](https://github.com/department-of-veterans-affairs/caseflow/wiki/Reader-Backend)
* [Reader tables diagram](https://dbdiagram.io/d/5ed6793d39d18f5553002077) 

### Documents
[Caseflow Reader](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Reader) allows users to access all of the documents related to the Veteran for an appeal. Users first interact with a *document list* page which presents a list of the documents.  Upon selection of a particular document, they are redirected to the *document view* page where they can view and interact with the document. Documents are populated by [eFolder](https://github.com/department-of-veterans-affairs/caseflow-efolder#caseflow---efolder-express), which retrieves them from two upstream dependencies: VBMS & VVA -- see [Reader Backend](https://github.com/department-of-veterans-affairs/caseflow/wiki/Reader-Backend) for details.  

### Annotations
On the document view page, users have the ability to add comments to documents via the "Add a comment" button.  A comment is stored in the `annotations` table.  Once a comment is created, it can be edited, shared via a link or deleted. In addition, comments can be seen on the document list page under the "Comment" column for the related document and also by selecting the "Comments" button which shows all comments.

### Tags
Tags can be added by the user to further label and categorize documents based on issues that they identify.  On the document view page, users may create a tag within the sidebar under the "Issue tags" dropdown section. Once a tag is created, it is saved (in the `tags` table) so that it is available for use on other documents.  Tags can also be deleted by the user.

### DocumentViews
Caseflow keeps track of when a user has viewed a document so the user is aware of which ones they have already opened.  To do this, documents in the document list are initially shown in bold text, however once a user has viewed a document, the text will no longer be bold. 

### Relationships
When a tag is created for a document, the user can apply it on other documents that may be relevant.  The `document_tags` table keeps track of which tags apply to which documents.  The `id` of the `tags` table corresponds to the `tag_id`, and the `id` of the documents table corresponds to the `documents_id`.

To track which document a comment/annotation is created for, the `id` from the `documents` table corresponds with the `document_id` on the `annotations` table.

To track when a document has been viewed by a user we have the `document_views` table, the `id` from the `documents` table corresponds with the `document_id` in the `document_views` table, and the `user_id` refers to the `id` in the `users` table.

<br/>[<img src="https://user-images.githubusercontent.com/55255674/97455894-54509f00-1906-11eb-8104-b409bc4d777a.png" height="600">](https://user-images.githubusercontent.com/55255674/97455894-54509f00-1906-11eb-8104-b409bc4d777a.png)

# By workflow

## Case Distribution workflow
* Distribution, CaseDistribution, Task
* [Case Distribution tables diagram](https://dbdiagram.io/d/5f7928353a78976d7b763d6d)

## Judge and Attorney Checkout workflow
* RequestIssue, DecisionIssue, RequestDecisionIssue
* SpecialIssuesList
* JudgeCaseReview, AttorneyCaseReview
* [JudgeTeam Checkout tables diagram](https://dbdiagram.io/d/5f790c8f3a78976d7b763c75)

## Motion-To-Vacate workflow
* A PostDecisionMotion record is created with these possible [`dispositions`](https://github.com/department-of-veterans-affairs/caseflow/blob/a7af6b0742413eaa137e6e04e592e960ce136e6d/app/models/post_decision_motion.rb#L15-L21), the `vacated_decision_issue_ids` (which reference DecisionIssue records), and a `task_id` (which references a Task record, which is associated to an appeal).

## Docket Switch workflow (for AMA appeals)
* A DocketSwitch record is created with these possible [`dispositions`](https://github.com/department-of-veterans-affairs/caseflow/blob/1c0cf3417ebc050bee6045a7443a4660dbcd081b/app/models/docket_switch.rb#L15-L19) and list of `granted_request_issue_ids` (which reference RequestIssue records).
* Each DocketSwitch record references the original and new appeals via `old_docket_stream_id` and `new_docket_stream_id` respectively.
  * Both appeals have the same docket number and appellant.
  * The two appeals can have different docket type, request issues, tasks, etc.
* Why create a new appeal? See [this Google Doc](https://docs.google.com/document/d/1rHpGtoJmoAy0KBqUxzzxr7-0rEj1QLDACM6IFzNPNrA/edit#)
* [More Google docs](https://drive.google.com/drive/u/0/folders/1V9Q0s-YDdoRBi5qymouneRHfZcUUxi3u)

## CAVC Remand workflow (for AMA appeals)
* A CavcRemand record is created with [details from CAVC](https://github.com/department-of-veterans-affairs/caseflow/blob/13f4fdaee95342d392ec5b7a96b87d7b364232ea/db/schema.rb#L290-L293) and list of `decision_issue_ids` (which reference DecisionIssue records).
* Each CavcRemand record references the source and new appeals via `source_appeal_id` and `remand_appeal_id` respectively.
  * Both appeals have the same docket number and appellant. The new appeal has docket type = `court_remand`.
  * The two appeals can have different request issues, tasks, etc.
* [CAVC Remand wiki page](https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands)

## Appellant Substitution workflow (for AMA appeals)
* An AppellantSubstitution record is created with [details for creating the new appeal](https://github.com/department-of-veterans-affairs/caseflow/blob/13f4fdaee95342d392ec5b7a96b87d7b364232ea/db/schema.rb#L131-L141).
* Each AppellantSubstitution record references the source and new appeals via `source_appeal_id` and `target_appeal_id` respectively.
  * Both appeals have the same docket type, docket number, and request issues, but different appellant.
  * The request issues on the source appeal has associated decision issues with `death_dismissal` dispositions.
  * The two appeals can have different tasks, etc.


## Appeals caching
(TBD)

## BGS caching
(TBD)

# By page

## Case Details page

### Power of Attorney
* [[Power of Attorney (POA)]]

Trace of POA lookup for LegacyAppeal
* First set `RequestStore.store[:application] == "queue"` because [POA lookup is different for different Caseflow apps](https://github.com/department-of-veterans-affairs/caseflow/blob/fde62ed5fe0a7410d2ed2cb8ff990f782d4455dd/app/models/legacy_appeal_representative.rb#L73-L78)
* Calling `LegacyAppeal#representative_name` calls `LegacyAppealRepresentative#representative_name`, which calls `PowerOfAttorney#bgs_representative_name`, which first looks in Caseflow and if needed queries BGS by using `BgsPowerOfAttorney` as follows:
  * `fetch_bgs_power_of_attorney || BgsPowerOfAttorney.new(file_number: file_number)`
    * `fetch_bgs_power_of_attorney` calls `fetch_bgs_power_of_attorney_by_file_number || fetch_bgs_power_of_attorney_by_claimant_participant_id`
    * `file_number` is the Veteran's file number -- [`#veteran_file_number`](https://github.com/department-of-veterans-affairs/caseflow/blob/58de93b39814b28a24c7a44f10f22b8ebfb82bfd/app/models/legacy_appeal.rb#L754-L771)
      * calls `sanitized_vbms_id` but if `veteran ||= VeteranFinder.find_best_match(sanitized_vbms_id)`, then uses `veteran.file_number`
      * `sanitized_vbms_id` calls `LegacyAppeal.veteran_file_number_from_bfcorlid(vbms_id)`
    * `claimant_participant_id` comes from `LegacyAppeal#claimant_participant_id`, which
      * checks `appellant_ssn` (from VACOLS `case_record.correspondent.ssn`), then looks up Person `Person.find_or_create_by_ssn(appellant_ssn)` for their `participant_id`.




