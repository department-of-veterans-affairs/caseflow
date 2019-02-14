import _ from 'lodash';
import { formatDateStr, formatDateStringForApi } from '../../util/DateUtil';
import DATES from '../../../constants/DATES.json';
import { FORM_TYPES } from '../constants';

const getNonVeteranClaimant = (intakeData) => {
  const claimant = intakeData.relationships.filter((relationship) => {
    return relationship.value === intakeData.claimant;
  });

  if (!intakeData.payeeCode) {
    return claimant[0].displayText;
  }

  return `${claimant[0].displayText} (payee code ${intakeData.payeeCode})`;
};

const getClaimantField = (formType, veteran, intakeData) => {
  if (formType === 'appeal' || intakeData.benefitType === 'compensation') {
    const claimant = intakeData.veteranIsNotClaimant ? getNonVeteranClaimant(intakeData) : veteran.name;

    return [{
      field: 'Claimant',
      content: claimant
    }];
  }

  return [];
};

export const legacyIssue = (issue, legacyAppeals) => {
  if (issue.vacolsIssue) {
    return issue.vacolsIssue;
  }

  let legacyAppeal = _.filter(legacyAppeals, { vacols_id: issue.vacolsId })[0];

  if (!legacyAppeal) {
    throw new Error(`No legacyAppeal found for '${issue.vacolsId}'`);
  }

  return _.filter(legacyAppeal.issues, { vacols_sequence_id: parseInt(issue.vacolsSequenceId, 10) })[0];
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
  if (!issue.benefitType) {
    return false;
  }

  // If we've gotten to here, that means we've got all necessary parts for a nonRatingRequestIssue to count
  return true;
};

const contestableIssueIndexByRequestIssue = (contestableIssuesByDate, requestIssue) => {
  const foundContestableIssue = _.reduce(contestableIssuesByDate, (foundIssue, contestableIssues) => {
    return foundIssue || _.find(contestableIssues, {
      decisionIssueId: requestIssue.contested_decision_issue_id,
      ratingIssueReferenceId: requestIssue.rating_issue_reference_id
    });
  }, null);

  return foundContestableIssue && foundContestableIssue.index;
};

// formatRequestIssues takes an array of requestIssues in the server ui_hash format
// and returns objects useful for displaying in UI
export const formatRequestIssues = (requestIssues, contestableIssues) => {
  return requestIssues.map((issue) => {
    // Nonrating issues
    if (issue.category) {
      return {
        id: String(issue.id),
        isRating: false,
        benefitType: issue.benefit_type,
        category: issue.category,
        decisionIssueId: issue.contested_decision_issue_id,
        description: issue.description,
        decisionDate: formatDateStr(issue.decision_date),
        ineligibleReason: issue.ineligible_reason,
        ineligibleDueToId: issue.ineligible_due_to_id,
        reviewRequestTitle: issue.review_request_title,
        contentionText: issue.contention_text,
        untimelyExemption: issue.untimelyExemption,
        untimelyExemptionNotes: issue.untimelyExemptionNotes,
        vacolsId: issue.vacols_id,
        vacolsSequenceId: issue.vacols_sequence_id,
        vacolsIssue: issue.vacols_issue
      };
    }

    // Unidentified issues
    if (issue.is_unidentified) {
      return {
        id: String(issue.id),
        description: issue.description,
        contentionText: issue.contention_text,
        notes: issue.notes,
        isUnidentified: issue.is_unidentified,
        vacolsId: issue.vacols_id,
        vacolsSequenceId: issue.vacols_sequence_id,
        vacolsIssue: issue.vacols_issue
      };
    }

    // Rating issues
    const issueDate = new Date(issue.rating_issue_profile_date);

    return {
      id: String(issue.id),
      index: contestableIssueIndexByRequestIssue(contestableIssues, issue),
      isRating: true,
      ratingIssueReferenceId: issue.rating_issue_reference_id,
      ratingIssueProfileDate: issueDate.toISOString(),
      date: issue.decision_date,
      decisionIssueId: issue.contested_decision_issue_id,
      notes: issue.notes,
      description: issue.description,
      ineligibleReason: issue.ineligible_reason,
      ineligibleDueToId: issue.ineligible_due_to_id,
      titleOfActiveReview: issue.title_of_active_review,
      contentionText: issue.contention_text,
      rampClaimId: issue.ramp_claim_id,
      untimelyExemption: issue.untimelyExemption,
      untimelyExemptionNotes: issue.untimelyExemptionNotes,
      vacolsId: issue.vacols_id,
      vacolsSequenceId: issue.vacols_sequence_id,
      vacolsIssue: issue.vacols_issue
    };
  });
};

export const formatContestableIssues = (contestableIssues) => {
  // order by date, otherwise all decision issues will always
  // come after rating issues regardless of date
  const orderedContestableIssues = _.orderBy(contestableIssues, ['date'], ['desc']);

  return orderedContestableIssues.reduce((contestableIssuesByDate, contestableIssue, index) => {
    contestableIssue.index = String(index);

    contestableIssuesByDate[contestableIssue.date] = contestableIssuesByDate[contestableIssue.date] || {};
    contestableIssuesByDate[contestableIssue.date][index] = contestableIssue;

    return contestableIssuesByDate;
  }, {});
};

