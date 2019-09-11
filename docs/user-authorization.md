# User authorization
This document captures the current state (09/10/2019) of user authorization and access permissions patterns in Caseflow. It can serve as a baseline from where we improve and/or simplify how we authorize and give access to users.

Caseflow has disparate permissioning sources:
1. CSEM/CSUM roles and functions
2. Feature toggles
3. VACOLS roles
4. Caseflow organizations

It's complex, because:
- How we use feature toggles overlaps with CSEM/CSUM roles
- How we use feature toggles overlaps with Caseflow organization
- How we use VACOLS roles overlaps with Caseflow organizations

We should identify patterns for each, and simplify.

Resources:
- https://github.com/department-of-veterans-affairs/caseflow/issues/5549 - discusses role based and activity based approaches to access permissions
- department-of-veterans-affairs/appeals-pm#1540 - (2017) Caseflow teamwide discussion about permissions

## CSEM/CSUM
- CSEM/CSUM is an access permissions application used by VA. 
  - Not all agencies use it. In mid-2019, the Caseflow team learned that VHA applications do not rely on CSEM
- It has 2 concepts: roles and functions
  - Initially, our team used both
  - Then, we relied more on functions, and kept the role vague as "User"
- Currently, Caseflow uses CSEM functions (which are meant to be activity-based, but the way we do so doesn’t neatly match either the activity-based or role-based approach)
    - Some Caseflow CSEM functions are phrased as activities e.g. “Certify Appeal”, “Establish Claim” 
    - Some are phrased as roles e.g. “Reader”, “Hearing Prep”
- Users submit a form (8824e) to another VA entity that process those requests - basically flips the switch. This process is notoriously cumbersome.

CSEM function | High-level functionality
---|---
Global Admin | Everything + impersonating users
System Admin | Everything
Download eFolder | eFolder Express
Establish Claim | Caseflow Dispatch flow
ManageClaimEstablishme | Caseflow Dispatch flow + manager view + Missing Decisions report
Certfy Appeal | Caseflow Certification
Hearing Prep | Caseflow Hearings - Hearing Prep functionality (Daily docket, Hearing worksheet)
VSO | VSO/private attorney/agent view of hearing schedule, VSO/private attorney/agent view of queue
Case Details | Search --> Case Details
Reader | Reader, Queue, Search, Case Details
More |

[CSUM functions](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/ansible/vars/functions-config.yml)

## Feature toggles
Conceptually, feature toggles are meant to be less permanent than roles/functions. However, the team is using these primarily to allow for code to be deployed to production as it's written for multi-ticket features, considering we deploy every day.

Assumption: feature toggles should be used for functionality that is rolled out to all users, or will eventually be removed when another mechanism for user permissions for this functionality has been decided.

We're using some feature toggles for functionality that only some users should get. This is probably an incorrect use of the pattern, because we can't remove the feature toggle and give access to everybody. We could rely on the organization pattern.
- Example: `withdraw_decision_review` is a feature toggle, when really, only a subset of BVA users should be able to do this. And, all VBA users want the ability to do this.
- Example: `remove_decision_reviews` is a feature toggle that is currently turned on for everyone, but it should be restricted.

A good example of using feature toggles as many consider they are intended is the Summer 2019 pagination API work `use_task_pages_api`. This refactoring and tech improvement begins behind a feature toggle, but can then be rolled out to everyone, and thus the feature toggle safely removed.

[Feature toggles list](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/ansible/vars/features-config.yml

TODO: comb through each and
- identify which can be removed because all users can have the functionality
- identify which should be replaced with longer term permissioning
  - LP's opinion:
    - `withdraw_decision_review`
    - `remove_decision_reviews`

## VACOLS
- The VACOLS staff table is the canonical board list of folks in many roles (Attorney, Judge, Co-located), and it currently is role-based
  - Jed updates this list
  - Seems like a headache to try to move that to CSEM and keep it updated — what’s the real lift there?
- The primary roles that provide support tickets and confusion are: Attorney, Judge, and Acting VLJ
- There are fewer VACOLS roles than there are Caseflow organizations, already

## Caseflow organizations
- Caseflow [organizations](https://github.com/department-of-veterans-affairs/caseflow/wiki/Organizations) are how Caseflow groups members of various BVA (and beyond!) teams. Since members of the same team have similar responsibilities and levels of access, we are able to use organization membership as a form of access control.
  - Examples:
    - Members of the `Mail team` can create mail tasks
    - Members of the `AOD team` can edit AOD data
    - Members of the `Special Case Movement` organization are allowed to specially move cases
    - Members of the `VLJ Support Staff` team can work `ColocatedTasks`
    - Members of the `Hearing Admin` team can work `HearingAdminActionTasks`
    - Members of the `Hearings Management` team can schedule hearings and complete hearing tasks
    - Members of the `Case Review` team can work withdrawal of appeal tasks
  - This pattern is largely:
    - Organization:Tasks :: Role:Activity
    - Special case movement is a particular outlier to that pattern
- Some members of organizations can be made team admins, which have different functionality
  - Examples: 
    - All admins can add users to their organizations
    - Judges can create AttorneyTasks
    - Admins of generic queues can act on behalf of members in their organization - they are presented with task actions available to the individual who is currently assigned the task (e.g. reassign, complete, place tasks on hold)
- Individuals are members of organizations, which often map to teams or subteams at the Board who complete certain tasks. For example: individual VLJ Support Staff are members of the VLJ Support Staff organization.

## Potential goals for access permissions
- Flexible/malleable, since we're still in development, we should make updates as we learn more/as things change
  - Can make quick changes (without lots of email/process)
- Simplified and logical, so we can give autonomy to our users

## Ideas:
- On first glance, our designs don’t seem like they fully lend themselves to purely activity-based access control
- Might we determine CSEM isn't the best option?
    - We have our own list of Functions overrides, we have our own layer where we can manage them along with CSEM
