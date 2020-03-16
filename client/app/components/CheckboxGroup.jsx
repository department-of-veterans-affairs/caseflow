import React from 'react';
import PropTypes from 'prop-types';

const renderCheckbox = (option, onChange, values = {}) => <div className="checkbox" key={option.id}>
  <input
    name={option.id}
    onChange={onChange}
    type="checkbox"
    id={option.id}
    checked={values[option.id]}
    disabled={option.disabled ? 'disabled' : ''}
  />
  <label htmlFor={option.id}>
    {option.label}
  </label>
</div>;

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
      errorMessage,
      errorState,
      getCheckbox,
      styling,
      strongLabel
    } = this.props;

    const labelContents = (
      <span>
        {label || name}
      </span>
    );

    let fieldClasses = `checkbox-wrapper-${name} cf-form-checkboxes cf-checkbox-group`;

    if (options.length <= this.MAX && !vertical) {
      fieldClasses += '-inline';
    }

    if (errorState || errorMessage) {
      fieldClasses += ' usa-input-error';
    }

    let legendClasses = (hideLabel) ? 'hidden-field' : '';

    return <fieldset className={fieldClasses} {...styling}>
      <legend className={legendClasses}>
        {required && <span className="cf-required">Required</span>}
        {strongLabel ? <strong>{labelContents}</strong> : labelContents}
      </legend>
      {errorMessage && <div className="usa-input-error-message">{errorMessage}</div>}
      {options.map((option) => getCheckbox(option, onChange, values))}
    </fieldset>;
  }
}

CheckboxGroup.defaultProps = {
  required: false,
  getCheckbox: renderCheckbox,
  hideErrorMessage: false
};

CheckboxGroup.propTypes = {
  label: PropTypes.node,
  hideLabel: PropTypes.bool,
  name: PropTypes.string.isRequired,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string,
      label: PropTypes.oneOfType([
        PropTypes.string,
        PropTypes.node
      ])
    })
  ).isRequired,
  onChange: PropTypes.func.isRequired,
  required: PropTypes.bool,
  vertical: PropTypes.bool,
  values: PropTypes.object,
  errorMessage: PropTypes.string,
  errorState: PropTypes.bool,
  getCheckbox: PropTypes.func,
  styling: PropTypes.object,
  strongLabel: PropTypes.bool
};
