import React, { PropTypes } from 'react';

export default class CheckboxGroup extends React.Component {

  // number of options that render horizontally by default
  MAX = 2;

  render() {
    let {
      label,
      name,
      required,
      onChange,
      options,
      vertical,
      hideLabel,
      values,
      errorMessage
    } = this.props;

    let fieldClasses = `checkbox-wrapper-${name} cf-form-checkboxes`;

    if (options.length <= this.MAX && !vertical) {
      fieldClasses += '-inline';
    }

    if (errorMessage) {
      fieldClasses += ' usa-input-error';
    }

    let legendClasses = (hideLabel) ? 'hidden-field' : '';

    return <fieldset className={fieldClasses}>
      <legend className={legendClasses}>
        {required && <span className="cf-required">Required</span>}
        {label || name}
      </legend>

      {errorMessage && <div className="usa-input-error-message">{errorMessage}</div>}

      {options.map((option) =>

      <div className="checkbox" key={option.id}>
        <input
          name={option.id}
          onChange={onChange}
          type="checkbox"
          id={option.id}
          checked={values[option.id]}
          disabled={option.disabled ? 'disabled' : ''}
        />
        <label className="question-label" htmlFor={option.id}>
          {option.label}
        </label>
      </div>

      )}
    </fieldset>;
  }
}

CheckboxGroup.defaultProps = {
  required: false
};

CheckboxGroup.propTypes = {
  label: PropTypes.node,
  hideLabel: PropTypes.bool,
  name: PropTypes.string.isRequired,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      label: PropTypes.string
    })
  ).isRequired,
  onChange: PropTypes.func.isRequired,
  required: PropTypes.bool,
  vertical: PropTypes.bool,
  values: PropTypes.object,
  errorMessage: PropTypes.string
};
