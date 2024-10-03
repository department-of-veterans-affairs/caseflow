This document was moved from [appeals-team](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Caseflow%20Projects/Hearings/Hearing%20Schedule/Tech%20Specs/COParentRecordsTransition.md).

## CO Parent Records to Caseflow  

Owner: Sharon Warner  
Date: 2018-11-16
Reviewer(s): Oscar Ramirez, Meredith Stewart, & Andrew Lomax  
Review by:  2018-11-18 

## Context

On January 1st, 2019, we are creating CO parent records in Caseflow! CO child records will still be stored in VACOLS, but will all be associated with a parent record in Caseflow. Caseflow will be the source of truth for the hearing date, hearing type, judge, regional office, room, BVA POC, and RO POC. To ensure backwards compatibility, when a parent record is updated or a child record is created, the information from the parent record will be saved/updated on the associated children records in VACOLS as well.

## Implementation

**VACOLS Updates**
1) The following fields on the hearsched table need to only be editable through Caseflow for CO hearings: hearing_date, hearing_type, board_member, room, vdbvapoc, and vdropoc.

**Caseflow Updates**
1) The RO/CO algorithm needs to create Caseflow parent records for Mondays-Thursdays excluding holidays and CO blackout dates.
2) The judge algorithm needs to assign judges for all CO parent records in Caseflow.
3) The assign hearings logic should create child records associated with Caseflow parent records for CO hearings.
4) Updating a hearing day should also update the information on any existing children records.
