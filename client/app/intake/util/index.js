import _ from 'lodash';
import { REVIEW_OPTIONS, PAYEE_CODES } from '../constants';
import { formatDateStringForApi } from '../../util/DateUtil';

export const getBlankOptionError = (responseErrorCodes, field) => (
  (_.get(responseErrorCodes[field], 0) === 'blank') && 'Please select an option.'
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
      payee_code: intakeData.payeeCode,
      legacy_opt_in_approved: intakeData.legacyOptInApproved
    };
  case 'supplementalClaim':
    return {
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      benefit_type: intakeData.benefitType,
      claimant: intakeData.claimant,
      payee_code: intakeData.payeeCode,
      legacy_opt_in_approved: intakeData.legacyOptInApproved
    };
  case 'higherLevelReview':
    return {
      informal_conference: intakeData.informalConference,
      same_office: intakeData.sameOffice,
      benefit_type: intakeData.benefitType,
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant,
      payee_code: intakeData.payeeCode,
      legacy_opt_in_approved: intakeData.legacyOptInApproved
    };
  default:
    return {
      receipt_date: formatDateStringForApi(intakeData.receiptDate),
      claimant: intakeData.claimant,
      payee_code: intakeData.payeeCode,
      legacy_opt_in_approved: intakeData.legacyOptInApproved
    };
  }
};

export const getValidPayeeCodes = (isDeceased) => {
  let validCodes = ['00', '10', '11', '12', '13', '14', '15', '16', '17',
    '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
    '31', '32', '33', '34', '35', '36', '37', '38', '39', '50', '60'];

  if (isDeceased) {
    validCodes = ['10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '31', '32',
      '33', '34', '35', '36', '37', '38', '39', '50', '60', '70', '71', '72',
      '73', '74', '75', '76', '77', '78'];
  }

  return validCodes.map((code) => {
    return { value: code,
      label: PAYEE_CODES[code] };
  });
};

export const getAllPayeeCodes = () => {
  return Object.keys(PAYEE_CODES).sort().
    map((code) => {
      return { value: code,
        label: PAYEE_CODES[code] };
    });
};
