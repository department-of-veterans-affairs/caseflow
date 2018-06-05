import _ from 'lodash';
import { REVIEW_OPTIONS } from '../constants';

export const getAppealDocketError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.appeal_docket, 0) === 'blank') && 'Please select an option.'
);

export const getOptionSelectedError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.option_selected, 0) === 'blank') && 'Please select an option.'
);

export const getReceiptDateError = (responseErrorCodes, state) => (
  {
    blank:
      'Please enter a valid receipt date.',
    in_future:
      'Receipt date cannot be in the future.',
    before_ramp: 'Receipt Date cannot be earlier than RAMP start date, 11/01/2017.',
    before_ama: 'Receipt Date cannot be earlier than the AMA pilot start date.',
    before_ramp_receipt_date: 'Receipt date cannot be earlier than the original ' +
      `RAMP election receipt date of ${state.electionReceiptDate}`
  }[_.get(responseErrorCodes.receipt_date, 0)]
);

export const toggleIneligibleError = (hasInvalidOption, selectedOption) => (
  hasInvalidOption && Boolean(selectedOption === REVIEW_OPTIONS.HIGHER_LEVEL_REVIEW.key ||
    selectedOption === REVIEW_OPTIONS.HIGHER_LEVEL_REVIEW_WITH_HEARING.key)
);

export const formatRatings = (ratings) => {
  return _.keyBy(_.map(ratings, (rating) => {
    return _.assign(rating,
      { issues: _.keyBy(rating.issues, 'reference_id') }
    );
  }), 'profile_date');
};

export const formatRatingData = (intakeState) => {
  const ratingData = {
    request_issues:
      _(intakeState.ratings).
        map((rating) => {
          return _.map(rating.issues, (issue) => {
            return _.merge(issue, { profile_date: rating.profile_date });
          });
        }).
        flatten().
        filter('isSelected')
  };

  const nonRatingData = {
    request_issues:
      _(intakeState.nonRatedIssues).map((issue) => {
        return {
          decision_text: issue.description,
          issue_category: issue.category
        };
      }).filter('issue_category')
  };

  const data = {
    request_issues: _.concat(ratingData.request_issues.value(), nonRatingData.request_issues.value())
  };

  return data;
};
