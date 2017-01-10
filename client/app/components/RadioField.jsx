import React, { PropTypes } from 'react';

export default class RadioField extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.value);
  }

  render() {
    let {
      label,
      name,
      options,
      value
    } = this.props;

    return <fieldset className="cf-form-radio-inline cf-form-showhide-radio">
      <legend className="question-label">{label || name}</legend>
      <div className="cf-form-radio-options">
        {options.map((option) =>
          <div className="cf-form-radio-option" key={option}>
            <input
              name={name}
              onChange={this.onChange}
              type="radio"
              id={`${name}_${option}`}
              value={option}
              checked={value === option}
            />
            <label htmlFor={`${name}_${option}`}>{option}</label>
          </div>
        )}
      </div>
    </fieldset>;
  }
}

RadioField.propTypes = {
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array,
  value: PropTypes.string
};
