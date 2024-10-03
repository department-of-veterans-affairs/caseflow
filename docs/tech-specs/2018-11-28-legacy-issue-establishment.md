This document was moved from [appeals-team](https://github.com/department-of-veterans-affairs/appeals-team/blob/main/Project%20Folders/Caseflow%20Projects/Intake/Tech%20Specs/legacy-issue-establishment.md).

# Legacy Issue Optin

## Context

Per the Acceptance Criteria in https://github.com/department-of-veterans-affairs/caseflow/issues/7337
we need to opt-in Legacy Appeal Issues to the AMA flow. Since this means interacting with VACOLS
and the existing Intake process, we thought it best to seek input both from the Sierra team and the Foxtrot
team for our technical proposal.

## Overview

A new model to transition legacy issues from VACOLS to AMA flow.

## Implementation

Because it must interact with external systems (VACOLS) this feature needs to be able to work asychronously.
We considered a variety of approaches to storing the necessary information for async work.

The `EndProductEstablishment` model already has Asyncable columns in place for other cases, and `Appeal` does
not create End Products, but does fall under the use case for Legacy Issue opt-in.

The `DecisionReview` abstract model supports the AMA flow. It is subclassed for a total of 3 tables
(appeals, higher level reviews, supplemental claims). The existing pattern for async work is to use
the `Asyncable` model concern on an existing table.
In this case, that means adding 4 columns to each of 3 tables, for 12 new columns.

Alternately, we propose a new model called `LegacyIssueOptin`. This new model
would work similarly to `EndProductEstablishment`. It would update VACOLS, asynchronously and idempotently,
and connect a `RequestIssue` and the legacy VACOLS issue.

Example schema:

```
            Column             |            Type             |  Nullable | Default
-------------------------------+-----------------------------+-----------+-------------------------------
 id                            | bigint                      |  not null | autoincrement
 request_issue_id              | bigint                      |  not null |
 submitted_at                  | timestamp without time zone |           |
 attempted_at                  | timestamp without time zone |           |
 processed_at                  | timestamp without time zone |           |
 error                         | character varying           |           |
```

The Legacy Issue reference id would be stored on the related `RequestIssue`.

