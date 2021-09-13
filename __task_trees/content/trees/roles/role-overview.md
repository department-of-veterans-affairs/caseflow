| [All Roles][ar] | [Attorney][a] | [Judge][j] | [Colocated][c] | [Acting Judge][aj] | [Dispatch User][du] | [Regional Office User][ro] | [Intake User][iu] | [Hearings User][hu] |

# Roles Overview

There are a number of different roles available within Caseflow defined primarily by which functions they are allowed to perform.

- [Attorney][a]
- [Judge][j]
- [Colocated][c]
- [Acting Judge][aj]
- [Dispatch User][du]
- [Regional Office User][ro]
- [Intake User][iu]
- [Hearings User][hu]

Users with a particular role will have access to perform different actions on tasks that have been assigned to them in their queue. To learn more about what roles can perform which actions on a given task, refer to each of the user role pages above.

[Caseflow User Access Guidance.pdf](https://drive.google.com/drive/folders/1ThQ2Q1G6Yv2RUdfk19_wFrpl8dXlTMcE)

## Queue

Each of the roles is associated with a particular queue that will be created for them if it does not exist as well as a list of available tasks associated with that queue. Attorneys get a special `AttorneyQueue` while all other user roles will receive a `GenericQueue`. Queues are built whenever the task list is [loaded](https://github.com/department-of-veterans-affairs/caseflow/blob/befe386da2803738292594f844a7f9fb87317f9e/app/controllers/tasks_controller.rb#L43) or a new task is [created](https://github.com/department-of-veterans-affairs/caseflow/blob/befe386da2803738292594f844a7f9fb87317f9e/app/controllers/tasks_controller.rb#L79)

In the Queue application, there are some tasks that are specific to the user roles above (see the individual role pages for specific examples). Other tasks are created and used by the system, such as the [Distribution Task](../task_descr/DistributionTask_Organization.md) which is used to auto-assign tasks to judges.

---

## Access Control

The Caseflow access control logic is implemented by checking several different attributes about the user. These attributes can come from a few different systems and use different methods to determine access.

The primary method for determining roles on a user is called `roles`

```ruby
def roles
  (self[:roles] || []).inject([]) do |result, role|
    result.concat([role]).concat(FUNCTION_ALIASES[role] || [])
  end
end
```

Additional methods for verifying user roles are as follows

### By Organization

The different organizations that the user is associated with (through `organization_users` table) can determine to which team the user belongs. Some teams have tasks specific to them:

- [Special Case Movement Team](../task_descr/SpecialCaseMovementTask_User.md)
- [Translation Team](../task_descr/TranslationTask_Organization.md)

### By Location

If the user has a station ID that is listed in the Regional Office, their roles will include the Regional Office User role.

### By Staff Fields

If the user is a VACOLS Staff, then they will have additional information on user profile to determine whether they will have one of the following roles:

- [Attorney][a]
- [Judge][j]
- [Colocated][c]

### By Function

Functions encompass a number of actions within the application that a user can perform if they have been granted that particular function. These actions help determine whether the user will be in one of the secondary roles listed above. Current functions include the following:

- Build HearSched
- Edit HearSched
- RO ViewHearSched
- VSO (a misleading term, as PrivateBar Organization users also receive the VSO role)
- Hearing Prep

[ar]: ./role-overview.md
[ro]: ./Regional_Office_User.md
[aj]: ./Acting_Judge.md
[a]: ./Attorney.md
[hu]: ./Hearings_User.md
[iu]: ./Intake_User.md
[du]: ./Dispatch_User.md
[c]: ./Colocated.md
[j]: ./Judge.md
[vsoe]: ./VSO_Employee.md
