---
title: Caseflow Dispatch
weight: 7
---

# Caseflow Dispatch
* [Caseflow Dispatch](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Dispatch)
* [BVA Dispatch](https://github.com/department-of-veterans-affairs/caseflow/wiki/BVA-Dispatch)
* [Dispatch tables diagram](https://dbdiagram.io/d/5f790ba03a78976d7b763c6d)

Caseflow Dispatch exists to create [EndProducts](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#endproduct) in VBMS from completed cases in VACOLS. Users of Dispatch, VBA Office of Administrative Review (OAR) employees, are presented with VACOLS cases that have received a decision and need to be routed to the correct VBA entity to update a Veteran's benefits.

## LegacyAppeals
The LegacyAppeals table is utilized by numerous Caseflow products. A [description](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Data-Model-and-Dictionary#legacyappeals) can be found above in the Certification section.

## DispatchTasks
Caseflow [tasks](https://github.com/department-of-veterans-affairs/caseflow/wiki/Tasks) designate what action needs to be taken on an appeal and who is responsible for taking said action. There are a wide variety of tasks across Caseflow products, but the Dispatch::Tasks table currently only stores EstablishClaim task records which are used to create the EndProduct in VBMS. You can read more about tasks [here](https://docs.google.com/presentation/d/1Cc84GH7giWHTNxUe3zixH7O-QT77STlptYfud9X8P1Y/edit#slide=id.g5ee8a20194_1_406).
* `aasm_state`
* `user_id` gets assigned upon clicking "Establish Next Claim" in Dispatch

## Users
[Caseflow users](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/roles/role-overview.md) are distinguished by their role, with different roles having different permissions and thus different capabilities made available to them.
* `roles`: All of the user's roles
* `css_id`: A unique identifier for VA employees or contractors

## Relationships
In the diagram below, you will see that the `dispatch_tasks` tables stores the `id` of the `user` assigned to the task as well as the `id` of the `legacy_appeal`. The `legacy_appeals` tables does not store any `dispatch_task` `ids` because each appeal can have many `dispatch_tasks`.

<img src="https://user-images.githubusercontent.com/63597932/116123231-c2e1a000-a690-11eb-9097-a8f48d223a0b.png" width=800>
