import _ from 'lodash';
import { formatDate, formatDateStr, formatDateStringForApi } from '../../util/DateUtil';
import DATES from '../../../constants/DATES.json';

const getNonVeteranClaimant = (intakeData) => {
  const claimant = intakeData.relationships.filter((relationship) => {
    return relationship.value === intakeData.claimant;
  });

  return `${claimant[0].displayText} (payee code ${intakeData.payeeCode})`;
};

const getClaimantField = (formType, veteran, intakeData) => {
  if (formType === 'appeal' || intakeData.benefitType === 'compensation') {
    const claimant = intakeData.claimantNotVeteran ? getNonVeteranClaimant(intakeData) : veteran.name;

    return [{
      field: 'Claimant',
      content: claimant
    }];
  }

  return [];
};

export const formatRatings = (ratings, requestIssues = []) => {
  const result = _.keyBy(_.map(ratings, (rating) => {
    return _.assign(rating,
      { issues: _.keyBy(rating.issues, 'reference_id') }
    );
  }), 'profile_date');

  _.forEach(requestIssues, (requestIssue) => {
    // filter out nil dates (request issues that are not yet rated)
    if (requestIssue.reference_id) {
      _.forEach(result, (rating) => {
        if (rating.issues[requestIssue.reference_id]) {
          rating.issues[requestIssue.reference_id].isSelected = true;
        }
      });
    }
  });

  return result;
};

export const validateDate = (date) => {
  const datePattern = /^(0[1-9]|1[0-2])[/](0[1-9]|[12][0-9]|3[01])[/](19|20)\d\d$/;

  if (datePattern.test(date)) {
    return date;
  }

  return null;
};

export const validNonratingRequestIssue = (issue) => {
  const unvalidatedDate = issue.decisionDate;
  const decisionDate = validateDate(unvalidatedDate);

  if (!issue.description) {
    return false;
  }
  // If there isn't any nonRatingRequest category, return 0
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

  // If we've gotten to here, that means we've got all necessary parts for a nonRatingRequestIssue to count
  return true;
};

// formatRequestIssues takes an array of requestIssues in the server ui_hash format
// and returns objects useful for displaying in UI
export const formatRequestIssues = (requestIssues) => {
  return requestIssues.map((issue) => {
    if (issue.category) {
      return {
        isRating: false,
        category: issue.category,
        description: issue.description,
        decisionDate: issue.decision_date,
        ineligibleReason: issue.ineligible_reason,
        contentionText: issue.contention_text
      };
    }

    // Unidentified issues
    if (issue.is_unidentified) {
      return {
        description: issue.description,
        contentionText: issue.contention_text,
        notes: issue.notes,
        isUnidentified: issue.is_unidentified
      };
    }

    // Rating issues
    const issueDate = new Date(issue.profile_date);

    return {
      isRating: true,
      id: issue.reference_id,
      profileDate: issueDate.toISOString(),
      notes: issue.notes,
      description: issue.description,
      ineligibleReason: issue.ineligible_reason,
      titleOfActiveReview: issue.title_of_active_review,
      contentionText: issue.contention_text,
      rampClaimId: issue.ramp_claim_id
    };
  });
};

const ratingIssuesById = (ratings) => {
  return _.reduce(ratings, (result, rating) => {
    _.forEach(rating.issues, (issue, id) => {
      result[id] = issue.decision_text;
    });

    return result;
  }, {});
};

export const issueById = (ratings, issueId) => {
  const currentRating = _.filter(
    ratings,
    (ratingDate) => _.some(ratingDate.issues, { reference_id: issueId })
  )[0];

  return currentRating.issues[issueId];
};

const formatUnidentifiedIssues = (state) => {
  // only used for the new add intake flow
  if (state.addedIssues && state.addedIssues.length > 0) {
    return state.addedIssues.
      filter((issue) => issue.isUnidentified).
      map((issue) => {
        return {
          decision_text: issue.description,
          notes: issue.notes,
          is_unidentified: true
        };
      });
  }

  return [];
};

const formatRatingRequestIssues = (state) => {
  const ratingIssues = ratingIssuesById(state.ratings);

  if (state.addedIssues && state.addedIssues.length > 0) {
    // we're using the new add issues page
    return state.addedIssues.
      filter((issue) => issue.isRating && !issue.isUnidentified).
      map((issue) => {
        return {
          reference_id: issue.id,
          decision_text: ratingIssues[issue.id],
          profile_date: issue.profileDate,
          notes: issue.notes,
          untimely_exemption: issue.untimelyExemption,
          untimely_exemption_notes: issue.untimelyExemptionNotes,
          ramp_claim_id: issue.rampClaimId
        };
      });
  }

  // default to original ratings format
  return _(state.ratings).
    map((rating) => {
      return _.map(rating.issues, (issue) => {
        return _.merge(issue, { profile_date: rating.profile_date });
      });
    }).
    flatten().
    filter('isSelected').
    value();
};

