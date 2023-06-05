import React from 'react';
import PropTypes from 'prop-types';
import TextField from './TextField';
import {
  INTAKE_EDIT_ISSUE_CHANGE_MESSAGE
} from 'app/../COPY';

const renderCheckbox = (option, onChange, values = {}, disabled = false, justifications, filterIssuesForJustification) => <div className="checkbox" key={option.id}>
  <input
    name={option.id}
    onChange={onChange}
    type="checkbox"
    id={option.id}
    checked={values[option.id]}
    disabled={option.disabled || disabled ? 'disabled' : ''}
  />
  <label htmlFor={option.id}>
    {option.label}
  </label>
  {option.requiresJustification && values[option.id] &&

        <TextField
        name={INTAKE_EDIT_ISSUE_CHANGE_MESSAGE}
        defaultValue={filterIssuesForJustification(justifications, option.id)[0].justification}
        required
        onChange={filterIssuesForJustification(justifications, option.id)[0].onJustificationChange}
        />
  }
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
      strongLabel,
      disableAll,
      justifications,
      filterIssuesForJustification
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
      {options.map((option) => getCheckbox(option, onChange, values, disableAll, justifications, filterIssuesForJustification))}
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
      ]),
      requiresJustification: PropTypes.bool
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
  strongLabel: PropTypes.bool,
  disableAll: PropTypes.bool,
  justifications: PropTypes.arrayOf(
    PropTypes.shape({
      pactJustification: PropTypes.string,
      mstJustification: PropTypes.string,
      pactJustificationOnChange: PropTypes.func,
      mstJustificationOnChange: PropTypes.func,
    })
  ),
  filterIssuesForJustification: PropTypes.func
};
