---
title: Caseflow Intake
weight: 2
---

# Caseflow Intake
* [Intake](https://github.com/department-of-veterans-affairs/appeals-team/wiki/Intake)
* [Caseflow Intake](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Intake)
* [Intake Data Model](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model)
* [Intake tables diagram](https://dbdiagram.io/d/5fc9027b3a78976d7b7e6700)

## Decision Reviews
Intake is the source of all AMA decision review request submissions. There are three decision review lanes: Appeals, HigherLevelReviews, and SupplementalClaims.

Class diagram of relevant terminology:
* [DecisionReview](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#decisionreview)
   - [Appeal](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#appeal)
   - [ClaimReview](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#claimreview)
      - [SupplementalClaim](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#supplementalclaim)
      - [HigherLevelReview](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#higherlevelreview)

### Appeals
[Appeals](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#appeal) represent an AMA review that gets filed with the Board of Veterans' Appeals (BVA). Refer to Intake tables diagram below.
* `docket_type` can be one of the following:
   * `direct_review` - No new evidence and not requesting a hearing
   * `evidence_submission` - New evidence but not requesting a hearing
   * `hearing` - Submit new evidence and want to testify before a VLJ
* `poa_participant_id`: Power of Attorney (POA) is connected to legacy appeals in VACOLS and Veterans in BGS. Since this model represents AMA appeals, we are getting this data from [BGS](https://github.com/department-of-veterans-affairs/caseflow/wiki/Data%3A-where-and-why)
* `veteran_is_not_claimant`: A claimant on an appeal does not have to be the Veteran. It can be a spouse, child, or even an attorney.

## Claim Reviews (i.e., HigherLevelReviews and SupplementalClaims)
A [HigherLevelReview](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#higher-level-review) and [SupplementalClaim](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#supplementalclaim) are a type of [ClaimReviews](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#claimreview). These ClaimReviews are sent to the Veterans Benefit Administration (VBA) and differentiate from Appeals in that they include a benefit type. Benefit types of `compensation` and `pension` are processed in VBMS, where as the rest are processed in Caseflow.

## RequestIssues
[RequestIssues](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#requestissue) are submitted as part of a DecisionReview and represent a specific issue a Veteran is facing, such as hearing loss or sleep apnea. There are three categories of RequestIssues: `rating`, `non-rating`, and `unidentified`.

## EndProductEstablishments
The [EndProductEstablishment](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#endproductestablishment) model exists in Caseflow to represent [EndProducts](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#endproduct) created in VBMS. End Products are created for Higher Level Reviews and Supplemental Claims that are compensation or pensions and for Board Grant Effectuations that have granted compensation and pension issues on appeals.

## Relationships
In the diagram below you can see that the `appeals`, `supplemental_claims`, and `higher_level_reviews` table's `id` will correspond with the `request_issues` table's `decision_review_id` as well as the `end_product_establishments` table's `source_id`.

Also note that the `request_issues` table's `id` is referenced by the `end_product_establishments` table. The `end_product_establishments` table's `source_type` is the same as the `request_issues` table's `decision_review_type`.

<img src="https://user-images.githubusercontent.com/63597932/116121937-223eb080-a68f-11eb-9625-fa9cca7c9201.png" width=800>
