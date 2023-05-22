import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';

export const Checkbox = (props) => {
  const {
    label,
    name,
    required,
    defaultValue,
    value,
    disabled,
    id,
    inputProps,
    inputRef,
    errorMessage,
    unpadded,
    hideLabel,
    onChange,
    styling,
    ariaLabel,
  } = props;

  const handleChange = (event) => onChange?.(event.target.checked, event);
  const wrapperClasses = classnames(`checkbox-wrapper-${name}`, {
    'cf-form-checkboxes': !unpadded,
    'usa-input-error': Boolean(errorMessage),
  });

  return (
    <div className={wrapperClasses} {...styling}>
      {errorMessage && (
        <div className="usa-input-error-message">{errorMessage}</div>
      )}
      <div className="cf-form-checkbox">
        <input
          name={name}
          onChange={handleChange}
          type="checkbox"
          id={id || name}
          defaultChecked={defaultValue}
          checked={value}
          disabled={disabled}
          aria-label={ariaLabel}
          ref={inputRef}
          {...inputProps}
        />
        <label htmlFor={name}>
          <span className={classnames({ 'usa-sr-only': hideLabel })}>
            {label || name}
          </span>{' '}
          {required && <span className="cf-required">Required</span>}
        </label>
      </div>
    </div>
  );
};
Checkbox.defaultProps = {
  required: false,
};

Checkbox.propTypes = {

  /**
   * The initial value of the `input` element; use for uncontrolled components where not using `value` prop
   */
  defaultValue: PropTypes.bool,

  /**
   * Text (or other node) to display in associated `label` element
   */
  label: PropTypes.node,

  /**
   * String to be applied to the `name` attribute of the `input` element
   */
  name: PropTypes.string.isRequired,

  /**
   * Callback fired when value is changed
   *
   * @param {boolean} value The current value of the component
   * @param {object} event The SyntheticEvent object
   */
  onChange: PropTypes.func,

  required: PropTypes.bool.isRequired,
  disabled: PropTypes.bool,

  /**
   * Sets the `id` attribute on the `input` element; defaults to value of `name` prop
   */
  id: PropTypes.string,

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
   * Props to be applied to the `input` element
   */
  inputProps: PropTypes.object,

  /**
   * Text (or other node) to display to indicate an error state
   */
  errorMessage: PropTypes.node,
  unpadded: PropTypes.bool,
  hideLabel: PropTypes.bool,

  /**
   * The value of the named `input` element(s); required for a controlled component
   */
  value: PropTypes.bool,
  styling: PropTypes.object,
  ariaLabel: PropTypes.string
};

export default Checkbox;
