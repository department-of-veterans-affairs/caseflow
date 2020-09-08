# Converting Travel Board hearings to video or virtual hearing requests
**Drafter**: Tomas Apodaca

**Date**: August 19th, 2020

## Context

Travel Board hearings are hearings for which a judge travels to a regional office and meets with the veteran in person. Only veterans with legacy appeals have been able to express a preference for a Travel Board hearing. That preference has been recorded in VACOLS, and is accessible in Caseflow via the `LegacyAppeal.sanitized_hearing_request_type` method.

This tech spec describes the back end changes necessary to "convert" requests for Travel Board hearings in VACOLS into requests for video or virtual hearings in Caseflow.

## Overview

In brief, intake and hearings management branch users will be able to visit the case details page for a legacy appeal with a Travel Board hearing request, and take an action that:

1. indicates whether the veteran prefers a video or virtual hearing,
2. allows the user to add a note for context, and
3. places that appeal in the appropriate regional office schedule veterans queue.

Later, when a coordinator schedules the veteran for a hearing, they will be able to see the preference for video or virtual that was chosen, and see and edit the note that was added.

We will also keep a record of what preference was selected, when the change was made, and who made it.

## Non-goals

This tech spec is specific to the requirement at hand: putting cases with Travel Board hearing requests into queues to be scheduled as video or virtual hearings. There may be a need to expand this functionality to other scenarios in the future, so I've tried to keep the design flexible, but fully anticipating those scenarios is outside the scope of this spec.

## Implementation

### A user has actions available from the case details page

When a user with the `"Admin Intake"`, `"Build HearSched"`, or `"Edit HearSched"` roles visits the case details page for a legacy appeal with a Travel Board hearing request, we will create (if it doesn't already exist) a typical schedule hearing task tree, with a `ChangeHearingRequestTypeTask` as the child of the `ScheduleHearingTask`. The task tree will look like this:

```
                                                ┌────────────────────────┐
LegacyAppeal (legacy) ───────────────────────── │ STATUS   │ ASSIGNED_TO │
└── RootTask                                    │ on_hold  │ Bva         │
    └── HearingTask                             │ on_hold  │ Bva         │
        └── ScheduleHearingTask                 │ on_hold  │ Bva         │
            └── ChangeHearingRequestTypeTask    │ assigned │ Bva         │
                                                └────────────────────────┘
```

The `ChangeHearingRequestTypeTask` will be assigned to the BVA organization by default. It will not be visible in any task queue (by overwriting the inherited `hide_from_queue_table_view` method to return `true`). It will have two actions available on it: "Convert hearing to video", and "Convert hearing to virtual".

### A user takes an action on the task

Selecting "Convert hearing to video" on the task will present the user with a simple confirmation modal, as described in [#12826](https://github.com/department-of-veterans-affairs/caseflow/issues/12826).

Selecting "Convert hearing to virtual" on the task will present the user with a confirmation form, as described in [#12826](https://github.com/department-of-veterans-affairs/caseflow/issues/12826). That form will have a text area field for notes, and a submission button.

Submitting the modal or the form will cause the following steps to happen.

### The new request type is saved

In VACOLS, the hearing request type is saved on the appeal. We access the value via the `LegacyAppeal.sanitized_hearing_request_type` method, which can return `:travel_board`, `:central_office`, or `:video`.

To accommodate our requirements, we'll add a column to the `legacy_appeals` table named `changed_hearing_request_type`, which will have possible values of `nil`, `"video"`, or `"virtual"`.

We still want to be able to access the original type of hearing request, so we'll rename `sanitized_hearing_request_type` to `sanitized_vacols_hearing_request_type`.

Then we'll create a new `sanitized_hearing_request_type` method that, if `changed_hearing_request_type` is `nil`, returns the value of `sanitized_vacols_hearing_request_type`, and otherwise returns `changed_hearing_request_type.to_sym`.

### The note is saved

If the hearing request type is being converted to virtual, a note may have been submitted with the form.

The note is intended to be viewed when a coordinator is scheduling a hearing, and it must persist until a hearing has been held, or the hearing request is withdrawn.

We'll save the note in a `HearingNote` object. This is a new model that will record the following details:

1. the contents of the note (`notes`)
2. the id of person who created/last updated the note (`updated_by_id`)
3. the date the note was created/updated (`created_at`, `updated_at`)
4. A polymorphic association with the appeal (`appeal_type`, `appeal_id`)

The table should have an index on the `appeal_type` and `appeal_id` columns together.

With this approach, we can easily access the note and display it/make it editable in whatever context it needs to be seen.

### The task is completed

The `ChangeHearingRequestTypeTask` is completed, and its parent `ScheduleHearingTask` status is automatically set to `assigned`.

The active `ScheduleHearingTask` will cause the veteran to show up in the schedule veterans queue for the appropriate RO (after the `UpdateCachedAppealAttributesJob` has cached the appeal).

### A record of the change is saved

A `PaperTrail::Version` object is saved. We will configure PaperTrail narrowly, to save only updates to the `changed_hearing_request_type` column. This will allow us to derive the following details:

1. What was changed (the `changed_hearing_request_type`)
2. What it was changed to (`video` or `virtual`)
3. When it was changed (via `created_at`)
5. The user who made the change (`whodunnit`)
6. The legacy appeal that was changed (`item`)

We may eventually use these objects to display a record of hearing request type changes to the user.

### When the hearing is scheduled

When the hearing is scheduled, we will use the value of `changed_hearing_request_type` to pre-select a hearing type in the schedule form. We'll also display, and make editable, the notes that were saved in the `HearingNote` object when the new hearing request type was created.

## Rollout

The user-facing aspects of the feature should be placed behind a feature flag named `convert_travel_board_hearings`.
