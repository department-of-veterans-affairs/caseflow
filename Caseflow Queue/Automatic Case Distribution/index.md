# Presentations
- [May 2020 Case Distribution Overview](https://docs.google.com/presentation/d/143KwMEkw55YoKRxPL3vumVFGPR3X2n23eqxrcy1tDyM/edit#slide=id.g54fd333abc_0_70)
- [November 2018 Presentation with cute robots describing how Automatic Case Distribution works](https://github.com/department-of-veterans-affairs/caseflow/files/2971837/2018-11-14.Automatic.Case.Distribution.UPDATED.pdf)

# Goal

When a Veterans Law Judge requests cases that are ready for a decision, those cases are drawn from the Board's various dockets according to a set of rules. Prior to the implementation of the Appeals Modernization Act in February 2019, there was only a single docket, and the distribution of cases could be done by hand. With AMA in place, there are now four dockets, and the rules for distribution have reached a level of complexity that this task now must be automated.

This pages describes the rules by which cases are distributed.

# Concepts

## Docket

A docket is a line. We can generally think of a docket like a first-in, first-out (FIFO) queue, however there are some exceptions to this rule. One is that a case must be "ready" to be distributed, i.e. it must have no other tasks to be completed before a decision is written. So a ready case will be distributed before a non-ready case, even if the non-ready case is ahead of it on the docket. The Board is also allowed a small amount of wiggle room so that it doesn't have to strictly observe docket order at the cost of efficiency; before AMA this was known as the "docket range," a number of cases that were close enough to the front of the line to be considered eligible to be distributed.

## Priority

If an appellant is suffering a serious illness, in financial distress, or for another sufficient cause, their appeal can be Advanced on the Docket, or prioritized. If the appellant is older than 75, their appeal is automatically AOD; otherwise, they must file a motion requesting this status.

Board decisions can be appealed to the Court of Appeals for Veterans Claims. If CAVC disagrees with the Board's decision, they will remand it back to the Board for another decision. These post-CAVC remands are also prioritized.

There is no differentiation between the various reasons for prioritizing cases. All priority cases are prioritized equally.

## Genpop

Before AMA, if a judge held a hearing with the appellant, that same judge would be required to write the decision on the appeal. We would say that this appeal is "tied to the judge." A Veteran could waive this right, enabling their appeal to go to any judge. They would be asked to do this if the judge retired, for example. At this point, their case would be deemed "genpop" — eligible to go to any judge.

Under AMA, this is no longer a requirement under law. However, it is still preferable for an appeal to go to the same judge who heard the hearing, provided they are still active at the Board.

An additional caveat, AOD appeals that are remanded by CAVC are tied to the same judge as wrote the original decision.

In the app, appeals that meet either one of these conditions are considered genpop:
- All appeals without a hearing
- All appeals with hearings, but none that are held (`disposition == "held"`)
- All appeals whose most recently held hearing is not tied to any active judge. A judge is considered active if they have logged in within the past 60 days. The hearing date is obtained by joining on the `HearingDay` table's `scheduled_for` field.

## Batch size

When a judge requests a distribution of cases, they will receive a certain number of cases in their queue. This number is called the batch size. It is a multiple of the number of attorneys on the judge's team (currently 3 x the number of attorneys). If the judge does not have their own team, for example if they are a DVC, they receive a set number of cases known as an alternative batch size (currently 15 cases).

We also can calculate a number called a total batch size, which is the sum of all of the individual judge's batch sizes. The total batch size is used as a denominator for calculating things like the optimal percentage of priority cases to distribute.

## Legacy docket range

The legacy docket combines hearing and non-hearing appeals. As a result, it is not optimal to always grab the frontmost case; there may be cases farther back on the docket that can only be distributed to this specific judge, and it will be advantageous to overall timeliness to distribute them ahead of genpop cases that could be worked by anybody. But we still need to respect docket order, and we do this, similar to how the legacy docket was manually managed, by calculating a docket range. This is the range of cases on the legacy docket that are close enough to the front of the line to be distributed.

The legacy docket range is equal to the total batch size, minus the count of priority cases, times the legacy docket proportion (see Docket Proportions below). A hearing case within that range is considered eligible to be distributed to its judge as if it was at the front of the line.

## Ready

Cases considered "ready" for distribution must have all pre-distribution tasks completed.

For AMA Appeals, this is simply determined by the state of the appeal's [distribution task](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Tasks/tasktrees/descr/DistributionTask_Organization.md). If this task has a status of "assigned", all child tasks that must be completed for distribution are either complete or cancelled, meaning the appeal is ready for distribution.

For legacy appeals, the appeal must meet the following conditions to be considered ready to distribute:
1. The appeal must be active at the board (`bfmpro` of the vacols case is "ACT")
1. The appeal must be in case storage (`bfcurloc` of the vacols case is "81" or "83")
1. The appeal must not belong to a special team at the board (`bfbox` of the vacols case is null)
1. The appeal must not have any open blocking vacols diaries (`tskdcls` is null (diary is open) and `tskactcd` is one of 'EXT', 'HCL', or 'POA' of any associated vacols diary record (diary is a blocking diary type))
1. The appeal must not have any open blocking vacols mail (`mlcompdate` is null (mail task is open) and `mltype` is NOT one of '02', '05', '08', or '13' of any associated vacols mail record (mail task is a blocking distribution type))

```ruby
appeal = LegacyAppeal.find_by(vacols_id: 3856200)

VACOLS::CaseDocket.priority_ready_appeal_vacols_ids.include? appeal.vacols_id
=> false
# Appeal is considered either not ready or not priority

appeal.aod?
=> true
# Is priority

appeal.location_code
=> "81"
# Appeal is in case storage, one of the conditions for "ready to distribute"

VACOLS::Case.find_by(bfkey: appeal.vacols_id).bfmpro
=> "ACT"
# Appeal is active, one of the conditions for "ready to distribute"

VACOLS::Case.find_by(bfkey: appeal.vacols_id).bfbox
=> nil
# Case does not belong to a special team, one of the conditions for "ready to distribute"

VACOLS::Note.where(tsktknm: appeal.vacols_id, tskdcls: nil, tskactcd: ['EXT', 'HCL', 'POA']).count
=> 0
# No blocking diary items in vacols, one of the conditions for "ready to distribute"

VACOLS::Mail.where(mlfolder: appeal.vacols_id, mlcompdate: nil).pluck(:mltype)
=> ["07"]
# There is an open blocking mail item in vacols, meaning this case is not ready to distribute
```

# AMA dockets

The Appeals Modernization Act created two new dockets, in addition to the existing "legacy" docket, and allowed VA to create as many additional dockets as it wants. VA decided to make one additional docket, bringing the total number to four.

1) *Legacy docket.* The original flavor docket. This docket contains appeals of decisions before AMA took effect. As there was previously only one docket, the legacy docket contains both hearing and non-hearing appeals. It also has an open record, meaning that evidence can be added to an appeal at any time.
1) *Direct Review docket.* This AMA docket contains appeals where the Veteran has decided they do not want to add new evidence and do not want a hearing. To encourage people to use this option, the Board has promised that the average number of days to complete appeals on this docket will be 365 days, one year.
1) *Evidence Submission docket.* On this AMA docket, a Veteran can add evidence during the 90 days after they begin their appeal. There is no timeliness goal for this docket.
1) *Hearing Request docket.* On this AMA docket, the Veteran has requested a hearing with a judge. They can also submit evidence at their hearing, or during the 90 days after the hearing.

