import DISTRIBUTION from '../../constants/DISTRIBUTION';

const LEVERS = 'levers';

export const Constant = {
  LEVERS
};

export const sectionTitles = {
  [DISTRIBUTION.ama_hearings_start_distribution_prior_to_goals]: 'AMA Hearings',
  [DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals]: 'AMA Direct Review',
  [DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals]: 'AMA Evidence Submission'
};

export const docketTimeGoalPriorMappings = {
  [DISTRIBUTION.ama_hearings_start_distribution_prior_to_goals]:
    DISTRIBUTION.ama_hearings_docket_time_goals,
  [DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals]:
    DISTRIBUTION.ama_direct_review_docket_time_goals,
  [DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals]:
    DISTRIBUTION.ama_evidence_submission_docket_time_goals
};
