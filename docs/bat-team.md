# Appeals Bat Team

## Definition

The Bat Team focuses on removing obstacles for regular sprint work. Each week two engineers are on-call
and during that week they, along with the engineering lead, form the Bat Team. Their mission is to:

* triage all product manager and support questions related to production issues
* respond to production issues as they arise
* monitor Slack for Sentry alerts
* improve the code base to reduce technical debt

The name "Bat Team" refers to the ["batman" military role](https://en.wikipedia.org/wiki/Batman_(military)).
It is a [growing software industry practice](https://twitter.com/mipsytipsy/status/1059392900239306755)
and an experiment in [agile development](https://www.icidigital.com/blog/web-development/batman-can-save-agile-team).

## Rituals

The Bat Team listens in the #appeals-batteam channel. They should be the only engineers actively participating
in that channel during the week, since the whole goal of the Bat Team is removing distractions from the
regular sprint team work.

The Bat Team commences Monday morning with a brief planning meeting, to choose which technical debt improvements
will be their focus during the week. Aside from that planning, their work is mostly reactionary according
to the needs of production support that week.

The team does async Slack standup reports each day, listing what happened yesterday, their plans for today,
and any blockers they are experiencing. The role of the engineering lead is to remove those blockers.

The team does a retrospective each Friday to reflect on the week and determine any recommendations
for the next team.

## Protocols

### Sentry and Slack

Each Bat Team member should take responsibility for one or more Slack channels and monitor for Sentry alerts. These
come from the production Caseflow system.

When a new Sentry alert appears in Slack, it should be investigated asap. If you cannot investigate it immediately,
emoji tag it with the :bat: emoji.

If a Github ticket already exists for the underlying issue, the Sentry alert should be ignored for a week.

If a Github ticket does not yet exist, create a Github ticket, with a link to the Sentry incident
in the ticket description.

The key evaluation is whether this incident reflects an immediate production issue,
particularly affecting data integrity, or whether it can be picked up during normal sprint planning.
If it's an immediate production issue, you should escalate to the tech lead for the affected feature,
and consult with them about next steps. If it's an outage of some kind, we should convene folks in #appeals-swat.
The Bat Team should do just enough investigation to determine further action.

Mark the Sentry alert in Slack with the green checkmark emoji when it has been triaged, and you can ignore the alert
in Sentry for a week.

