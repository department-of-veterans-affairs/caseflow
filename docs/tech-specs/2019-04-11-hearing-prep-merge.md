This document was moved from [appeals-team](https://github.com/department-of-veterans-affairs/appeals-team/blob/main/Project%20Folders/Caseflow%20Projects/Hearings/Hearing%20Schedule/Tech%20Specs/HearingPrepMerge.md).

## Hearing Prep Merge

Owner: Sharon Warner
Date: 2019-04-11
Reviewer(s):
Review by:

## Context

When Caseflow Hearing Prep was first developed 2 years ago, hearings' master records (records that group hearings by type, date, regional office, and judge) were stored in inconsistent ways in VACOLS. Video hearings were all linked to master records in the hearings table; CO hearings did not have any concept of master records; and travel board hearings had master records stored in a completely different table. Because these master records were so inconsistent, we determined it would be easier to not use master records within hearing prep and instead group hearings in our own way.

Since Caseflow Hearing Schedule's rollout, however, we now have a consistent implementation of master records, now called hearing days, stored in caseflow's database. We also already have implemented hearing schedule views and daily dockets based on these hearing days. In order to minimize discrepancies between Hearing Prep and Hearing Schedule, we are merging Hearing Prep's hearing schedule views and daily dockets into Hearing Schedule.

## Out of Scope

We will not be introducing any new functionality for travel board hearings, and we will be removing travel board support from hearing prep.

## Rollout Plan & Implementation

- [x] Add an alert to Hearing Prep informing judges that travel board will not be supported as of May 20th, 2019.
- [x] Stop displaying travel board hearings scheduled after May 20th, 2019.
- [x] Add judge view in Hearing Schedule for the view schedule page.
- [x] Add judge view in Hearing Schedule for the daily docket.
- [x] Add a button to the alert that will redirect judges to the Hearing Schedule homepage at their discretion.
- [x] After a set amount of time (must be after May 20th), add an automatic redirect from the Hearing Prep homepage to the Hearing Schedule homepage such that judges no longer have the ability to view Hearing Prep.
- [x] After a set amount of time, remove hearing prep code.
   - [x] Remove dockets_controller.rb, master_record.rb, hearing_docket.rb
   - [x] Add hearing worksheet to Hearing Schedule application
   - [x] Remove `client/app/hearings`
   - [x] Rename `client/app/hearingSchedule` to `client/app/hearings`
   - [x] Remove `app/views/hearings`
   - [x] Rename `app/views/hearing_schedule` to `app/views/hearings`
- [ ] Administrative cleanup
   - [x] Remove `caseflow-hearing-prep` tag from Github
   - [x] Rename `caseflow-hearing-schedule` tag to `caseflow-hearings`
   - [x] Remove `hearing-prep` channel from Slack
   - [x] Rename `hearing-schedule` channel to `hearings`
   - [x] Confirm Sentry alerts are sent to `hearings` in Slack
   - [x] Rename `Hearing Schedule` to `Hearings` in the application
   - [x] Confirm support requests are sent for `Hearings`
   - [x] Remove hearing prep from Statuspage
   - [ ] Update FAQs
