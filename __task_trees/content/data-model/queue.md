---
title: Caseflow Queue
weight: 6
---

# Caseflow Queue
* [Caseflow Queue](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Queue)
  * [Organizations](https://github.com/department-of-veterans-affairs/caseflow/wiki/Organizations)
  * [Tasks](https://github.com/department-of-veterans-affairs/caseflow/wiki/Tasks)
    * [Tasks talk](https://github.com/department-of-veterans-affairs/caseflow/wiki/2019-12-04-Wisdom-Wednesday---Tasks-and-their-Trees)
* [Queue tables diagram](https://dbdiagram.io/d/5f790a8f3a78976d7b763c61)
  * Appeal, Task
  * User, OrganizationsUser, Organization, JudgeTeam organizations

## Appeals
Queue is the portion of Caseflow users utilize when an appeal has reached the [Decision](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/tasks-overview.md#decision-phase) phase and is ready to be reviewed by judges and attorneys for processing. Queue services both AMA and Legacy appeals, the behavior of each varying slightly. One of the main differences is that AMAs are contained within Caseflow whereas much of the data for Legacy appeals is extracted from [VACOLS](https://github.com/department-of-veterans-affairs/caseflow/wiki/VACOLS-DB-Schema).

## Tasks
User interaction with specific appeals is dependent on the type of task on the appeal that's been assigned to them. For instance, a [`JudgeAssignTask`](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/JudgeAssignTask_User.md) is given to a judge so that they may assign an [`AttorneyTask`](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/AttorneyTask_User.md) to an attorney on their team to draft a decision.

A more thorough breakdown of Queue tasks can be found in the Decision phase portion of the task tree [documentation](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/tasks-overview.md#decision-phase)

## Organizations
Users can be added to organizations so that we can control the types of permissions and task action options alotted to them.  For instance, [`JudgeTeams`](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/models/organizations/judge_team.rb) are comprised of a judge along with their team of attorneys.  This allows the judge to assign cases to these individuals in the same flow mentioned in the Task description.

## Relationships
In the following diagram, you can see that an `id` on an AMA or Legacy appeal will correspond with the `appeal_id` on a task created on that appeal.

An `assigned_by_id` or `assigned_to_id` will correspond with the `id` of the user who has either assigned or been assigned a task

Finally, `organization_users` is representative of a users relationship to a particular type of organization.  Therefore the users table's `id` will correspond with the `user_id` and the organizations table's `id` will correspond with the `organization_id`.

<img src="https://user-images.githubusercontent.com/63597932/116122858-4c44a280-a690-11eb-8198-666b0c23a82e.png">
