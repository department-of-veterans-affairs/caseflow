-- Example SQL for pull Decision Reviews and related data for a specific Line of Business

-- Line of Business is tracked via "benefit_type" on the "request_issues" table
-- In these examples we are using "vha"

select * from request_issues where benefit_type = "vha";

-- Find the related Decision Reviews

select * from appeals where id in (
  select decision_review_id
  from request_issues
  where decision_review_type = "Appeal"
    and benefit_type = "vha"
);

select * from higher_level_reviews where benefit_type = "vha";
select * from supplemental_claims where benefit_type = "vha";

-- With the related Veterans

select * from appeals, veterans where veterans.file_number = appeals.veteran_file_number
  and appeals.id in (
    select decision_review_id from request_issues
    where decision_review_type = "Appeal" and benefit_type = "vha"
  );

select * from higher_level_reviews, veterans
 where higher_level_reviews.veteran_file_number = veterans.file_number
  and higher_level_reviews.benefit_type = "vha";

select * from supplemental_claims, veterans
  where supplemental_claims.veteran_file_number = veterans.file_number
   and supplemental_claims.benefit_type = "vha";

-- Find the decision issues

select * from decision_issues
 where decision_review_type = "Appeal"
 and decision_review_id in (
  select decision_review_id
  from request_issues
  where decision_review_type = "Appeal"
    and benefit_type = "vha"
);

select * from decision_issues
 where decision_review_type = "HigherLevelReview"
 and decision_review_id in (select id from higher_level_reviews where benefit_type = "vha");

select * from decision_issues
 where decision_review_type = "SupplementalClaim"
 and decision_review_id in (select id from supplemental_claims where benefit_type = "vha");

