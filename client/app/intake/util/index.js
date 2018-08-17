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

export const validateDate = (date) => {
  const datePattern = /^(0[1-9]|1[0-2])[/](0[1-9]|[12][0-9]|3[01])[/](19|20)\d\d$/;

  if (datePattern.test(date)) {
    return date;
  }

  return null;
};

export const validNonRatedIssue = (issue) => {
  const unvalidatedDate = issue.decisionDate;
  const decisionDate = validateDate(unvalidatedDate);

  if (!issue.description) {
    return false;
  }
  // If there isn't any nonRated category, return 0
  if (!issue.category) {
    return false;
  }
  // If category is unknown issue category, no decision date is necessary.
  if (issue.category === 'Unknown issue category') {
    return true;
  }
  // If category isn't unknown or there's no valid decisionDate, return 0
  if (!decisionDate) {
    return false;
  }

  // If we've gotten to here, that means we've got all necessary parts for a nonRatedIssue to count
  return true;
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
          return validNonRatedIssue(issue);
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

export const prepareReviewData = (intakeData, intakeType) => {
  switch (intakeType) {
  case 'appeal':
    return {
      docket_type: intakeData.docketType,
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant,
      payee_code: intakeData.payeeCode
    };
  case 'supplementalClaim':
    return {
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant,
      payee_code: intakeData.payeeCode
    };
  case 'higherLevelReview':
    return {
      informal_conference: intakeData.informalConference,
      same_office: intakeData.sameOffice,
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant,
      payee_code: intakeData.payeeCode
    };
  default:
    return {
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant,
      payee_code: intakeData.payeeCode
    };
  }
};
