import React from 'react';
import PropTypes from 'prop-types';
import TextField from '../components/TextField';
import ValidatorsUtil from '../util/ValidatorsUtil';
import COPY from '../../COPY';

const DEFAULT_TEXT = 'mm/dd/yyyy';

export const DateSelector = (props) => {
  const { dateValidator, futureDate } = ValidatorsUtil;

  const {
    errorMessage,
    label,
    name,
    onChange,
    readOnly,
    required,
    type,
    validationError,
    value,
    dateErrorMessage,
    noFutureDates = false,
    inputStyling,
    ...passthroughProps
  } = props;

  const dateValidationError = (date) => {
    if (date) {
      if (!dateValidator(date)) {
        return COPY.DATE_SELECTOR_INVALID_DATE_ERROR;
      }

      if (noFutureDates && futureDate(date)) {
        return COPY.DATE_SELECTOR_FUTURE_DATE_ERROR;
      }

      if (validationError) {
        return validationError(date);
      }
    }

    return null;
  };

  let max = '9999-12-31';

  if (noFutureDates) {
    max = new Date().toISOString().
      split('T')[0];
  }

  return (
    <TextField
      errorMessage={errorMessage}
      label={label}
      name={name}
      readOnly={readOnly}
      type={type}
      value={value}
      validationError={dateValidationError(value)}
      onChange={onChange}
      placeholder={DEFAULT_TEXT}
      required={required}
      {...passthroughProps}
      max={max}
      dateErrorMessage={dateErrorMessage}
      inputStyling={inputStyling}
    />
  );
};

DateSelector.propTypes = {

  /**
   * The initial value of the `input` element; use for uncontrolled components where not using `value` prop
   */
  defaultValue: PropTypes.string,
  inputStyling: PropTypes.object,
  dateErrorMessage: PropTypes.string,

  /**
   * Text (or other node) to display to indicate an error state
   */
  errorMessage: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.node
  ]),
  invisible: PropTypes.bool,

  /**
   * Props to be applied to the `input` element
   */
  inputProps: PropTypes.object,

  /**
   * Pass a ref to the `input` element
   */
  inputRef: PropTypes.oneOfType([
    // Either a function
    PropTypes.func,
    // Or the instance of a DOM native element (see the note about SSR)
    PropTypes.shape({ current: PropTypes.instanceOf(Element) }),
  ]),

  /**
   * Text or element to display in a `label` element
   */
  label: PropTypes.oneOfType([PropTypes.string, PropTypes.bool, PropTypes.element]),

  /**
   * String to be applied to the `name` attribute of the `input` element
   */
  name: PropTypes.string.isRequired,

  /**
   * Callback fired when value is changed
   *
   * @param {string} value The current value of the component
   */
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,

  /**
   * When true, will display text indicating that the field is required
   */
  required: PropTypes.bool,

  /**
   * Specifies the `type` parameter for the underlying `input` element
   */
  type: PropTypes.string,
  validationError: PropTypes.string,

  /**
   * The value of the `input` element; required for a controlled component
   */
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.bool]),

  /**
   * Disables future dates from being selected or entered
   */
  noFutureDates: PropTypes.bool
};

export default DateSelector;
