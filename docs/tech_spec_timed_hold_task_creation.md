# Tech Spec: API for creating TimedHoldTasks

## How do we place tasks on hold now?
The only tasks that can be placed on hold are [`ColocatedTask`s](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/app/models/tasks/colocated_task.rb#L61) (and [`HearingAdminActionTask`s](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/app/models/tasks/hearing_admin_action_task.rb#L33) and [`ChangeHearingDispositionTask`s](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/app/models/tasks/change_hearing_disposition_task.rb#L11)) through [the `ColocatedPlaceHoldView` component](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/client/app/queue/ColocatedPlaceHoldView.jsx#L60). This component PATCHes to `/tasks/{task_id}` which is processed by [`TasksController.update`](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/app/controllers/tasks_controller.rb#L82) and eventually [`Task.update!`](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/app/models/task.rb#L143) with the appropriate parameters (something like `{ status: "on_hold", on_hold_duration: 14, instructions: "Placing hold until private attorney responds to email."}`).

## Why don't we just keeping doing it like that?
* Tasks returning to the active state after their timed hold expires requires [loading the queue that contains that task](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/app/models/queues/generic_queue.rb#L9). This is not obvious and has the potential to not happen (if somebody leaves the Board for instance and never loads their personal queue again).
* Tasks can be on hold for two reasons (timed hold or child task) that require different handling (timed holds should be cancellable for instance) but we essentially handle the same. `TimedHoldTask`s makes the distinction between those two types of hold clear.
* Current handling of on hold can result in bugs. For example, if we end a timed hold before it expired, then create a child task (which results in the task being placed on hold again), then the original timed hold expires [we will take the task off hold](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/app/models/task.rb#L425) even though the child task has not yet been completed.
* If we create multiple holds for a single task, we lose any record of the previous holds.
* The on hold fields results in `tasks` being a sparsely populated-table.

## So what are we doing instead?
We're creating a [special `TimedHoldTask` class](https://github.com/department-of-veterans-affairs/caseflow/issues/9207#issuecomment-484914183) that we will create as children of any tasks that will indicate that a task is on hold and that we can take off hold with [a regular script designed to do just that](https://github.com/department-of-veterans-affairs/caseflow/blob/c4d3c1ab33503d11c2cae6bea3606012d4dac828/app/jobs/task_timer_job.rb#L3).

## Let's explore some options for the `TimedHoldTask` creation API:

### 1. `PATCH /tasks/{task_id}`
We can continue sending the same request from the front-end and intercept the logical flow somewhere on the back-end (`TasksController.update` or `Task.update_from_params` perhaps) so that we create child `TimedHoldTask`s instead of updating fields on the targeted task.

**Advantages**:
* We do not have to change any front-end code.

**Disadvantages**:
* Dishonest. The front-end tells the back-end to update a task and instead the back-end creates a new task.
* Indirection leads to non-obvious placement of logical interception. Should the controller make the determination about whether to call `update()` for a task or `create()` because we want that distinction to happen at the API interface? Or should each task type decide whether to create a child `TimedHoldTask` when they are instantiated with input parameters that would place it on hold? And should that interception happen for all tasks of a given type or only for tasks updated through the front-end? Since the answers to these questions are not obvious to us now, I believe they will be less obvious to us later and frustrating bugs and confusion about how the code works.

### 2. `POST /tasks`
We could create `TimedHoldTask`s just the same as we create any other type of task.

**Advantages**:
* We do what we say. The front-end creates `TimedHoldTask`s and the back-end does what it was directed to do.

**Disadvantages**:
* We have to update some front-end code.
* We are sending redundant fields to the back-end. Since each `TimedHoldTask` will relate to an existing `Task`, we already know all of the information the front-end will send up except for the duration of the hold (and optionally instructions).

### 3. `POST /tasks/{task_id}/place_hold`
We could POST to an endpoint that indicates some action (placing a hold) we want to take on an existing task.

**Advantages**:
* We send as little information to the back-end as we need (only duration and optionally instructions) because we already know that information by way of the parent task.
* We don't have to overload any of the params functions in `TasksController`
* Represents the action we are taking directly (putting a specific task on hold)

**Disadvantages**:
* We have to change some front-end code.
* Not the REST-iest pattern.