# Policy Objectives

In designing the automatic case distribution, there were a number of policy objectives that the team sought to realize.

* Priority cases should be balanced among judges. No judge should request a distribution and receive all priority cases.
* Priority cases should be distributed quickly.
* Docket order should be respected. An appeal that has an earlier docket date should be distributed before one with a later docket date. A certain amount of allowance is made on the legacy docket, where some appeals are tied to judges. In this case, we'll want to maximize the docket efficiency, that is the extent to which we do not need to look too deep on the docket to find cases for a given judge.
* Nonpriority appeals on the Direct Review docket should receive a decision about 365 days after VA received the form starting the appeal.
* However, the Board should also start to work some Direct Review cases straight away, and not just wait for one year before starting to work the Direct Review docket. As a result, we want to ramp up to the 365 day timeline.
* The other dockets, legacy, Evidence Submission, and Hearing Request, should be balanced proportionately. That is the number of nonpriority cases distributed from each docket should be proportionate to the number of cases on each docket.
* Clearing the legacy backlog should be prioritized, but meeting the Direct Review timeliness goal is a higher priority.

# Wrangling the dockets

## Priority Target

How much of a given distribution should be priority cases? If we were to just always distribute a priority case if one was available, we would see that some judges would get far more priority cases than others, just by virtue of the timing of their request. Instead, we'll calculate an optimal number of cases for a given distribution that should be priority.

