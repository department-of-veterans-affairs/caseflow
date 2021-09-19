---
title: Caseflow Hearings
weight: 3
---

# Caseflow Hearings
* [Caseflow Hearings](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings)
* [Hearing Request Type](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#hearing-request-type)
* [Hearings tables diagram](https://dbdiagram.io/d/5f98b2073a78976d7b796fa2)

## Hearings

Veterans have the option to have a hearing with a Veterans Law Judge (VLJ) as part of the appeals process. At these hearings, a VLJ meets with a veteran or representative to go over the case. It is not a defense but a chance for a Veteran to provide additional details. After a hearing is conducted, the recordings are sent to the transcription office, and then entered into VBMS.

There are four types of hearings:
* Central Hearing: An in-person hearing at BVA's central office (425 I st.)
* Video Hearing: A hearing over video conference conducted between a regional office or alternate hearing location and central office
* Virtual Hearing: a hearing over video conference conducted between any location (sometimes the representative's office) and central office
* Travel Board: An in person hearing where the VLJ travels to the regional office. These are not currently supported by Caseflow and are handled in VACOLS. If Caseflow serves Travel Board hearings it will be only through converting them to video or virtual hearings.

## HearingDays

A `HearingDay` organizes `Hearings` and `LegacyHearings` by regional office and hearing room.
* A hearing day is assigned to one judge, although hearing coordinators have the ability to override the hearing day's judge on the [Hearings table](https://github.com/department-of-veterans-affairs/caseflow/blob/622210e52cff4b468385b2396bf4ca105546a04b/db/schema.rb#L628) or in [VACOLS](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/repositories/hearing_repository.rb#L177) by editing the [hearing details](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#for-hearing-coordinators).
* Each room / HearingDay has a maximum number of hearings that can be held (slots) that are determined by the regional office's [timezone](https://github.com/department-of-veterans-affairs/caseflow/blob/622210e52cff4b468385b2396bf4ca105546a04b/app/models/hearing_day.rb#L27-L39). If a hearing day's slots are filled, the coordinator will receive a warning when scheduling a Veteran ("You are about to schedule this Veteran on a full docket. Please verify before scheduling") but will still be able to schedule if they so choose.
* `request_type` : `R` for virtual, `V` for video, `C` for central
* `regional_office`: If the `request_type` is `V`, then the `HearingDay` will be associated to a regional office
* `judge_id`
* `scheduled_for`

## LegacyHearings
Legacy Hearings are hearings for cases that originated inside of VACOLS.  On a judge's Hearing Worksheet, they can edit Legacy hearing issues directly on the workbook page (for AMA cases, they would need to go to the Case Details page).

## Task
All appeals on the hearing docket have a series of tasks that can be divided into five groups.  Here is a brief summary of what those are, full description can be found [here](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#hearings-task-model).
* Initial tasks - these include creating a `HearingTask` with a child `ScheduleHearingTask`. For AMA cases, the initial hearing tasks are created as a children of the `DistributionTask` after intake. For Legacy cases, a geomatching job finds all appeals in VACOLS that are ready to be scheduled and creates a hearing task tree as a child of the `RootTask`.
* Schedule Veteran tasks - schedule hearing tasks are shown on the assign hearings page (see this [page](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Hearings#hearings-pages-overview). A coordinator can block scheduling by adding a `HearingAdminActionTask` and can also withdraw the hearing.  After scheduling, a `AssignHearingDispositionTask` and a new hearing is created and that hearing is associated to the `HearingTask` with an `HearingTaskAssociation`.
* Assign a Disposition - Postponing cancels the current hearing task and recreates the initial hearing task tree. If a coordinator or judge changes the hearing's disposition on the daily docket, the `HearingDispositionChangeJob` finds all appeals with hearings in the last 24 hours and creates a `AssignHearingDispositionTask` and completes the task based on the disposition.  No-show hearings are given a `NoShowHearingTask`.
* Transcription/Evidence submission - After a disposition is assigned, AMA appeals must complete a `TranscriptionTask` and an `EvidenceSubmissionWindowTask`. The evidence task gives the Veteran an additional 90 days to submit evidence before the case is distributed.
* Case Distribution - When all other hearing tasks are completed, a case is ready for distribution to judge because its `DistributionTask` is moved from on_hold to assigned (AMA cases) or the case is in case storage location 81 (legacy cases). See also [automatic case distribution](https://github.com/department-of-veterans-affairs/caseflow/wiki/Automatic-Case-Distribution).

## VirtualHearings
Once a virtual hearing is scheduled, the associated record in `hearing_days` is not changed because a record in the `hearing_days` table represents the whole day. In other words, many hearing types are associated with that `hearing_days` record, so `hearing_days.request_type` should not be changed. This is an artifact of how the virtual hearings feature was introduced into Caseflow, i.e., as a conversion of video hearings into virtual hearings.

[`virtual_hearings`, `virtual_hearing_establishments`, and `sent_hearing_email_events` table descriptions](https://github.com/department-of-veterans-affairs/caseflow/issues/14067#issuecomment-620792309)

## Relationships
In the diagram below you can see the following relationships between various hearing-related tables:
* The `hearings` and `legacy_hearings` table's `id` corresponds with the `hearings_tasks_assocations` and `virtual_hearings` table's `hearing_id`.
* The `hearings` and `legacy_hearings` table's `hearing_day_id` corresponds with the `hearing_days` table's `id`.
* The `hearings_tasks_assocations` table's hearing_task_id corresponds with the `tasks` table's `id`.

<img src="https://user-images.githubusercontent.com/63597932/105734269-760af380-5f00-11eb-8766-cc8fea5ba437.png">


