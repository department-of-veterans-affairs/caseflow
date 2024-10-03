This document was moved from [appeals-team](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Caseflow%20Projects/Hearings/Hearing%20Schedule/Tech%20Specs/ScheduleHearingTask.md).

## Schedule Hearing Task

Owner: Sharon Warner & Andrew Lomax   
Date: 2018-11-14   
Reviewers: Lowell Wood

## Context

We are refactoring the way we create Hearing Scheduling tasks on the Case Details page! 

Previously, we created a Schedule Hearing task anytime a user navigated to the Case Details page from the Assign Hearings page. Unfortunately this leaves out necessary functionality; for example, sometimes users will navigate to the Case Details page from search and need to schedule a hearing.

To fix this, we are now going to allow Hearings Management Branch users to create Schedule Hearing tasks themselves.

## Overview

When on the Case Details page, all Hearings Management Branch users will have the ability to create a Schedule Hearing task for the appeal as long as 1) The appeal does not already have a hearing with no disposition, and 2) The appeal does not already have an open Schedule Hearing task. 

When a user begins working on the Schedule Hearing task, a modal is displayed. This modal will display a noneditable hearing location (Central Office or the RO for a video hearing) and dropdown of upcoming hearing dates with available slots for that hearing location. If the user has navigated to the Case Details page from the Assign Hearings page, the hearing date will be prepopulated with the date the user selected on the Assign Hearings page. If the user has navigated to the Case Details page a different way, the date will not be prepopulated.

## Implementation

Previously, we created a Schedule Hearing task from the Assign Hearings page and were able to transfer data through a task payload. Because the user is now creating the Schedule Hearing task from the Case Details page, we can't use the task payload. We will transfer the selected hearing date, location, and parent record id through a query param.

We'll update the Assign Hearing modal such that when the user selects 'Change' on the hearing date, we send a call to the backend to get that hearing location's upcoming hearing days with available slots. We can use logic similar to load_days_with_open_hearing_slots in HearingDay.rb, but we'll pare the data collected down to ensure the call finishes in a reasonable amount of time. When the user selects a date, we'll create a hearing for that date's associated parent record.

When a query param does not exist on the Case Details page, we'll have to prepopulate the hearing location based on information from the appeal. We can get the appeal location from sanitized_hearing_request_type in legacy_appeal.rb and regional_office if necessary. We can populate the hearing date choices using the same logic as above.

While previously we created a root task and a Schedule Hearing task on Case Details page load, we will now only create a root task on page load (assuming one does not already exist). Any hearings management branch user will have the ability to create a Schedule Hearing task as long as the appeal does not have a scheduled hearing with a blank disposition and the appeal doesn't already have an open Schedule Hearing task. These tasks will be assigned to the Hearings Management Branch organization.
