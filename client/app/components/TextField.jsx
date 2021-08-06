import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import { FormLabel } from './FormLabel';
import { isArray } from 'lodash';

const labelTextStyling = css({
  marginTop: '0.65em',
  marginBottom: '0.65em',
});

export const TextField = (props) => {
  const handleChange = (event) => props.onChange?.(event.target.value);

  const {
    errorMessage,
    className,
    label,
    name,
    readOnly,
    required,
    optional,
    type,
    defaultValue,
    value,
    validationError,
    invisible,
    placeholder,
    title,
    onKeyPress,
    strongLabel,
    maxLength,
    max,
    autoComplete,
    useAriaLabel,
    dateErrorMessage,
    labelText,
    inputStyling,
    inputProps,
    inputRef,
  } = props;

  let textInputClass = isArray(className) ? className.join(' ') : className;

  textInputClass.
    concat(invisible ? ' cf-invisible' : '').
    concat(errorMessage ? ' usa-input-error' : '').
    concat(dateErrorMessage ? ' cf-date-error' : '');

  const labelContents = (
    <FormLabel
      label={label}
      name={name}
      required={required}
      optional={optional}
    />
  );

  const ariaLabelObj = useAriaLabel ? { 'aria-label': name } : {};

  // Transform `null` values to empty strings to avoid React warnings
  // We allow `undefined` as it indicates uncontrolled usage
  const adjustedVal = useMemo(() => typeof value === 'object' && !value ? '' : value);

  return (
    <div className={textInputClass}>
      {dateErrorMessage && (
        <span className="usa-input-error-message">{dateErrorMessage}</span>
      )}
      {label !== false && (
        <label htmlFor={name} {...labelTextStyling}>
          {strongLabel ? <strong>{labelContents}</strong> : labelContents}
        </label>
      )}
      {labelText && <p {...labelTextStyling}>{labelText}</p>}
      {errorMessage && (
        <span className="usa-input-error-message">{errorMessage}</span>
      )}
      {props.fixedInput ? (
        <p>{value}</p>
      ) : (
        <input
          ref={inputRef}
          className={className}
          name={name}
          id={name}
          onChange={handleChange}
          onKeyPress={onKeyPress}
          type={type}
          defaultValue={defaultValue}
          value={adjustedVal}
          readOnly={readOnly}
          placeholder={placeholder}
          title={title}
          maxLength={maxLength}
          max={max}
          autoComplete={autoComplete}
          {...inputProps}
          {...ariaLabelObj}
          {...inputStyling}
        />
      )}

      {validationError && (
        <div className="cf-validation">
          <span>{validationError}</span>
        </div>
      )}
    </div>
  );
};

TextField.defaultProps = {
  required: false,
  optional: false,
  useAriaLabel: false,
  type: 'text',
  className: ['cf-form-textinput'],
};

TextField.propTypes = {
  dateErrorMessage: PropTypes.string,

  /**
   * The initial value of the `input` element; use for uncontrolled components where not using `value` prop
   */
  defaultValue: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  errorMessage: PropTypes.string,
  className: PropTypes.oneOfType([PropTypes.arrayOf(PropTypes.string), PropTypes.string]),
  inputStyling: PropTypes.object,

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
  invisible: PropTypes.bool,

  /**
   * Text to display in a `label` element
   */
  label: PropTypes.oneOfType([PropTypes.string, PropTypes.bool, PropTypes.element]),

  /**
   * Plain text to display in lieu of a `label`
   */
  labelText: PropTypes.string,
  useAriaLabel: PropTypes.bool,

  /**
   * String to be applied to the `name` attribute of the `input` element
   */
  name: PropTypes.string.isRequired,

  /**
   * Callback fired when value is changed
   *
   * @param {string | number} value The current value of the component
   */
  onChange: PropTypes.func,
  title: PropTypes.string,
  onKeyPress: PropTypes.func,
  strongLabel: PropTypes.bool,
  maxLength: PropTypes.number,
  max: PropTypes.any,
  autoComplete: PropTypes.string,
  placeholder: PropTypes.string,
  readOnly: PropTypes.bool,
  fixedInput: PropTypes.bool,
  required: PropTypes.bool.isRequired,
  optional: PropTypes.bool.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,

  /**
   * The value of the `input` element; required for a controlled component
   */
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};

export default TextField;