export const issueByIndex = (contestableIssuesByDate, issueIndex) => {
  const currentContestableIssueGroup = _.filter(
    contestableIssuesByDate,
    (contestableIssues) => _.some(contestableIssues, { index: issueIndex })
  )[0];

  return currentContestableIssueGroup[issueIndex];
};

const formatUnidentifiedIssues = (state) => {
  return (state.addedIssues || []).
    filter((issue) => issue.isUnidentified).
    map((issue) => {
      return {
        request_issue_id: issue.id,
        decision_text: issue.description,
        notes: issue.notes,
        is_unidentified: true
      };
    });
};

const formatRatingRequestIssues = (state) => {
  return (state.addedIssues || []).
    filter((issue) => issue.isRating && !issue.isUnidentified).
    map((issue) => {
      return {
        request_issue_id: issue.id,
        rating_issue_reference_id: issue.ratingIssueReferenceId,
        decision_text: issue.description,
        rating_issue_profile_date: issue.ratingIssueProfileDate,
        rating_issue_diagnostic_code: issue.ratingIssueDiagnosticCode,
        notes: issue.notes,
        untimely_exemption: issue.untimelyExemption,
        untimely_exemption_notes: issue.untimelyExemptionNotes,
        ramp_claim_id: issue.rampClaimId,
        vacols_id: issue.vacolsId,
        vacols_sequence_id: issue.vacolsSequenceId,
        contested_decision_issue_id: issue.decisionIssueId,
        ineligible_reason: issue.ineligibleReason,
        ineligible_due_to_id: issue.ineligibleDueToId
      };
    });
};

const formatNonratingRequestIssues = (state) => {
  return (state.addedIssues || []).filter((issue) => !issue.isRating && !issue.isUnidentified).map((issue) => {
    return {
      request_issue_id: issue.id,
      contested_decision_issue_id: issue.decisionIssueId,
      benefit_type: issue.benefitType,
      issue_category: issue.category,
      decision_text: issue.description,
      decision_date: formatDateStringForApi(issue.decisionDate),
      untimely_exemption: issue.untimelyExemption,
      untimely_exemption_notes: issue.untimelyExemptionNotes,
      vacols_id: issue.vacolsId,
      vacols_sequence_id: issue.vacolsSequenceId,
      ineligible_due_to_id: issue.ineligibleDueToId,
      ineligible_reason: issue.ineligibleReason
    };
  });
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
  const veteranInfo = `${veteran.name} (${veteran.fileNumber})`;
  const selectedForm = _.find(FORM_TYPES, { key: formType });

  switch (formType) {
  case 'higher_level_review':
    fields = [
      { field: 'Form',
        content: selectedForm.name },
      { field: 'Veteran',
        content: veteranInfo },
      { field: 'Receipt date of this form',
        content: formatDateStr(intakeData.receiptDate) },
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
      { field: 'Form',
        content: selectedForm.name },
      { field: 'Veteran',
        content: veteranInfo },
      { field: 'Receipt date of this form',
        content: formatDateStr(intakeData.receiptDate) },
      { field: 'Benefit type',
        content: _.startCase(intakeData.benefitType) }
    ];
    break;
  case 'appeal':
    fields = [
      { field: 'Veteran',
        content: veteranInfo },
      { field: 'NOD receipt date',
        content: formatDateStr(intakeData.receiptDate) },
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
      // todo: date works for contestable issue
      // and profile_date works for request issue (for the edit page)
      // fix this to use same keys
      const profileDate = new Date(issue.date || issue.profileDate);

      return {
        referenceId: issue.id,
        text: issue.description,
        date: formatDateStr(profileDate),
        notes: issue.notes,
        titleOfActiveReview: issue.titleOfActiveReview,
        sourceReviewType: issue.sourceReviewType,
        promulgationDate: issue.promulgationDate,
        profileDate,
        timely: issue.timely,
        beforeAma: profileDate < amaActivationDate && !issue.rampClaimId,
        untimelyExemption: issue.untimelyExemption,
        untimelyExemptionNotes: issue.untimelyExemptionNotes,
        ineligibleReason: issue.ineligibleReason,
        rampClaimId: issue.rampClaimId,
        vacolsId: issue.vacolsId,
        vacolsSequenceId: issue.vacolsSequenceId,
        vacolsIssue: issue.vacolsIssue,
        eligibleForSocOptIn: issue.eligibleForSocOptIn
      };
    }

    const decisionDate = new Date(issue.decisionDate);

    // returns nonrating request issue format
    return {
      referenceId: issue.id,
      text: issue.decisionIssueId ? issue.description : `${issue.category} - ${issue.description}`,
      benefitType: issue.benefitType,
      date: formatDateStr(issue.decisionDate),
      timely: issue.timely,
      beforeAma: decisionDate < amaActivationDate,
      untimelyExemption: issue.untimelyExemption,
      untimelyExemptionNotes: issue.untimelyExemptionNotes,
      ineligibleReason: issue.ineligibleReason,
      vacolsId: issue.vacolsId,
      vacolsSequenceId: issue.vacolsSequenceId,
      vacolsIssue: issue.vacolsIssue,
      eligibleForSocOptIn: issue.eligibleForSocOptIn,
      reviewRequestTitle: issue.reviewRequestTitle
    };
  });
};
