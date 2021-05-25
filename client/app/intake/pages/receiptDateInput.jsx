import React from 'react';
import PropTypes from 'prop-types';
import * as yup from 'yup';
import { format, add } from 'date-fns';
import DateSelector from '../../components/DateSelector';
import DATES from '../../../constants/DATES';

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
    errorMessage={receiptDateError || errors?.['receipt-date']?.message}
    type="date"
    strongLabel
    inputRef={register}
  />
);

const receiptDateInputValidation = (includeAmaValidation = false) => {
  return includeAmaValidation ?
    {
      'receipt-date':
      yup.date().
        when(['$useAmaActivationDate'], {
          is: true,
          then: yup.date().typeError('Receipt Date is required.').
            min(
              new Date(DATES.AMA_ACTIVATION),
          `Receipt Date cannot be prior to ${format(new Date(DATES.AMA_ACTIVATION), 'MM/dd/yyyy')}`
            ),
          otherwise: yup.date().typeError('Receipt Date is required.').
            min(
              new Date(DATES.AMA_ACTIVATION_TEST),
          `Receipt Date cannot be prior to ${format(new Date(DATES.AMA_ACTIVATION_TEST), 'MM/dd/yyyy')}`
            )
        }).
        typeError('Please enter a valid receipt date.').
        max(format(add(new Date(), { hours: 1 }), 'MM/dd/yyyy'), 'Receipt date cannot be in the future.').
        required('Please enter a valid receipt date.')
    } :
    {
      'receipt-date': yup.date().typeError('Please enter a valid receipt date.').
        max(format(add(new Date(), { hours: 1 }), 'MM/dd/yyyy'), 'Receipt date cannot be in the future.').
        required('Please enter a valid receipt date.'),
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
