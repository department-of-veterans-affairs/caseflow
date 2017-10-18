# Standup

Standup is a standard way that agile development teams stay in sync, identify blockers, and build quickly. Our team is a bit unusual, because we have many people operating in a single monolithic codebase. And, many of our teams work very closely together, and some people work across teams. Long term, we may wish to address those issues directly. In the interim, we structure our standup to be optimally useful for this unusual situation.

Our standup routine has three parts:

* **10:15a** – Sprint team standup
* **10:30a** – Entire team standup
* **10:45a** – Optional post-standup discussion
* **11:00a** – Hard stop.

To describe each part:

## Standup Phases

### Sprint Team Standup
Each sprint team listed in [`priorities.md`](https://github.com/department-of-veterans-affairs/appeals-pm/blob/master/priorities.md) will meet:

| Team | Room |
| --- | --- |
| Whiskey | Bespin |
| Tango | Naboo |
| Foxtrot | Endor | 
| Devops | ??? |
| Harambe | Anoat |
| QA? | ??? |

The sprint team standup can be cancelled at the team leads' discretion. Each team is responsible for their own dial-in system for remote teammates (Slack call, Google Hangout, just calling the one remote person on the phone, etc). People who are not attached to a specific team are welcome at any standup, but only as observers.

Sprint team standup is a good time to discuss things like:

* Blockers
* What people should work on that day
* Identifying potential conflicts ("my work may step on your toes; let's chat offline.")
* Syncing on the plan for the day ("If you get me the PR by lunch, I can have it back to you by 2p.")

As always, the key to a good standup is setting the stage for doing work, not actually doing work in the meeting.

Sprint team standup is cross-functional. Engineers, designers, and product people all attend the same standup.

### Entire Team Standup
The team-wide standup occurs in Endor. This is a good time to discuss topics like:

* Updates to how deployment works
* Updates on roll-out progress
* PTO / HR announcements
* Tool / build changes ("We're switching from `npm` to `yarn`.")
* Reminders about post-standup discussions
* Notes about code changes that affect all Caseflow apps
* Notes about design or produce decisions that affect the entire team

If there are no such announcements, then we'll end the meeting immediately and give everyone the time back.

### Optional Post-Standup Discussion
Post-standup discussions occur in Endor. They are announced ahead of time at other standups.

### Hard Stop
At 11am, we stop any post-standup discussion. If we can't resolve an issue in this time, then we can schedule a longer session. It may also indicate that we need to do more prep work before gathering people to make a decision.

## Daily Schedule
| Day | Schedule | 
| --- | --- |
| Monday | Sprint + full eng standup (does design want to do a separate full standup?) |
| Tuesday | Sprint standup only |
| Wednesday | Sprint + full eng and design standup |
| Thursday | Sprint standup only |
| Friday | Sprint + full eng and design standup |

On the first Monday of the sprint, we skip standup, and do sprint planning instead.

## Expectations
At all standups, teammates are expected to be on time and pay attention.

## Appendix A: Previous Notes
* https://github.com/department-of-veterans-affairs/caseflow/issues/1703
