-- Example SQL for pull Decision Reviews and related data for a specific Line of Business

-- Line of Business is tracked via 'benefit_type' on the 'request_issues' table
-- In these examples we are using 'vha'

-- @QUERY_NAME: vha_request_issues
select * from request_issues where benefit_type = 'vha';

-- Find the related Decision Reviews
-- NOTE we must determine that the Decisions Reviews have been fully established

-- @QUERY_NAME: vha_established_appeals
select * from appeals
where established_at is not null
and id in (
  select decision_review_id
  from request_issues
  where decision_review_type = 'Appeal'
    and benefit_type = 'vha'
);

-- @QUERY_NAME: vha_established_hlrs
select * from higher_level_reviews
where establishment_processed_at is not null
  and benefit_type = 'vha';

-- @QUERY_NAME: vha_established_scs
select * from supplemental_claims
where establishment_processed_at is not null
  and benefit_type = 'vha';

-- With the related Veterans

-- @QUERY_NAME: vha_established_appeals_by_vet_filenumber
select * from appeals, veterans
where veterans.file_number = appeals.veteran_file_number
  and appeals.established_at is not null
  and appeals.id in (
    select decision_review_id from request_issues
    where decision_review_type = 'Appeal' and benefit_type = 'vha'
  );

-- @QUERY_NAME: vha_established_hlrs_by_vet_filenumber
select * from higher_level_reviews, veterans
where higher_level_reviews.veteran_file_number = veterans.file_number
  and higher_level_reviews.establishment_processed_at is not null
  and higher_level_reviews.benefit_type = 'vha';

-- @QUERY_NAME: vha_established_scs_by_vet_filenumber
select * from supplemental_claims, veterans
where supplemental_claims.veteran_file_number = veterans.file_number
  and supplemental_claims.establishment_processed_at is not null
  and supplemental_claims.benefit_type = 'vha';

-- Find the decision issues

-- @QUERY_NAME: vha_appeal_decisions
select * from decision_issues
where decision_review_type = 'Appeal'
  and decision_review_id in (
    select decision_review_id
    from request_issues
    where decision_review_type = 'Appeal'
      and benefit_type = 'vha'
);

-- @QUERY_NAME: vha_established_hlr_decisions
select * from decision_issues
where decision_review_type = 'HigherLevelReview'
  and decision_review_id in (
    select id from higher_level_reviews
    where establishment_processed_at is not null
      and benefit_type = 'vha'
);

-- @QUERY_NAME: vha_established_sc_decisions
select * from decision_issues
where decision_review_type = 'SupplementalClaim'
  and decision_review_id in (
    select id from supplemental_claims
    where establishment_processed_at is not null
      and benefit_type = 'vha'
);

