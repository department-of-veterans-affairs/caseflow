import _ from 'lodash';

export const getOptionSelectedError = (responseErrorCodes) => (
  _.get(responseErrorCodes.option_selected, 0) && 'Please select an option.'
);

export const getReceiptDateError = (responseErrorCodes, state) => (
  {
    blank:
      'Please enter a valid receipt date.',
    in_future:
      'Receipt date cannot be in the future.',
    before_notice_date: 'Receipt date cannot be earlier than the election notice ' +
      `date of ${state.noticeDate}`
  }[_.get(responseErrorCodes.receipt_date, 0)]
);

