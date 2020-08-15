import React from 'react';
import PropTypes from 'prop-types';
import TextField from '../components/TextField';
import _ from 'lodash';

const DEFAULT_TEXT = 'mm/dd/yyyy';
// A regex that will match as much of a mm/dd/yyyy date as possible.
// TODO (mdbenjam): modify this to not accept months like 13 or days like 34
const DATE_REGEX = /[0,1](?:\d(?:\/(?:[0-3](?:\d(?:\/(?:\d{0,4})?)?)?)?)?)?/;

export const DateSelector = (props) => {
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
    ...passthroughProps
  } = props;

  const dateFill = (newVal = '') => {
    const propsValue = props.value || '';
    let updatedVal = newVal;

    if (type === 'date') {
      // input type=date handles validation, returns yyyy-mm-dd, displays mm/dd/yyyy
      return onChange?.(value);
    }

    // If the user added characters we append a '/' before putting
    // it through the regex. If this spot doesn't accept a '/' then
    // the regex test will strip it. Otherwise, the user doesn't have
    // to type a '/'. If the user removed characters we check if the
    // last character is a '/' and remove it for them.
    if (updatedVal.length > propsValue.length) {
      updatedVal = `${updatedVal}/`;
    } else if (propsValue.charAt(propsValue.length - 1) === '/') {
      updatedVal = updatedVal.substr(0, updatedVal.length - 1);
    }

    // Test the input agains the date regex above. The regex matches
    // as much of an allowed date as possible. Therefore this will just
    // removing any non-date characters
    const match = DATE_REGEX.exec(updatedVal);

    const result = match ? match[0] : '';

    onChange?.(result);
  };

  const handleChange = (val) => dateFill(val);

  return (
    <TextField
      errorMessage={errorMessage}
      label={label}
      name={name}
      readOnly={readOnly}
      type={type}
      value={value}
      validationError={validationError}
      onChange={handleChange}
      placeholder={DEFAULT_TEXT}
      required={required}
      {...passthroughProps}
      max="9999-12-31"
      dateErrorMessage={dateErrorMessage}
    />
  );
};

DateSelector.propTypes = {
  errorMessage: PropTypes.string,
  dateErrorMessage: PropTypes.string,
  invisible: PropTypes.bool,
  label: PropTypes.oneOfType([PropTypes.string, PropTypes.bool]),
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  required: PropTypes.bool,
  type: PropTypes.string,
  validationError: PropTypes.string,
  value: PropTypes.string,
};

export default DateSelector;
