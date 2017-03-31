import React, { PropTypes } from 'react';
import RequiredIndicator from './RequiredIndicator';
import StringUtil from '../util/StringUtil';

/**
 * Radio button component.
 *
 * See StyleGuideRadioField.jsx for usage examples.
 *
 */

export default class RadioField extends React.Component {

  isVertical() {
    return this.props.vertical || this.props.options.length > 2;
  }

  render() {
    let {
      id,
      className,
      label,
      name,
      options,
      value,
      onChange,
      required,
      errorMessage,
      hideLabel
    } = this.props;

    required = required || false;

    let radioClass = className.concat(
      this.isVertical() ? "cf-form-radio" : "cf-form-radio-inline"
    ).concat(
      errorMessage ? "usa-input-error" : ""
    );

    let labelClass = "question-label";

    if (hideLabel) {
      labelClass += " hidden-field";
    }

    // Since HTML5 IDs should not contain spaces...
    let idPart = StringUtil.html5CompliantId(id || name);

    return <fieldset className={radioClass.join(' ')}>
      <legend className={labelClass}>
        {(label || name)} {(required && <RequiredIndicator/>)}
      </legend>

      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}

      <div className="cf-form-radio-options">
        {options.map((option, i) =>
          <div className="cf-form-radio-option" key={`${idPart}-${option.value}-${i}`}>
            <input
              name={name}
              onChange={onChange}
              type="radio"
              id={`${idPart}_${option.value}`}
              value={option.value}
              checked={value === option.value}
            />
            <label htmlFor={`${idPart}_${option.value}`}>{option.displayText}</label>
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
  id: PropTypes.string,
  className: PropTypes.arrayOf(PropTypes.string),
  required: PropTypes.bool,
  label: PropTypes.node,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  options: PropTypes.array,
  value: PropTypes.string
};
