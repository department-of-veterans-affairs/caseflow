import React, { PropTypes } from 'react';
import RequiredIndicator from './RequiredIndicator';

export default class RadioField extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null,
      isInitialState: true
    };
  }

  isChecked(value, option) {
    if (this.state.isInitialState) {
      return value === option;
    }

    return this.state.value === option;

  }

  isVertical() {
    return this.props.vertical || this.props.options.length > 2;
  }

  onChange = (event) => {
    this.setState({
      value: event.target.value,
      isInitialState: false
    });

    if (this.props.onChange) {
      this.props.onChange(event.target.value);
    }
  }

  render() {
    let {
      className,
      label,
      name,
      options,
      value,
      required,
      hideLabel
    } = this.props;

    required = required || false;

    let radioClass = className.concat(
      this.isVertical() ? "cf-form-radio" : "cf-form-radio-inline"
    );

    let labelClass = "question-label";

    if (hideLabel) {
      labelClass += " hidden-field";
    }

    return <fieldset className={radioClass.join(' ')}>
      <legend className={labelClass}>
        {(label || name)} {(required && <RequiredIndicator/>)}
      </legend>

      <div className="cf-form-radio-options">
        {options.map((option) =>
          <div className="cf-form-radio-option" key={`${name}-${option.value}`}>
            <input
              name={name}
              onChange={this.onChange}
              type="radio"
              id={`${name}_${option.value}`}
              value={option.value}
              checked={this.isChecked(value, option.value)}
            />
            <label htmlFor={`${name}_${option.value}`}>{option.displayText}</label>
          </div>
        )}
      </div>
    </fieldset>;
  }
}

RadioField.defaultProps = {
  className: ["cf-form-showhide-radio"]
};

RadioField.propTypes = {
  className: PropTypes.arrayOf(PropTypes.string),
  required: PropTypes.bool,
  label: PropTypes.string,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.array,
  value: PropTypes.string
};
