import _ from 'lodash';
import { REVIEW_OPTIONS } from '../constants';
import { formatDateStringForApi } from '../../util/DateUtil';

export const getAppealDocketError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.appeal_docket, 0) === 'blank') && 'Please select an option.'
);

export const getOptionSelectedError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.option_selected, 0) === 'blank') && 'Please select an option.'
);

export const getPageError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.other, 0) === 'unknown_error') && 'Unknown error.'
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

export const formatRelationships = (relationships) => {
  return relationships.map((relationship) => {
    const first = _.capitalize(relationship.first_name);
    const last = _.capitalize(relationship.last_name);
    const type = _.capitalize(relationship.relationship_type);

    return {
      value: relationship.participant_id,
      displayText: `${first} ${last}, ${type}`
    };
  });
};

export const formatIssues = (intakeState) => {
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
      _(intakeState.nonRatedIssues).
        filter((issue) => {
          return issue.category && issue.description;
        }).
        map((issue) => {
          return {
            decision_text: issue.description,
            issue_category: issue.category,
            decision_date: formatDateStringForApi(issue.decisionDate)
          };
        })
  };

  const data = {
    request_issues: _.concat(ratingData.request_issues.value(), nonRatingData.request_issues.value())
  };

  return data;
};

export const nonRatedIssueCounter = (state, action) => {
  const selectedIssues = formatIssues(state).request_issues;
  const selectedIssueCount = selectedIssues ? selectedIssues.length : 0;
  const currentIssue = state.nonRatedIssues[action.payload.issueId];
  const descriptionCounter = !currentIssue.description && currentIssue.category ? 1 : 0;
  const categoryCounter = !currentIssue.category && currentIssue.description ? 1 : 0;

  if (selectedIssueCount && !action.payload.category && !action.payload.description) {
    return selectedIssueCount - 1;
  }

  if (action.payload.description) {
    return selectedIssueCount + descriptionCounter;
  }

  if (action.payload.category) {
    return selectedIssueCount + categoryCounter;
  }
};

export const prepareReviewData = (intakeData, intakeType) => {
  switch (intakeType) {
  case 'appeal':
    return {
      docket_type: intakeData.docketType,
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant
    };
  case 'supplementalClaim':
    return {
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant
    };
  case 'higherLevelReview':
    return {
      informal_conference: intakeData.informalConference,
      same_office: intakeData.sameOffice,
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant
    };
  default:
    return {
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant
    };
  }
};
