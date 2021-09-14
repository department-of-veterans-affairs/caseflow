---
parent: Workflows
nav_order: 2
tags: ["workflow", "intake"]
---
# Intake Workflow

Intake creates data that can trace a claim through its initial decision, through any requests to contest that decision or subsequent decisions, all the way to the final decision(s).

It helps present data to veterans in the same way they already view decision reviews, as an extension to their original claim.

[Issues presentation](https://github.com/department-of-veterans-affairs/appeals-team/blob/master/Project%20Folders/Caseflow%20Projects/Intake/AMA%20ISSUES.pdf)

## Mail Intake

{% mermaid %}
graph TD

claim --> claim_decision
claim_decision --> V[Veteran]

V --> |form| BvaMail[BVA mail intake]
BvaMail -.- NOD
BvaMail -.- mailPortal[Mail Portal]
mailPortal --> |documents| vbmsEFolder[VBMS eFolder]

BvaMail --> docket{docket?}
BvaMail --> TranslationTask

BvaMail --> |change POA| PoaMailTask
PoaMailTask --> newTrackVet[new TrackVeteranTask]
PoaMailTask --> |if necessary| newIHP[new IHPTask]

BvaMail --> AodMailTask
AodMailTask -.- |decided by| VLJ

docket --> |if H| Hearing
Hearing -.- |presided by| VLJ
Hearing --> ACD
ACD --> Decision
%% Decision -.- VLJ
Decision --> Dispatch

docket --> |if ES| EvidenceSubmissionWindowTask
EvidenceSubmissionWindowTask --> ACD

BvaMail --> TrackVeteranTask
VSO -.- TrackVeteranTask
VSO --> |if IHP-writing VSO| IHPTask
{% endmermaid %}


{% mermaid %}
graph TD
validate[Validate form]
validate --> add_issues[add issues from veteran's decision review]
add_issues --> |match to| decision
add_issues --> |same issue as| legacy
{% endmermaid %}

## Business Lines

Once Intake is done, there are 3 major flows for AMA decision review:
1. HLR & SC (Compensation and Pension) - in VBMS
  * Request issues are represented as *contentions* on EPs in VBMS
  * Request issues (in the same appeal) can map to contentions in different EPs.
  * Once EP is cleared/completed, Caseflow loads the new rating issues (and dispositions) to create VA decision issues on AMA decision reviews.
  * A decision issue maps to only one rating issue or nothing.
2. HLR & SC (other business lines) - in Caseflow
  * One queue for each non-VBMS business line.
  * No EPs or contentions. For each request issue, create a decision issue with the disposition.
3. Board Appeals - in Caseflow
  * Attorneys create decision issues, not raters.
  * Dispositions on decision issues get *outcoded* to contentions on a new(?) EP, and a new rating issue is created.
  * The only purpose of the EP is to email the person of the decision.

* Only VBA Compensation and Pension business lines use ratings (and VBMS).
* The 7 other business lines use nonrating request issues.
* Unidentified issues should be resolved before making decisions on them.
  Otherwise, they will be considered ineligible.

{% mermaid %}
graph TD
bizlines{business lines}
mailPortal[Mail Portal]
mailPortal --> |documents| vbmsEFolder[VBMS eFolder]
bizlines --> |Compensation| mailPortal
bizlines --> |Pension| mailPortal
bizlines --> |small volume| manual[NCA, Fiduciary, VHA, Loan Guaranty, Eudcation, Insurance]

bizlines --> |performs| record_request
record_request --> |document| bizlines
{% endmermaid %}

## Decision Review Lanes

{% mermaid %}
graph TD
decision_review_lanes --> SC
decision_review_lanes --> HLR
decision_review_lanes --> Board_Appeal
SC --> |decision saved| issue_complete
HLR --> |decision saved| issue_complete

form --> |specifies| decision_review_lanes
form --> Intake[Intake within 24 hrs]
Intake --> intake_complete
Intake --> intake_cancelled
{% endmermaid %}

## Caseflow and EPs

{% mermaid %}
graph TD
EP --> |has| request_issue
request_issue --> |can result in many| decision_issue
decision_issue --> |can satisfy many| request_issue

Caseflow --> |creates in VBMS| EP
EP --> |has one or more| contention
contention --> |connects to| rating_issue
Caseflow --> close_legacy[close legacy appeal issues or legacy appeals]

Caseflow --> |polls EPs in| VBMS
VBMS --> EP_state{EP state?}
EP_state --> |cancelled| Caseflow_closes_issues
EP_state --> |cleared, takes 24hrs from BGS| Caseflow_syncs
Caseflow_syncs --> |syncs| contention_disposition

rating_issue --> Caseflow_sync_VBMS_decision_review
contention_disposition --> Caseflow_sync_VBMS_decision_review
Caseflow_sync_VBMS_decision_review --> |creates| decision_issue

Caseflow_sync_VBMS_decision_review --> dtaError{DTA error?}
dtaError --> |yes| auto_create_SC
auto_create_SC --> SupplementalClaim
{% endmermaid %}

## After Dispatched

{% mermaid %}
graph TD
board_grants --> |notified during outcode| bizline
bizline --> |confirms in Caseflow| grant_effectuation
grant_effectuation --> bizlineUsesVBMS{bizline uses VBMS?}
bizlineUsesVBMS --> |yes| Caseflow_creates_effectuation_EP
bizlineUsesVBMS --> |no| Caseflow_uses_task
{% endmermaid %}

{% mermaid %}
graph TD

Dispatch --> |dispatched| outcode
outcode --> bizline{bizline?}

bizline --> |VBMS| EP
bizline --> |VBMS| SupplementalClaim
bizline --> |VBMS| DecisionIssue

subgraph Compensation and Pension bizline worked in VBMS
    EP
    SupplementalClaim
    DecisionIssue
end

bizline --> |Non-compensation| NonCompen_SupplementalClaim
subgraph Other bizline worked in CaseflowIntake
    NonCompen_SupplementalClaim
end
{% endmermaid %}

## Intake Models
[Intake Data Model](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model)

* Ratings and rating issues are stored in the VBA Corp DB.
  * Caseflow and VBMS both use BGS, which queries Corp DB.
* Request issues can also match legacy issues in VACOLS.
  * Veteran can choose to close the VACOLS legacy issue with a disposition designating
    that it's been opted into the AMA process.

{% mermaid %}
graph TD

Veteran -.- Rating
Rating -.- RatingIssue
RequestIssue -.- Contention
RequestIssue -.- RatingIssue
RequestIssue -.- EndProductEstablishment
RequestIssue -.- DecisionIssue
DecisionIssue -.- DecisionReview
Veteran -.- EndProduct
EndProduct -.- EndProductEstablishment

ClaimReview --> |inherits| DecisionReview
SupplementalClaim --> |inherits| ClaimReview
HigherLevelReview --> |inherits| ClaimReview
Appeal --> |inherits| DecisionReview

Appeal --> |has multiple| DecisionDocument
DecisionDocument -.- BoardGrantEffectuation
{% endmermaid %}
