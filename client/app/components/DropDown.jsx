import React, { PropTypes } from 'react';
export default class DropDown extends React.Component {
  render() {
    let {
      errorMessage,
      label,
      name,
      options,
      required,
      value,
      readOnly
    } = this.props;

    return <div className="cf-form-dropdown">
      <label className="question-label" htmlFor={name}>
        {label || name} {required && <span className="cf-required">(Required)</span>}
      </label>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      <select value={value} onChange={this.props.onChange} id={name} readOnly={readOnly}>
        {options.map((option, index) =>
          <option
            value={option}
            id={`${name}_${option}`}
            key={index}>{option}
          </option>
        )}
      </select>
    </div>;
  }
}

DropDown.propTypes = {
  errorMessage: PropTypes.string,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array,
  readOnly: PropTypes.bool,
  required: PropTypes.required,
  value: PropTypes.string
};
