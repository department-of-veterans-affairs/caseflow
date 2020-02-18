---
name: Flaky test task
about: Template for a new task to investigate and fix a flaky test
title: "[Flaky Test] "
labels: Flaky test, tech-improvement
assignees: ''

---

## Description
<!-- The description should summarize enough information that someone can know what this ticket is about without having to look at information in background/context -->

## Background/context/resources
<!-- A place for additional information such as links to Slack chats, Sentry alerts, data IDs, research links -->

 - Circle CI Error:  [ <!--CircleCI Failure alert text --> ](<!-- link to circleCI flake -->)
 - Has the test already been skipped in the code?
   - [ ] Skipped
   - [ ] Not Skipped
 - Related Flakes
    + <!-- list any suspected related flaky test GH issues / CI links -->

## Approach
<!-- Has our agreed upon default approach for tackling flaky tests. -->
Time box this investigation and fix. 
Remember that if a test has been skipped for a decent amount of time, it may no longer map to the exact code. 
If you reach the end of your time box and don't feel like the solution is in sight, 
  - document the work you've done, including dead ends and research
  - skip the test in the code
  - file a follow on ticket 
  - and close this one
