import React, { PropTypes } from 'react';
export default class RadioField extends React.Component {
  render() {
    let {
      label,
      name,
      onChange,
      options,
      checked
    } = this.props;

    return <fieldset className="cf-form-radio-inline cf-form-showhide-radio">
      <legend className="question-label">{label || name}</legend>
      <div className="cf-form-radio-options">
        {options.map((option) =>
          <div className="cf-form-radio-option" key={option}>
            <input
              name={name}
              onChange={onChange}
              type="radio"
              id={`${name}_${option}`}
              value={option}
              checked={checked==option}
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
  options: PropTypes.array,
  checked: PropTypes.string,
  onChange: PropTypes.func
};