We start by [counting](https://github.com/department-of-veterans-affairs/caseflow/blob/a349110aa64f93561aa52297738dcf537ba28364/app/models/docket_coordinator.rb#L62) all of the  priority cases that are ready to be distributed on any docket. We then [divide this number by the total batch size](https://github.com/department-of-veterans-affairs/caseflow/blob/a349110aa64f93561aa52297738dcf537ba28364/app/models/concerns/ama_case_distribution.rb#L111) to get an target percentage, and then multiply by the individual judge's batch size (rounding up) to get the target number of priority cases that should be distributed.

## Docket Proportions

We don't have to worry about which docket priority cases come from; all priority cases are treated the same. But for nonpriority cases, we must balance the four dockets, calculating the percentage of cases that we want to come from each docket.

### Direct Review docket

Unlike the other dockets, cases on the Direct Review docket are distributed based on the Board's 365 day timeliness goal. We do this by giving each Direct Review case a `target_decision_date` at intake of 365 days after the `receipt_date` (this allows the Board the option of increasing the goal, while respecting the promises made to Veterans who are already in the door). We can then mark cases as due a [set number of days](https://github.com/department-of-veterans-affairs/caseflow/blob/a349110aa64f93561aa52297738dcf537ba28364/app/models/dockets/direct_review_docket.rb#L5) before their `target_decision_date`. We then [count the number of due cases](https://github.com/department-of-veterans-affairs/caseflow/blob/a349110aa64f93561aa52297738dcf537ba28364/app/models/dockets/direct_review_docket.rb#L11), and like we do with the priority target, [divide by the total batch size](https://github.com/department-of-veterans-affairs/caseflow/blob/a349110aa64f93561aa52297738dcf537ba28364/app/models/docket_coordinator.rb#L36) (this time after excluding the count of priority cases from the denominator) to get the direct review proportion.

However, this proportion would remain at zero for nearly a year, waiting for cases to become due, and this is contrary to the Board's goal of beginning to work these cases immediately. So we will also calculate an [interpolated minimum direct review proportion](https://github.com/department-of-veterans-affairs/caseflow/blob/a349110aa64f93561aa52297738dcf537ba28364/app/models/docket_coordinator.rb#L73). We use the rate at which Direct Reviews are arriving to calculate a pacesetting proportion, or the proportion of nonpriority decision capacity that would need to go to the Direct Review docket in order to keep pace with what's arriving. We will then interpolate between 0 and the pacesetting proportion based on the age of the oldest Direct Review in the system. Finally, to accelerate the curve out, we multiply this interpolated figure by the [interpolated direct review proportion adjustment](https://github.com/department-of-veterans-affairs/caseflow/blob/a349110aa64f93561aa52297738dcf537ba28364/app/models/docket_coordinator.rb#L10). This gives us a curve out of the direct review proportion that would look something like the following:

![](/assets/images/distribution-from-direct-docket.png)

The "jolt" in this chart shows when the calculation switched from using the interpolated minimum to using the standard due proportion.

The direct review proportion is also subject to a maximum. It currently cannot exceed 80%. This prevents a complete halt to work on other dockets should demand for direct reviews approach the Board's capacity.

## Balanced dockets

The other dockets are balanced proportionate to the number of cases on the docket. After the direct review proportion is deducted, the remaining proportions are divided among the other dockets according to their weight, the number of cases waiting.

The legacy docket has two exceptions to this rule. First, in addition to counting the cases on the docket, we also count the number of cases where the Agency of Original Jurisdiction has received a Notice of Disagreement but where the appeal has not yet reached the Form 9 stage. We count these cases at a 40% discount, reflecting the likelihood that they will come to the Board and providing a fuller picture of what is waiting.

Second, the legacy docket is subject to a 10% minimum. This ensures that even as the legacy docket is winnowed, VA does not let up off the gas of finishing these older cases. Note that the sum of this minimum and the direct review maximum should not exceed 100%.

# Case distribution
## Requested
When a judge requests the distribution, we distribute cases according to the following steps:

1) We distribute priority legacy cases that are tied to a judge. As many as available, up to the limit of the batch size.
1) We distribute priority AMA hearing cases that are tied to a judge. Again, as many as available.
1) We distribute nonpriority legacy cases that are tied to a judge. We'll distribute as many as available, but they must be within the legacy docket range.
1) We distribute nonpriority AMA hearing cases that are tied to a judge. As many as available.
1) At this point, we may have distributed some priority appeals. We'll deduct those appeals from the priority target to get the number of additional priority appeals that we should distribute. We ask each docket for its priority appeals that have been waiting the longest, and distribute the oldest ones up to the priority remaining number, irrespective of docket.
1) We have also potentially distributed some nonpriority appeals from the legacy and AMA hearing dockets. We'll deduct these cases from the docket proportions.
1) Now we're ready to distribute the remaining nonpriority cases from each of the dockets according to the updated docket proportions. As some of these proportions may be small, we do this by means of [stochastic allocation](https://github.com/department-of-veterans-affairs/caseflow/blob/a349110aa64f93561aa52297738dcf537ba28364/app/models/concerns/proportion_hash.rb#L31).
1) If when we try to distribute cases from a given docket, we find that it has no cases that are ready to distribute, we'll reallocate those cases among the other dockets according to the docket proportions and try again until we've found a number of cases equal to the batch size.

## Priority Push
In an effort to get priority cases to judges without waiting for them to request cases, every Monday morning, a`PushPriorityAppealsToJudgesJob` is run to push ready priority cases to judges that can receive them. Judges can receive this push if they have an active judge team in caseflow and they hav not been removed from the job. DVCs are in charge of keeping this list of judges up to date and can add and remove judges from this job from the Team Management page.

To ensure some judges are not distributed more than others, we first distribute all priority cases that are tied to a judge (non-genpop) to that respective judge. We then look at the number of cases all eligible judges have received in the last month (including the ones just distributed), calculate a target number for each judge that would get us as close to even as possible, and distribute the remaining ready priority genpop appeals based on that calculation. The board is in charge of manually handling any cases that cannot be distributed due to the associated judge being unable to receive cases (they have left the board, they are no longer a judge, they are on vacation, etc).

# Further reading
[Presentation with cute robots describing how Automatic Case Distribution works](https://github.com/department-of-veterans-affairs/caseflow/files/2971837/2018-11-14.Automatic.Case.Distribution.UPDATED.pdf)
[Jupyter Notebooks](https://github.com/department-of-veterans-affairs/docketeer)
