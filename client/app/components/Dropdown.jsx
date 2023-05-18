import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';

export default class Dropdown extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      errorMessage,
      label,
      name,
      options,
      required,
      value,
      defaultText,
      readOnly,
      hideLabel
    } = this.props;

    // Use empty string instead of null or undefined,
    // otherwise React displays the following error:
    //
    // "`value` prop on `input` should not be null.
    // Consider using the empty string to clear the component
    // or `undefined` for uncontrolled components."
    //
    value = (value === null || typeof value === 'undefined') ? '' : value;

    const labelClasses = classNames({ 'usa-sr-only': hideLabel });

    return <div className="cf-form-dropdown">
      <label htmlFor={name} className={labelClasses}>
        {label || name} {required && <span className="cf-required">Required</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message" tabIndex={0}>{errorMessage}</span>}
      <select value={value} onChange={this.onChange} id={name} disabled={readOnly}>
        { defaultText && <option defaultValue hidden>{defaultText}</option>}
        {options.map((option, index) =>
          <option
            value={option.value}
            id={`${name}_${option.value}`}
            disabled={option.disabled}
            key={index}>{option.displayText}
          </option>
        )}
      </select>
    </div>;
  }
}

Dropdown.propTypes = {
  errorMessage: PropTypes.string,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.arrayOf(PropTypes.shape({
    value: PropTypes.any,
    displayText: PropTypes.string
  })).isRequired,
  defaultText: PropTypes.string,
  hideLabel: PropTypes.bool,
  readOnly: PropTypes.bool,
  required: PropTypes.bool,
  value: PropTypes.string
};
