import DISTRIBUTION from '../../constants/DISTRIBUTION';

const LEVERS = 'levers';

export const Constant = {
  LEVERS
};

export const sectionTitles = {
  [DISTRIBUTION.ama_hearing_start_distribution_prior_to_goals]: DISTRIBUTION.ama_hearings_section_title,
  [DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals]: DISTRIBUTION.ama_direct_review_section_title,
  [DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals]: DISTRIBUTION.ama_evidence_submission_section_title
};

export const docketTimeGoalPriorMappings = {
  [DISTRIBUTION.ama_hearing_start_distribution_prior_to_goals]:
    DISTRIBUTION.ama_hearing_docket_time_goals,
  [DISTRIBUTION.ama_direct_review_start_distribution_prior_to_goals]:
    DISTRIBUTION.ama_direct_review_docket_time_goals,
  [DISTRIBUTION.ama_evidence_submission_start_distribution_prior_to_goals]:
    DISTRIBUTION.ama_evidence_submission_docket_time_goals
};
