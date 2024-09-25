This document was moved from [appeals-team](https://github.com/department-of-veterans-affairs/appeals-team/blob/main/Project%20Folders/Caseflow%20Projects/Hearings/Hearing%20Schedule/Tech%20Specs/SlottingVeterans.md).

## Slotting Veterans - October 19th Release

Owner: Sharon Warner
Date: 2018-08-16
Reviewer(s):
Review by:

## Context

In a previous phase of Hearing Schedule, we created functionality to allow users to build a hearing schedule. The hearing schedule is comprised of hearing days which are associated with a hearing type, an RO (if applicable), and a judge. Each hearing day can have up to 11 hearing slots that we can assign veterans to.

While previously, RO hearing coordinators handled assigning veterans to hearing slots, the AMA legislation dictates that the board must take this process over. We are creating functionality within Caseflow Hearing Schedule to assist hearing coordinators at BVA with this process.

## Overview

In order to allow our users to slot veterans to hearing days, we will provide two data elements:

1) A list of veterans who are ready for hearings, filtered by RO and hearing type, and sorted by priority and docket order (CAVC, AOD, other)
2) A list of upcoming hearing days, filtered by RO and hearing type, along with the number of available slots

The hearing coordinators will use these data elements to assign veterans to the appropriate hearing days. We will also build search functionality so hearing coordinators can search for individual cases.

We will provide this functionality for hearings scheduled in both VACOLS and Caseflow and video and central office hearings.

## Out of Scope
1) We will not slot veterans for travel board hearings.
1) We will not provide functionality for finding appeals in location 57 that do not have a hearing type requested. There is an existing report that can be run to find those appeals, and the hearing coordinators can update the hearing type in VACOLS.
1) We will not account for docket date when pulling appeals from location 57.
1) We will not slot veterans with appeals in locations that do not hold hearings (Philadelphia Pension Center, etc).*
1) We will not slot veterans with AMA appeals.*
1) We will not provide functionality for alternate hearing locations.*

\* will be available by March 31st

## Open Questions

1) How will we prevent multiple users from editing the same schedule?

## Process Changes

Currently, hearings are scheduled for appeals in VACOLS' locations 57, 77cert, and 96. While 57 is the official VACOLS location for appeals waiting for a hearing to be scheduled, often hearings are scheduled from locations 77cert and 96 (the official locations for appeals and remanded appeals waiting to be activated). This makes sense while ROs are scheduling hearings because ROs have visibility into appeals in locations 77cert and 96, but not 57. This makes less sense now that the board is taking over scheduling hearings.

We are proposing a process change to the board to only schedule hearings for appeals in location 57. This would mean that the activation team would need to activate all appeals before hearings are scheduled.

## Implementation

***Data Structures***

The data structures for Caseflow hearings can be found [here](2018-06-21-vacols-caseflow-transition.md).

***VACOLS Integrations***

To find veterans ready to be scheduled for a hearing, we will pull appeals from location 57 (assuming the process change is successful). The hearing type and the associated RO can be found in the brieff table. They are currently stored as hearing_request_type and regional_office on the Caseflow appeal object.

After scheduling a veteran, we will move their appeal to location 36 if they were assigned a central office hearing and location 38 if they were assigned a video hearing.

***User Permissions***

This functionality will be accessible to anybody with 'Build HearSched' or 'Edit HearSched' functions.

***URLs***

The homepage for this functionality will exist at /hearings/schedule/assign.

## Rollout Plan

**CO Hearings**— This functionality will be released October 19th, 2018. Our first user will be the Central Office Hearing Coordinator at the Board. They will use Caseflow to slot veterans for central office hearings. We confirmed with the Hearings Management Branch that all Central Office appeals to be scheduled area already available in Location 57, which is already part of their normal processes for scheduling CO hearings.

The Project Management Team will develop training materials and we will schedule a training with the CO Hearing Coordinator.

**One Regional Office** — After successful rollout to Central Office hearings, the board will take over slotting veterans for 1 RO that does not have any alternate hearing locations through Caseflow. For this to work, the Board will need to activate, case review, and move these appeals to Location 57 so that Caseflow can display those Veterans to schedule.

**Full Roll out** - On February 14th, 2019, the board will take over slotting veterans for all ROs.  The Board will need to have appeals that are ready to be scheduled activated, reviewed, and in location 57.

## Research Notes
