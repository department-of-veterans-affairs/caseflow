import _ from 'lodash';
import { formatDateStr, formatDateStrUtc } from '../../util/DateUtil';
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
    const claimant = intakeData.veteranIsNotClaimant ? getNonVeteranClaimant(intakeData) : veteran.name;

    return [{
      field: 'Claimant',
      content: claimant
    }];
};

export const isTimely = (formType, decisionDateStr, receiptDateStr) => {
    if (formType === 'supplemental_claim') {
      return true;
    }

    if(!decisionDateStr) {
      return true
    }

    const ONE_YEAR_PLUS_MS = 1000 * 60 * 60 * 24 * 372;

    // we assume the timezone of the browser for all these.
    const decisionDate = new Date(decisionDateStr)
    const receiptDate = new Date(receiptDateStr);
    const lessThanOneYear = receiptDate - decisionDate <= ONE_YEAR_PLUS_MS;
    
    return lessThanOneYear;
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

export const validateDateNotInFuture = (date) => {
  const currentDate = new Date();
  const enteredDate = new Date(date);

  if (currentDate < enteredDate) {
    return false;
  }

  return true;
};

export const validNonratingRequestIssue = (issue) => {
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
  if (!issue.decisionDate) {
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
      ratingIssueReferenceId: requestIssue.rating_issue_reference_id,
      ratingDecisionReferenceId: requestIssue.rating_decision_reference_id
    });
  }, null);

  return foundContestableIssue && foundContestableIssue.index;
};

// formatRequestIssues takes an array of requestIssues in the server ui_hash format
// and returns objects useful for displaying in UI
export const formatRequestIssues = (requestIssues, contestableIssues) => {
  if (!requestIssues) {
    return;
  }

  return requestIssues.map((issue) => {
    return {
      id: String(issue.id),
      benefitType: issue.benefit_type,
      decisionIssueId: issue.contested_decision_issue_id,
      description: issue.description,
      decisionDate: issue.approx_decision_date,
      ineligibleReason: issue.ineligible_reason,
      ineligibleDueToId: issue.ineligible_due_to_id,
      decisionReviewTitle: issue.decision_review_title,
      contentionText: issue.contention_text,
      untimelyExemption: issue.untimelyExemption,
      untimelyExemptionNotes: issue.untimelyExemptionNotes,
      vacolsId: issue.vacols_id,
      vacolsSequenceId: issue.vacols_sequence_id,
      vacolsIssue: issue.vacols_issue,
      endProductCleared: issue.end_product_cleared,
      endProductCode: issue.end_product_code,
      withdrawalDate: issue.withdrawal_date,
      editable: issue.editable,
      isUnidentified: issue.is_unidentified,
      notes: issue.notes,
      category: issue.category,
      index: contestableIssueIndexByRequestIssue(contestableIssues, issue),
      isRating: !issue.category,
      ratingIssueReferenceId: issue.rating_issue_reference_id,
      ratingDecisionReferenceId: issue.rating_decision_reference_id,
      ratingIssueProfileDate: new Date(issue.rating_issue_profile_date).toISOString(),
      approxDecisionDate: issue.approx_decision_date,
      decisionIssueId: issue.contested_decision_issue_id,
      titleOfActiveReview: issue.title_of_active_review,
      rampClaimId: issue.ramp_claim_id,
      verifiedUnidentifiedIssue: issue.verified_unidentified_issue
    };
  }
  );
};

