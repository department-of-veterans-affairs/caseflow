import React from 'react';
import PropTypes from 'prop-types';
import * as yup from 'yup';
import { format, add } from 'date-fns';
import DateSelector from '../../components/DateSelector';
import DATES from '../../../constants/DATES';
import { RECEIPT_DATE_ERRORS } from '../constants';

const ReceiptDateInput = ({
  receiptDate,
  setReceiptDate,
  receiptDateError,
  errors,
  register
}) => (
  <DateSelector
    name="receipt-date"
    label="What is the Receipt Date of this form?"
    value={receiptDate}
    onChange={setReceiptDate}
    errorMessage={errors?.['receipt-date']?.message || receiptDateError}
    type="date"
    strongLabel
    inputRef={register}
  />
);

const receiptDateInputValidation = (includeAmaValidation = false) => {
  return includeAmaValidation ?
    {
      receiptDate:
      yup.date().
        when(['$useAmaActivationDate'], {
          is: true,
          then: yup.date().typeError(RECEIPT_DATE_ERRORS.invalid).
            min(
              new Date(DATES.AMA_ACTIVATION),
              'Receipt Date cannot be prior to ' +
              `${format(new Date(DATES.AMA_ACTIVATION), 'MM/dd/yyyy')}.`
            ),
          otherwise: yup.date().typeError(RECEIPT_DATE_ERRORS.invalid).
            min(
              new Date(DATES.AMA_ACTIVATION_TEST),
              'Receipt Date cannot be earlier than RAMP start date, ' +
              `${format(new Date(DATES.AMA_ACTIVATION_TEST), 'MM/dd/yyyy')}.`
            )
        }).
        typeError(RECEIPT_DATE_ERRORS.invalid).
        max(format(add(new Date(), { hours: 1 }), 'MM/dd/yyyy'), RECEIPT_DATE_ERRORS.in_future).
        required(RECEIPT_DATE_ERRORS.invalid)
    } :
    {
      receiptDate: yup.date().typeError(RECEIPT_DATE_ERRORS.invalid).
        max(format(add(new Date(), { hours: 1 }), 'MM/dd/yyyy'), RECEIPT_DATE_ERRORS.in_future).
        required(RECEIPT_DATE_ERRORS.invalid),
    };
};

ReceiptDateInput.propTypes = {
  receiptDate: PropTypes.string,
  setReceiptDate: PropTypes.func,
  receiptDateError: PropTypes.string,
  errors: PropTypes.array,
  register: PropTypes.func
};

export default ReceiptDateInput;
export { receiptDateInputValidation };
