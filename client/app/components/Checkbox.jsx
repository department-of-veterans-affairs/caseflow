import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';

export const Checkbox = (props) => {
  const {
    label,
    name,
    required,
    value,
    disabled,
    id,
    errorMessage,
    unpadded,
    hideLabel,
    onChange,
    styling,
  } = props;

  const handleChange = (event) => onChange?.(event.target.checked, event);

  const wrapperClasses = classnames(`checkbox-wrapper-${name}`, {
    'cf-form-checkboxes': !unpadded,
    'usa-input-error': Boolean(errorMessage)
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
          checked={value}
          disabled={disabled}
          aria-label={name}
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
  label: PropTypes.node,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  required: PropTypes.bool.isRequired,
  disabled: PropTypes.bool,
  id: PropTypes.string,
  errorMessage: PropTypes.node,
  unpadded: PropTypes.bool,
  hideLabel: PropTypes.bool,
  value: PropTypes.bool,
  styling: PropTypes.object,
};

export default Checkbox;
