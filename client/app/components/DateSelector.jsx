import React from 'react';
import PropTypes from 'prop-types';
import TextField from '../components/TextField';

const DEFAULT_TEXT = 'mm/dd/yyyy';

export const DateSelector = (props) => {
  const {
    errorMessage,
    label,
    name,
    onChange,
    readOnly,
    required,
    validationError,
    value,
    dateErrorMessage,
    ...passthroughProps
  } = props;

  const handleChange = (val = '') => onChange?.(val);

  return (
    <TextField
      errorMessage={errorMessage}
      label={label}
      name={name}
      readOnly={readOnly}
      type="date"
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

  validationError: PropTypes.string,

  /**
   * The value of the `input` element; required for a controlled component
   */
  value: PropTypes.string,
};

export default DateSelector;
