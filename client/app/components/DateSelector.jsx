import React from 'react';
import PropTypes from 'prop-types';
import TextField from '../components/TextField';

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
      return onChange?.(newVal);
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

    // Test the input against the date regex above. The regex matches
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

  /**
   * The initial value of the `input` element; use for uncontrolled components where not using `value` prop
   */
  defaultValue: PropTypes.string,

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
  value: PropTypes.string,
};

export default DateSelector;
