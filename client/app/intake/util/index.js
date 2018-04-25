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
