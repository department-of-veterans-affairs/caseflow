# Data Changelog

## Certification

Date | PR | Change
---- | -- | ------
2015-12-02 |  | First record
2016-09-20 | [#326](https://github.com/department-of-veterans-affairs/caseflow/pull/326) | Begin recording certifications in the `certifications` table. Prior to this point, Caseflow certifications were only recorded in VACOLS, indicated by the presence of a `BRIEFF.BFDCERTOOL` timestamp.
2016-11-03 | [#393](https://github.com/department-of-veterans-affairs/caseflow/pull/393) | Begin recording changes to the Form 8 in the `form8s` table.
2016-11-28 | [#486](https://github.com/department-of-veterans-affairs/caseflow/pull/486) | Begin recording the certifying user in the `users` table.

## Dispatch

Date | PR | Change
---- | -- | ------
2017-02-21 |  | First record
2017-04-13 | [#1503](https://github.com/department-of-veterans-affairs/caseflow/pull/1503) | Prior to this date, `tasks.completion_status` was set to 0 (`routed_to_arc`), when it should have been set to 3 (`routed_to_ro`) or 7 (`special_issue_vacols_routed`). 6 (`special_issue_not_emailed`) deprecated.

## Reader

Date | PR | Change
---- | -- | ------
     |    |  

## Google Analytics

Date | PR | Change
---- | -- | ------
9/11/17 | https://github.com/department-of-veterans-affairs/caseflow/pull/3118 | Changed header menu events from: eventCategory: 'Menu', eventAction: 'Click`(Help or Feedback)`', eventLabel: '`(Help or Feedback)`', eventValue: 1 to eventCategory: '`(AppName)`', eventAction: '`(Help or Feedback)`'
