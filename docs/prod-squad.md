# Prod Squad

![watchers on the wall](http://i.imgur.com/7X1OBRu.png)

Prod Squad is a rotating assignment with two people are responsible for daily operations of Caseflow. Our rationale is based on the following:

1. In the worst case, a single `500` can ruin a veteran's life. 
1. We don't have enough pure DevOps people to ask them to be solely responsible for operating the site.
1. Operational stability is everyone's responsibility, and having people take turns on prod squad reinforces that.

## When you're on prod squad

You must respond to every error logged in #appeals-devops-alerts. You are not expected the fix everything, but you are the first line of defense to determine if we have a serious problem or not. This is a painful job if there are many alerts, so it's on all of us to silence alerts that are not meaningful.

When you're on prod squad, it's expected that you will make less progress than usual on normal sprint work, because of your prod squad duties. Take this into account during sprint planning. You are expected to be constantly monitoring the #appeals-devops-alerts channel to be responsive to alerts.

### Sentry Errors

The procedure for responding to a new alert in #appeals-devops-alerts is:

1. If the error is obviously meaningless, silence it in Sentry.
1. Otherwise, make a ticket for the error. Label it with `prod-alert`. If a ticket already exists for the error, comment on the existing ticket with a link to the latest occurrence.
1. Determine the impact of the error. Is this going to hurt a veteran, or is it just noise?
    1. **You're not totally sure:** Ping the tech lead for the team responsible for the error. See the [table below](#responsibility-for-errors) to determine who to ping if you're not sure.
    1. **Obviously annoying to end users, but not corrupting data or causing a major user work stoppage:** 
        1. If you know what the error is, and it's easy to fix, fix it immediately. 
        1. If you don't know what the error is, but you're sure that it's too insignificant to be worth fixing, either:
            1. *Preferred:* `catch` or `rescue` the error in the code. Continue to log it, but do not send it to Sentry.
            1. Silence the error via the Sentry UI.
        1. If you don't know what the error is or how to fix it, batch up all such errors, and tell the relevant tech leads at the end of the day or end of the week.
    1. **Potentially corrupting data or causing a major user work stoppage:** Ping the following people immediately:
        1. The tech lead of the relevant app
        1. DevOps lead (Alan Ning)
        1. Project tech lead (Nick Heiner)

This procedure only needs to be done during business hours. When you start work in the morning, review errors that happened after close of business the prior day.

### Backup
If you are unavailable at any time during your prod squad rotation, whether it's because you're on vacation or out for an appointment in the afternoon, you're responsible for finding someone to replace you.

## Who is on prod squad
All engineers with VA email addresses participate in prod squad. The VA email address gives the ability to access our production systems.

If you are on prod squad, you must have access to the following:

1. PagerDuty
1. CloudWatch logs
1. Sentry

If you don't have access to everything on this list, talk to your team lead about getting access.

## Responsibility for Errors
| App | Team | Tech Lead |
| --- | --- | --- |
| Reader | Whiskey | Mark |
| Certification | Foxtrot | Alex |
| Certification v2 | Foxtrot | Alex |
| eFolder | Foxtrot | Alex |
| Dispatch | Tango | Sharon |
| Hearings Prep | Tango | Sharon |

All the tech leads need to be responsible for prioritizing triaging errors and either silencing or fixing them. We can't be complacent, like we were with the flakey tests, and wait until there's a crisis. 
