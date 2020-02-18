import _ from 'lodash';
import { REVIEW_OPTIONS } from '../constants';
import DATES from '../../../constants/DATES';
import { formatDateStr } from '../../util/DateUtil';

export const getBlankOptionError = (responseErrorCodes, field) => (
  (_.get(responseErrorCodes[field], 0) === 'blank') && 'Please select an option.'
);

export const getClaimantError = (responseErrorCodes) => {
  const errorCode = _.get(responseErrorCodes.claimant, 0);

  if (errorCode === 'blank') {
    return 'Please select an option.';
  } else if (errorCode === 'claimant_address_required') {
    return "Please update the claimant's address.";
  }
};

export const getPageError = (responseErrorCodes) => (
  (_.get(responseErrorCodes.other, 0) === 'unknown_error') && 'Unknown error.'
);

// use this conversion to change between rails model and react radio input
// otherwise we send over a string true/false and reloading turns it into a boolean
// which messes up logic on backend which expects a string
export const convertStringToBoolean = (string) => {
  if (string === 'true') {
    return true;
  } else if (string === 'false') {
    return false;
  }

  return null;
};

export const benefitTypeProcessedInVBMS = (benefitType) => {
  return (benefitType === 'compensation' || benefitType === 'pension');
};

export const isCorrection = (isRating, intakeData) => {
  const isRatingCorrection = isRating && intakeData.hasClearedRatingEp;
  const isNonratingCorrection = !isRating && intakeData.hasClearedNonratingEp;

  return Boolean(isRatingCorrection || isNonratingCorrection);
};

export const getReceiptDateError = (responseErrorCodes, state) => (
  {
    in_future:
      'Receipt date cannot be in the future.',
    before_ramp: 'Receipt Date cannot be earlier than RAMP start date, 11/01/2017.',
    before_ama: `Receipt Date cannot be prior to ${formatDateStr(DATES.AMA_ACTIVATION)}.`,
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
      displayText: `${first} ${last}, ${type}`,
      defaultPayeeCode: relationship.default_payee_code
    };
  });
};

export const getDefaultPayeeCode = (state, claimant) => {
  return _.find(state.relationships, { value: claimant }).defaultPayeeCode;
};

export const formatRadioOptions = (options) => {
  return _.map(options, (value, key) => {
    return { value: key,
      displayText: value };
  });
};

export const formatSearchableDropdownOptions = (options) => {
  return _.map(options, (value, key) => {
    return { value: key,
      label: value };
  });
};

export const prepareReviewData = (intakeData, intakeType) => {
  switch (intakeType) {
  case 'appeal':
    return {
      docket_type: intakeData.docketType,
      receipt_date: intakeData.receiptDate,
      claimant: intakeData.claimant,
      veteran_is_not_claimant: intakeData.veteranIsNotClaimant,
      payee_code: intakeData.payeeCode,
      legacy_opt_in_approved: intakeData.legacyOptInApproved
    };
  case 'supplementalClaim':
    return {
      receipt_date: intakeData.receiptDate,
      benefit_type: intakeData.benefitType,
      claimant: intakeData.claimant,
      veteran_is_not_claimant: intakeData.veteranIsNotClaimant,
      payee_code: intakeData.payeeCode,
      legacy_opt_in_approved: intakeData.legacyOptInApproved
    };
  case 'higherLevelReview':
    return {
      informal_conference: intakeData.informalConference,
      same_office: intakeData.sameOffice,
      benefit_type: intakeData.benefitType,
      receipt_date: intakeData.receiptDate,
      claimant: intakeData.claimant,
      veteran_is_not_claimant: intakeData.veteranIsNotClaimant,
      payee_code: intakeData.payeeCode,
      legacy_opt_in_approved: intakeData.legacyOptInApproved
    };
  default:
    return {
      receipt_date: intakeData.receiptDate,
      claimant: intakeData.claimant,
      veteran_is_not_claimant: intakeData.veteranIsNotClaimant,
      payee_code: intakeData.payeeCode,
      legacy_opt_in_approved: intakeData.legacyOptInApproved
    };
  }
};
