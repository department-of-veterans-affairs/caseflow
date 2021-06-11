import _ from 'lodash';
import { REVIEW_OPTIONS, REVIEW_DATA_FIELDS, CLAIMANT_ERRORS } from '../constants';
import DATES from '../../../constants/DATES';
import { formatDateStr } from '../../util/DateUtil';

export const getBlankOptionError = (responseErrorCodes, field) => (
  _.get(responseErrorCodes[field], 0) === 'blank' ? 'Please select an option.' : null
);

export const getClaimantError = (responseErrorCodes) => {
  const errorCode = _.get(responseErrorCodes.claimant, 0);

  return CLAIMANT_ERRORS[errorCode];
};

export const getPageError = (responseErrorPayload) => {
  if (responseErrorPayload.responseErrorCodes.other?.[0] === 'unknown_error') {
    return { errorCode: null, errorUUID: responseErrorPayload.errorUUID };
  }
};

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
    blank: 'Please enter a valid receipt date.',
    in_future: 'Receipt date cannot be in the future.',
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
      fullName: `${first} ${last}`,
      relationshipType: type,
      displayText: `${first} ${last}, ${type}`,
      defaultPayeeCode: relationship.default_payee_code
    };
  });
};

export const getDefaultPayeeCode = (state, claimant) => {
  return (claimant ? _.find(state.relationships, { value: claimant }).defaultPayeeCode : null);
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

// Performs frontend validation on payloads intended for the /review endpoint.
// For simple validation (i.e. presence of fields), this saves an XHR roundtrip,
// and decouples error-reporting in the UI from backend ActiveModel logic.
export const validateReviewData = (intakeData, intakeType) => {
  const fields = REVIEW_DATA_FIELDS[intakeType];
  let errorCodes = {};
  for (const fieldName in fields) {
    const field = fields[fieldName];
    if (field.required && intakeData[field.key] == null) {
      errorCodes[fieldName] = ['blank'];
    }
  }
  if (intakeData.receiptDate && intakeData.receiptDate > (new Date).toISOString()) {
    errorCodes.receipt_date = ['in_future'];
  }
  if (['dependent', 'attorney'].includes(intakeData.claimantType) && !intakeData.claimant) {
    errorCodes.claimant = ['blank'];
  }
  return (Object.keys(errorCodes).length ? errorCodes : null);
};


  // Converts all object and nested keys to snake case
const keysToSnakeCase = (object) => {
  let snakeCaseObject = _.cloneDeep(object);

  // Convert keys to snake case
  snakeCaseObject = _.mapKeys(snakeCaseObject, (value, key) => {
    return _.snakeCase(key);
  });

  // Recursively apply throughout object
  return _.mapValues(
    snakeCaseObject,
    value => {
      if (_.isPlainObject(value)) {
        return keysToSnakeCase(value);
      } else if (_.isArray(value)) {
        return _.map(value, keysToSnakeCase);
      } else {
        return value;
      }
    }
  );
};

export const prepareReviewData = (intakeData, intakeType) => {
  const fields = REVIEW_DATA_FIELDS[intakeType];
  const result = {};
  for (let fieldName in fields) {
    result[fieldName] = intakeData[fields[fieldName].key];
  }
  console.log('un prepared data', result)
  console.log('Prepared data', keysToSnakeCase(result))
  return keysToSnakeCase(result);
};
