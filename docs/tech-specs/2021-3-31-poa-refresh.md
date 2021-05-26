## Context
Dating back to at least August 2020 (according to the original issue), we have been receiving reports from BVA users that POA data in Caseflow is out of date with respect to the POA data stored in the corpDB.  It seems that users are entering updated POA information into VBMS and expecting to see that information immediately reflected in Caseflow.  Instead what users are seeing is the POA information that has been [cached](https://github.com/department-of-veterans-affairs/caseflow/blob/4e042c15144e926ec065e4e4869ca236158690ff/db/schema.rb#L178) in the Caseflow Postgres DB.

#### Services involved
- **VBMS**: where users are entering updated POA information
- **BGS**: the API Caseflow interacts with to retrieve POA information
- **corpDB**: the DB that stores POA information that BGS retrieves

#### Relevant Issues/Epics
- [Original issue](https://github.com/department-of-veterans-affairs/caseflow/issues/14974)
- [Epic](https://vajira.max.gov/browse/CASEFLOW-42)  

#### Stakeholder: BVA
## Overview

We need to provide more updated POA information to BVA users.  After consultation with the stakeholder we have agreed upon a two pronged approach:
1. Add a new POA update job or update an existing job to better reflect POA records in the corpDB.
2. Implement the ability for users to initiate a POA update on the Case Details page via a button to be added to the POA section.

## Considerations
We'll want to consider several factors when creating the job in order to maximize the effectiveness:
#### 1. Distributed vs Undistributed appeals
In the context of Queue, appeals can be framed as either distributed or undistributed.  Distributed appeals have been assigned to a user and are ready to be worked, whereas undistributed appeals have completed Intake but are yet to be assigned.  We should prioritize updating POAs of distributed appeals.

#### 2. Priority consideration
We should update the records of appeals based on how we prioritize the distribution of appeals. That way the updates of the POA records should somewhat coincide with the appeals that are more likely to be worked first by users.

Prioritization for the distribution of appeals is based on their type, currently that prioritization is as follows:
- CAVC AOD cases
- AOD cases
- CAVC cases
- remaining cases prioritized by docket number

To determine priority of distributed appeals, we can reference the [`priority`](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/db/schema.rb#L461) boolean on the `distributed_cases` table

Undistributed appeals are on dockets awaiting distribution, for AMA those dockets are Direct Review, Evidence Submission & Hearing Request. All 3 of the respective models for these dockets are subclasses of the `Docket` model which has a [`priority`](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/app/models/docket.rb#L106) method we can utilize to determine priority status.

Legacy cases belong to a single docket.  This `VACOLS::CaseDocket` model has a [`priority_ready_appeal_vacols_ids`](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/app/models/vacols/case_docket.rb#L276) method to determine their priority status. 
#### 3. When was the POA last updated
We should also take into consideration the last time that the POA record was updated, which we track on the `bgs_power_of_attorneys` table with [`last_synced_at`](https://github.com/department-of-veterans-affairs/caseflow/blob/4e042c15144e926ec065e4e4869ca236158690ff/db/schema.rb#L194).  If we have synced the record in the last 16 hours it is most likely unnecessary to re-update the record. #15538 
### Non goals
Removing non-existent POA records
There is a related issue currently where we are not removing POA records that come back as `not_found` from the BGS.  We should update our logic to remove the POA record from the Caseflow DB if it does (originally noted in [#15043](https://github.com/department-of-veterans-affairs/caseflow/issues/15043)).  It would be a "nice to have" but probably technically out of scope here as we still have yet to identify exactly what the cause is.
## Implementation Options
### Option 1: Update PushPriorityAppealsToJudgesJob (focused on updating _distributed_ cases)
This would be a weekly job that targets the appeals that have been distributed from the `PushPriorityAppealsToJudges` job.  As mentioned in the priority consideration section we have the ability to filter distributed cases by priority.  _However_, it would seem logical to also refresh the POAs of the non-priority distributions at this point as well as there is no extra lift (simply don't filter for priority) and a non-priority distributed appeal still has a high likelihood of being worked by a user.

For this approach we can grab the ids of the distributed cases and locate the POA record to update.   This can be achieved by locating the veteran file number associated with the appeal and then using BgsPowerOfAttorney's [`find_or_create_by_file_number`](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/app/models/bgs_power_of_attorney.rb#L34).

To get a sense of how many POA updates would be completed taking this path, there was a total of 1850 appeals distributed by PushPriorityAppealsToJudgesJob over the course of the previous month (ran 5 times every Monday 3/8 - 4/5) averaging to 370 every time the job ran.   

A similar approach was taken as part of the FNOD effort in [this](https://github.com/department-of-veterans-affairs/caseflow/pull/15772/files) PR when updating veteran attributes

### Option 2: Update the WarmBgsCachesJob (focused on updating _undistributed_ cases)

WarmBgsCachesJob runs nightly. Currently we update our POA caches based on a few factors, those being:
- [priority hearings](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/app/jobs/warm_bgs_caches_job.rb#L71)
- [most recent hearings](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/app/jobs/warm_bgs_caches_job.rb#L90)
- [oldest claimants](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/app/jobs/warm_bgs_caches_job.rb#L107) (age of claim) 
- [oldest records](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/app/jobs/warm_bgs_caches_job.rb#L114)

For this approach we need to update POAs based on the priority appeals outlined under the undistributed appeals portion of the "Priority consideration" section.

We would add methods to WarmBgsCachesJob each concerned with retrieving and updating the POA records for the particular docket types (i.e. `warm_poa_and_cache_for_direct_review_appeals`).

In terms of numbers of priority AMA appeals on the various dockets at the time of this writing the breakdown is:
Direct Review: 969 (`DirectReviewDocket.new.count(priority: true)`)
Evidence Submission: 600 (`EvidenceSubmissionDocket.new.count(priority: true)`)
Hearing Request: 4251 (`HearingRequestDocket.new.count(priority: true)`)

### Option 3:  A combination of Options 1 & 2
If it was determined that either of the approaches would not provide enough coverage in combination with the refresh button, we could undertake both efforts.

## Additional options from tech spec discussion
### Create a new job (not piggy-backing off of `PushPriorityAppealsToJudgesJob`) targeting distributed appeals
Since we have access to the `distributed_cases` table we can create a new job that targets recent distributions in a separate job that wouldn't a. increase the runtime of `PushPriorityAppealsToJudgesJob` or b. in the case of an exception being thrown, cause both jobs to fail.
### Update methods on BgsPowerOfAttorney model
Currently `find_or_create_by_file_number` and `find_or_create_by_claimant_participant_id` are simply responsible for locating or creating cached POA records.  We can update both of these to utilize `update_cached_attributes` which will refresh the cache from BGS.  To prevent excessive BGS calls, we can simply add a conditional referencing an "expiration" time on the cache data which we'll set so that the external call only occurs when we deem the info to be expired (initial thoughts are 24 or even 48 hours).
## Recommendation
Updating the methods on the BgsPowerOfAttorney model seems to be most preferable for a few reasons.  It is most likely the smallest lift for one.  In addition, it takes any guessing out of which POAs we are choosing to update.  Instead it is essentially that we put time constraints on to prevent excessive BGS calls. In combination with the implementation of the refresh button this should provide sufficient coverage for POA refreshes.

We do not alter WarmBgsCachesJob taking this path. This is tech debt we can address later.  
## Implementation of POA refresh button
![Screen Shot 2021-04-06 at 12 33 06 PM](https://user-images.githubusercontent.com/18618189/113746476-5e0bd900-96d4-11eb-81bd-f7d53936b009.png)
The button will need to send a request to the `AppealsController` and trigger a call to the [`save_with_updated_bgs_record! `](https://github.com/department-of-veterans-affairs/caseflow/blob/4e042c15144e926ec065e4e4869ca236158690ff/app/models/bgs_power_of_attorney.rb#L114) method on the `BgsPowerOfAttorney` model in order to retrieve the updated record.

We want to prevent the user continuously hitting the refresh button and triggering multiple calls to BGS.  To address this 
1. We should be able to utilize the Button components [loading](https://github.com/department-of-veterans-affairs/caseflow/blob/e49f79f733037461fd93b5e4d86bd174021c8d76/client/app/components/Button.jsx#L25) attribute to prevent this from occurring.
2. We can set a an expiration on the last synced time similar to what is suggested for the update of the methods on `BgsPowerOfAttorney` model, only allowing for the user to refresh after a certain period of time.

Finally we will show the user an inline success banner in the POA portion of case details informing them the POA has been refreshed. 