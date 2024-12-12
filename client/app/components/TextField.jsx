import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import { FormLabel } from './FormLabel';

const labelTextStyling = css({
  marginTop: '0.65em',
  marginBottom: '0.65em',
});

export const TextField = (props) => {
  const handleChange = (event) => props.onChange?.(event.target.value);
  const handleBlur = (event) => props.onBlur?.(event.target.value);

  const {
    ariaLabelText,
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
    loading,
    id,
    inputID,
    disabled
  } = props;

  const textInputClass = className.
    concat(invisible ? ' cf-invisible' : '').
    concat(errorMessage ? 'usa-input-error' : '').
    concat(dateErrorMessage ? 'cf-date-error' : '');

  const labelContents = (
    <FormLabel
      label={label}
      name={name}
      required={required}
      optional={optional}
    />
  );

  const ariaLabelObj = useAriaLabel ? { 'aria-label': ariaLabelText || name } : {};

  // Transform `null` values to empty strings to avoid React warnings
  // We allow `undefined` as it indicates uncontrolled usage
  const adjustedVal = useMemo(() => typeof value === 'object' && !value ? '' : value);

  const idVal = () => {
    if (inputID && inputID !== '') {
      return inputID;
    } else if (name !== '') {
      return name;
    } else if (id !== '') {
      return id;
    }

    return '';
  };

  return (
    <div className={textInputClass.join(' ')}>
      {dateErrorMessage && (
        <span className="usa-input-error-message" tabIndex={0}>{dateErrorMessage}</span>
      )}
      {label !== false && (
        <label htmlFor={name}>
          {strongLabel ? <strong>{labelContents}</strong> : labelContents}
        </label>
      )}
      {labelText && <p {...labelTextStyling}>{labelText}</p>}
      {errorMessage && (
        <span className="usa-input-error-message" tabIndex={0}>{errorMessage}</span>
      )}
      {props.fixedInput ? (
        <p>{value}</p>
      ) : (
        <div className="input-container">
          <input
            ref={inputRef}
            className={className}
            name={name}
            id={idVal()}
            onChange={handleChange}
            onKeyPress={onKeyPress}
            onBlur={handleBlur}
            type={type}
            defaultValue={defaultValue}
            value={adjustedVal}
            aria-readonly={readOnly}
            readOnly={readOnly}
            placeholder={placeholder}
            title={title}
            maxLength={maxLength}
            max={max}
            autoComplete={autoComplete}
            disabled={disabled}
            {...inputProps}
            {...ariaLabelObj}
            {...inputStyling}
          />

          { loading &&
              <span className="cf-loading-icon-container">
                <span className="cf-loading-icon-front">
                  <span className="cf-loading-icon-back" />
                </span>
              </span>
          }
        </div>
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
  className: PropTypes.arrayOf(PropTypes.string),
  id: PropTypes.string,
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
  onBlur: PropTypes.func,
  title: PropTypes.string,
  ariaLabelText: PropTypes.string,
  onKeyPress: PropTypes.func,
  strongLabel: PropTypes.bool,
  maxLength: PropTypes.number,
  max: PropTypes.any,
  autoComplete: PropTypes.string,
  inputID: PropTypes.string,
  placeholder: PropTypes.string,
  readOnly: PropTypes.bool,
  fixedInput: PropTypes.bool,
  required: PropTypes.bool.isRequired,
  optional: PropTypes.bool.isRequired,
  type: PropTypes.string,
  validationError: PropTypes.string,
  loading: PropTypes.bool,
  disabled: PropTypes.bool,

  /**
   * The value of the `input` element; required for a controlled component
   */
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};

export default TextField;
