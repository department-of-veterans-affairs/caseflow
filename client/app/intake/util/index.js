import _ from 'lodash';
import { REVIEW_OPTIONS } from '../constants';
import { formatDateStr, formatDateStringForApi } from '../../util/DateUtil';

export const getAppealDocketError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.appeal_docket, 0) === 'blank') && 'Please select an option.'
);

export const getOptionSelectedError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.option_selected, 0) === 'blank') && 'Please select an option.'
);

export const getBenefitTypeError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.benefit_type, 0) === 'blank') && 'Please select a Benefit Type option.'
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

export const formatRadioOptions = (options) => {
  return _.map(options, (value, key) => {
    return { value: key,
      displayText: value };
  });
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
      benefit_type: intakeData.benefitType,
      claimant: intakeData.claimant,
      payee_code: intakeData.payeeCode
    };
  case 'higherLevelReview':
    return {
      informal_conference: intakeData.informalConference,
      same_office: intakeData.sameOffice,
      benefit_type: intakeData.benefitType,
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

export const formatAddedIssues = (intakeData) => {
  let issues = intakeData.addedIssues || [];

  return issues.map((issue) => {
    // currently does not handle unrated issues
    if (issue.isRated) {
      let foundIssue = intakeData.ratings[issue.profileDate].issues[issue.id];

      return {
        referenceId: issue.id,
        text: `${foundIssue.decision_text} Decision date ${formatDateStr(issue.profileDate)}.`
      };
    }

    return {};
  });
};
