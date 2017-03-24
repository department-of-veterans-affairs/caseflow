import React, { PropTypes } from 'react';
import RequiredIndicator from './RequiredIndicator';

/*
 * Usage example:
 *
 * <RadioField
 *   label="Enter an answer to this question."
 *   required={true}
 *   options=[{display}]
 *
 */

export default class RadioField extends React.Component {
  onChange = (event) => {
    debugger;
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      label,
      name,
      options,
      value,
      required
    } = this.props;

    required = required || false;

    debugger;

    return <fieldset className="cf-form-radio-inline cf-form-showhide-radio">
      <legend className="question-label">
        {(label || name)} {(required && <RequiredIndicator/>)}
      </legend>

      <div className="cf-form-radio-options">
        {options.map((option) =>
          <div className="cf-form-radio-option" key={option.value}>
            <input
              name={name}
              onChange={this.onChange.bind(this)}
              type="radio"
              id={`${name}_${option.value}`}
              value={option.value}
              checked={value === option.value}
            />
            <label htmlFor={`${name}_${option}`}>{option.displayText}</label>
          </div>
        )}
      </div>
    </fieldset>;
  }
}

RadioField.propTypes = {
  required: PropTypes.bool,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array,
  value: PropTypes.string
};