const formatNonratingRequestIssues = (state) => {
  if (state.addedIssues && state.addedIssues.length > 0) {
    // we're using the new add issues page
    return state.addedIssues.filter((issue) => !issue.isRating && !issue.isUnidentified).map((issue) => {
      return {
        issue_category: issue.category,
        decision_text: issue.description,
        decision_date: formatDateStringForApi(issue.decisionDate)
      };
    });
  }

  // default to original format
  return _(state.nonRatingRequestIssues).
    filter((issue) => {
      return validNonratingRequestIssue(issue);
    }).
    map((issue) => {
      return {
        decision_text: issue.description,
        issue_category: issue.category,
        decision_date: formatDateStringForApi(issue.decisionDate)
      };
    }).
    value();
};

export const formatIssues = (state) => {
  const ratingData = formatRatingRequestIssues(state);
  const nonRatingData = formatNonratingRequestIssues(state);
  const unidentifiedData = formatUnidentifiedIssues(state);

  const data = {
    request_issues: _.concat(ratingData, nonRatingData, unidentifiedData)
  };

  return data;
};

export const getAddIssuesFields = (formType, veteran, intakeData) => {
  let fields;

  switch (formType) {
  case 'higher_level_review':
    fields = [
      { field: 'Benefit type',
        content: _.startCase(intakeData.benefitType) },
      { field: 'Informal conference request',
        content: intakeData.informalConference ? 'Yes' : 'No' },
      { field: 'Same office request',
        content: intakeData.sameOffice ? 'Yes' : 'No' }
    ];
    break;
  case 'supplemental_claim':
    fields = [
      { field: 'Benefit type',
        content: _.startCase(intakeData.benefitType) }
    ];
    break;
  case 'appeal':
    fields = [
      { field: 'Review option',
        content: _.startCase(intakeData.docketType.split('_').join(' ')) }
    ];
    break;
  default:
    fields = [];
  }

  let claimantField = getClaimantField(formType, veteran, intakeData);

  return fields.concat(claimantField);
};

export const formatAddedIssues = (intakeData, useAmaActivationDate = false) => {
  let issues = intakeData.addedIssues || [];
  let ratingIssues = ratingIssuesById(intakeData.ratings);
  // match date definition in Rails Rating model
  const ONE_YEAR_PLUS_MS = 1000 * 60 * 60 * 24 * 372;

  const amaActivationDate = new Date(useAmaActivationDate ? DATES.AMA_ACTIVATION : DATES.AMA_ACTIVATION_TEST);

  return issues.map((issue) => {
    if (issue.isUnidentified) {
      return {
        referenceId: issue.id,
        text: `Unidentified issue: no issue matched for "${issue.description}"`,
        notes: issue.notes,
        isUnidentified: true
      };
    } else if (issue.isRating) {
      const profileDate = new Date(issue.profileDate);

      return {
        referenceId: issue.id,
        text: ratingIssues[issue.id],
        date: formatDateStr(issue.profileDate),
        notes: issue.notes,
        titleOfActiveReview: issue.titleOfActiveReview,
        sourceHigherLevelReview: issue.sourceHigherLevelReview,
        promulgationDate: issue.promulgationDate,
        profileDate: issue.profileDate,
        timely: issue.timely,
        beforeAma: profileDate < amaActivationDate && !issue.rampClaimId,
        untimelyExemption: issue.untimelyExemption,
        untimelyExemptionNotes: issue.untimelyExemptionNotes,
        ineligibleReason: issue.ineligibleReason,
        rampClaimId: issue.rampClaimId
      };
    }

    // we must do our own date math for nonrating request issues.
    // we assume the timezone of the browser for all these.
    let decisionDate = new Date(issue.decisionDate);
    let receiptDate = new Date(intakeData.receiptDate);
    let isTimely = (receiptDate - decisionDate) <= ONE_YEAR_PLUS_MS;

    // returns nonrating request issue format
    return {
      referenceId: issue.id,
      text: `${issue.category} - ${issue.description}`,
      date: formatDate(issue.decisionDate),
      timely: isTimely,
      beforeAma: decisionDate < amaActivationDate,
      ineligibleReason: issue.ineligibleReason
    };
  });
};