export const formatContestableIssues = (contestableIssues) => {
  // order by date, otherwise all decision issues will always
  // come after rating issues regardless of date
  const orderedContestableIssues = _.orderBy(contestableIssues, ['approxDecisionDate'], ['desc']);

  return orderedContestableIssues.reduce((contestableIssuesByDate, contestableIssue, index) => {
    contestableIssue.index = String(index);

    contestableIssuesByDate[contestableIssue.approxDecisionDate] =
      contestableIssuesByDate[contestableIssue.approxDecisionDate] || {};
    contestableIssuesByDate[contestableIssue.approxDecisionDate][index] = contestableIssue;

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
    filter((issue) => issue.isUnidentified || issue.verifiedUnidentifiedIssue).
    map((issue) => {
      return {
        request_issue_id: issue.id,
        decision_text: issue.description,
        notes: issue.notes,
        is_unidentified: issue.isUnidentified,
        decision_date: issue.decisionDate,
        withdrawal_date: issue.withdrawalPending ? state.withdrawalDate : issue.withdrawalDate,
        correction_type: issue.correctionType,
        untimely_exemption: issue.untimelyExemption,
        untimely_exemption_notes: issue.untimelyExemptionNotes,
        untimely_exemption_covid: issue.untimelyExemptionCovid,
        ineligibleReason: issue.ineligibleReason,
        vacols_id: issue.vacolsId,
        vacols_sequence_id: issue.vacolsSequenceId,
        verified_unidentified_issue: issue.verifiedUnidentifiedIssue
      };
    });
};

const formatRatingRequestIssues = (state) => {
  return (state.addedIssues || []).
    filter((issue) => issue.isRating && !issue.isUnidentified && !issue.verifiedUnidentifiedIssue).
    map((issue) => {
      return {
        request_issue_id: issue.id,
        rating_issue_reference_id: issue.ratingIssueReferenceId,
        rating_decision_reference_id: issue.ratingDecisionReferenceId,
        decision_date: issue.decisionDate,
        decision_text: issue.description,
        rating_issue_profile_date: issue.ratingIssueProfileDate,
        rating_issue_diagnostic_code: issue.ratingIssueDiagnosticCode,
        notes: issue.notes,
        untimely_exemption: issue.untimelyExemption,
        untimely_exemption_notes: issue.untimelyExemptionNotes,
        untimely_exemption_covid: issue.untimelyExemptionCovid,
        ramp_claim_id: issue.rampClaimId,
        vacols_id: issue.vacolsId,
        vacols_sequence_id: issue.vacolsSequenceId,
        contested_decision_issue_id: issue.decisionIssueId,
        ineligible_reason: issue.ineligibleReason,
        ineligible_due_to_id: issue.ineligibleDueToId,
        withdrawal_date: issue.withdrawalPending ? state.withdrawalDate : null,
        edited_description: issue.editedDescription,
        correction_type: issue.correctionType
      };
    });
};

const formatNonratingRequestIssues = (state) => {
  return (state.addedIssues || []).
  filter((issue) => !issue.isRating && !issue.isUnidentified && !issue.verifiedUnidentifiedIssue).
  map((issue) => {
    return {
      request_issue_id: issue.id,
      contested_decision_issue_id: issue.decisionIssueId,
      benefit_type: issue.benefitType,
      nonrating_issue_category: issue.category,
      decision_text: issue.description,
      decision_date: issue.decisionDate,
      untimely_exemption: issue.untimelyExemption,
      untimely_exemption_notes: issue.untimelyExemptionNotes,
      vacols_id: issue.vacolsId,
      vacols_sequence_id: issue.vacolsSequenceId,
      ineligible_due_to_id: issue.ineligibleDueToId,
      ineligible_reason: issue.ineligibleReason,
      edited_description: issue.editedDescription,
      withdrawal_date: issue.withdrawalPending ? state.withdrawalDate : null,
      correction_type: issue.correctionType
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
  
  return issues.map((issue, index) => {
    if (issue.isUnidentified || issue.verifiedUnidentifiedIssue) {
      const issueText = issue.isUnidentified ? `Unidentified issue: no issue matched for "${issue.description}"` : issue.description
      return {
        index,
        referenceId: issue.id,
        text: issueText,
        notes: issue.notes,
        isUnidentified: issue.isUnidentified,
        date: issue.decisionDate,
        withdrawalPending: issue.withdrawalPending,
        withdrawalDate: issue.withdrawalDate,
        endProductCleared: issue.endProductCleared,
        correctionType: issue.correctionType,
        editable: issue.editable,
        timely: issue.timely,
        untimelyExemption: issue.untimelyExemption,
        untimelyExemptionNotes: issue.untimelyExemptionNotes,
        ineligibleReason: issue.ineligibleReason,
        vacolsId: issue.vacolsId,
        vacolsSequenceId: issue.vacolsSequenceId,
        vacolsIssue: issue.vacolsIssue,
        verifiedUnidentifiedIssue: issue.verifiedUnidentifiedIssue
      };
    } else if (issue.isRating) {
      if (!issue.decisionDate && !issue.approxDecisionDate) {
        console.warn(issue);
        throw new Error('no decision date');
      }

      const decisionDate = new Date(issue.decisionDate || issue.approxDecisionDate);

      return {
        index,
        referenceId: issue.id,
        text: issue.description,
        date: issue.decisionDate || issue.approxDecisionDate,
        notes: issue.notes,
        titleOfActiveReview: issue.titleOfActiveReview,
        sourceReviewType: issue.sourceReviewType,
        decisionDate,
        timely: issue.timely,
        beforeAma: decisionDate < amaActivationDate && !issue.rampClaimId,
        untimelyExemption: issue.untimelyExemption,
        untimelyExemptionNotes: issue.untimelyExemptionNotes,
        ineligibleReason: issue.ineligibleReason,
        rampClaimId: issue.rampClaimId,
        vacolsId: issue.vacolsId,
        vacolsSequenceId: issue.vacolsSequenceId,
        vacolsIssue: issue.vacolsIssue,
        eligibleForSocOptIn: issue.eligibleForSocOptIn,
        withdrawalPending: issue.withdrawalPending,
        withdrawalDate: issue.withdrawalDate,
        endProductCleared: issue.endProductCleared,
        editedDescription: issue.editedDescription,
        correctionType: issue.correctionType,
        editable: issue.editable,
        decisionIssueId: issue.decisionIssueId,
        ratingIssueReferenceId: issue.ratingIssueReferenceId,
        ratingDecisionReferenceId: issue.ratingDecisionReferenceId
      };
    }

    const decisionDate = new Date(issue.decisionDate);

    // returns nonrating request issue format
    return {
      index,
      referenceId: issue.id,
      text: issue.decisionIssueId ? issue.description : `${issue.category} - ${issue.description}`,
      benefitType: issue.benefitType,
      date: issue.decisionDate,
      timely: issue.timely,
      beforeAma: decisionDate < amaActivationDate,
      untimelyExemption: issue.untimelyExemption,
      untimelyExemptionNotes: issue.untimelyExemptionNotes,
      ineligibleReason: issue.ineligibleReason,
      vacolsId: issue.vacolsId,
      vacolsSequenceId: issue.vacolsSequenceId,
      vacolsIssue: issue.vacolsIssue,
      eligibleForSocOptIn: issue.eligibleForSocOptIn,
      decisionReviewTitle: issue.decisionReviewTitle,
      withdrawalPending: issue.withdrawalPending,
      withdrawalDate: issue.withdrawalDate,
      endProductCleared: issue.endProductCleared,
      category: issue.category,
      editedDescription: issue.editedDescription,
      correctionType: issue.correctionType,
      editable: issue.editable,
      decisionIssueId: issue.decisionIssueId
    };
  });
};
