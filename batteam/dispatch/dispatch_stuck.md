---
my_var: ok
tags: ["batteam", dispatch", "stuck"]
---

# Dispatch claim being "stuck"
If I receive a support issue regarding Caseflow Dispatch claim being "stuck".
1. Look for a Sentry error in `#appeals-dispatch` channel.
1. If the error is related to `AASM::InvalidTransition`, that means the state transition is invalid.
1. Find the associated dispatch task in the `dispatch_tasks` table.
1. Choose the appropriate state for the task by referencing the `aasm` machine in `Dispatch::Task` model and update the task manually using production console.
1. Example of a similar problem can be found [here](https://dsva.slack.com/archives/CHX8FMP28/p1561996067122700).