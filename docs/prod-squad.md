# Prod Squad

![watchers on the wall](http://i.imgur.com/7X1OBRu.png)

Prod Squad is a rotating assignment with two people are responsible for daily operations of Caseflow. Our rationale is based on the following:

1. In the worst case, a single `500` can ruin a veteran's life. 
1. We don't have enough pure DevOps people to ask them to be solely responsible for operating the site.
1. Operational stability is everyone's responsibility, and having people take turns on prod squad reinforces that.

We have two alert rotations, staffed by different people: "Business Hours" and "Non-Business Hours". Both receive the same alerts. Because working outside of regular business hours is more painful, that rotation has more people in it.

During business hours, all alerts go first to the "Business Hours" rotation.

## Non-Business Hours

In order to have an acceptable level of uptime, our team needs to be responsive to issues outside of regular working hours.

### Proposed Staffing
* Nick
* Mike
* JD
* Alex
* Anya
* Sharon
* Artem
* Mark
* Evan
* Teja
* Shane
* Sunil (when he arrives)
* Alan

### Rotation
Each person will take one week being the primary responder. If the primary does not respond in time, Pager Duty will escalate to everyone else at the same time. This has the benefit of being simple to implement, and provides a hilarious consequence for people who are not responsive.

### On Call Hours
Monday through Saturday: 6a - 12a EST (except [business hours](#Business-Hours-On-Call))
Sunday and federal holidays: 9p - 12a EST

### Response Time SLA
Responders should acknowledge an alert within 20 minutes. Responders should be able to be at a laptop and debugging within an hour.

### Meaningful Alerts
As a team, we owe it to each other to have only meaningful alerts. If people get paged for no reason, it will cause pain, and will make people stop paying attention to the pager. It is better to under-alert than to over-alert, since they produce the same outcome, but over-alerting is more painful.

### Runbooks
We must have well-documented runbooks to help people respond to issues. We will ensure that the runbooks are ready as part of this plan.

### Comfort
We recognize that being on call can be painful, particularly in a ~~godforesaken hellscape~~ unstable environment like the VA. For many issues, the on call response will be getting in touch with the right VA team, rather than fixing anything on our end.

To have an on-call rotation with minimal pain:
* People should swap specific time to make their lives easier. ("I'm going camping this weekend – can we trade these two weekends?")
* People should swap recurring time to make their lives easier ("I'd prefer to be on call in the morning rather than the evening – how about I'll do mornings for your shift, and you can do evenings for mine?")
* If you work extra time off-hours responding to a page, feel free to deduct that time from the amount that you'll work for the week overall. So if I normally leave at 5p, but I get woken up at 6a that day to respond to a page and work on it for an hour, then I may leave at 4p.
* We will use time zones to our advantange. Shane will be on call during time that's business hours in PST but not EST. Shane will never be on call during time that's business hours in EST but not PST.

We'll have to figure out holidays when they arise. For holidays that not everyone celebrates, like Hanukkah, we should ensure that people are not on call during holidays that are relevant to them. If there are holidays that everyone on the team celebrates, like Thanksgiving, then whomever takes a shift during that time gets to skip their next shift.

## Business Hours

### Proposed Staffing
* Marian
* Alexis
* Shade
* Nolawi
* Nemo

### Business Hours On Call
Monday - Friday: 9a-5p EST

### When you're on prod squad

You must respond to every error logged in #appeals-devops-alerts. You are not expected the fix everything, but you are the first line of defense to determine if we have a serious problem or not. This is a painful job if there are many alerts, so it's on all of us to silence alerts that are not meaningful.

When you're on prod squad, it's expected that you will make less progress than usual on normal sprint work, because of your prod squad duties. Take this into account during sprint planning. You are expected to be constantly monitoring the #appeals-devops-alerts channel to be responsive to alerts.

### Sentry Errors

The procedure for responding to a new alert in #appeals-devops-alerts is:

1. Leave a threaded comment in Slack on the issue in question to say that you're looking at it. When you finish the steps here, post the result on that thread. (For example, if you create a new GitHub issue, link to it.)
1. Make a ticket for the error. Label it with `prod-alert`. 
    1. If a ticket already exists for the error, comment on the existing ticket with a link to the latest occurrence.
    1. If the error is already ticketed and obviously low-impact, temporarily silence it in Sentry.
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
        1. Product Support Team (Raven/Sandra)
1. If an issue was big enough to cause a major disruption, lead a [post mortem](#post-mortems) for it.

To deal with a specific error, see the [First Responder's Manual](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/first-responder-manual.md).

### Support Tickets
Glance at support tickets that come in. "Follow your heart", and if they seem relevant, follow the [Sentry Errors](#sentry-errors) procedure above.

This procedure only needs to be done during business hours. When you start work in the morning, review errors that happened after close of business the prior day.

### Backup
Two people are on prod squad at any given time. The primary person is responsible for following the [Sentry Errors](#sentry-errors) procedure. The secondary person takes over whenever the primary is not available. The primary is responsible for notifying the secondary when they are not available. This includes PTO, a midday appointment, or a no-laptops meeting.

## Both Business Hours and Non-Business Hours

### Post Mortems
For major outages or data corruption issues, we need to dig into the root causes of why the outage happened and take steps to prevent similar problems from happening in the future.

1. Create an issue in the appropriate repo, and label it "post-mortem".
1. Describe the details and the timeline of the outage and resolution in the issue.
1. Move the issue to In Progress, announce it to the team, and call for feedback on the issue.
1. Discuss the action items after standup with the team.

## Who is on prod squad
If you are on prod squad, you must have access to the following:

1. PagerDuty
1. [CloudWatch logs](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/cheatsheet/logs.md)
1. [Sentry](https://sentry.ds.va.gov)
1. AWS
1. Production (i.e. you can log into prod as a user)
    * Note: we are currently in the process of getting production access. It's ok if you don't have this yet.
1. [SSH into production boxes](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/ssh-user.md)
1. [appeals-deployment repo](https://github.com/department-of-veterans-affairs/appeals-deployment/tree/master/docs)

If you don't have access to everything on this list, talk to your team lead about getting access.

The Prod Squad schedule is managed via Pager Duty. See https://dsva-appeals.pagerduty.com/escalation_policies for the schedule.

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
