import React, { PropTypes } from 'react';
import RequiredIndicator from './RequiredIndicator';


/**
 *
 * Usage example:
 *
 * const options = [
    {displayText:"Hearing changed", value: "true" },
    {displayText:"Hearing did not change", value: "false"}
  ]
 * <RadioField name={"Did hearing change?"}
      required={true}
      options={}
      value={hearingDocumentIsInVbms}
      onChange={onHearingDocumentChange}/>
 *
 *
 */

export default class RadioField extends React.Component {
  onChange = (event) => {
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
            <label htmlFor={`${name}_${option.value}`}>{option.displayText}</label>
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
