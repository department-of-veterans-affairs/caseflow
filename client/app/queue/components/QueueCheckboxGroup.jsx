import React from 'react';
import PropTypes from 'prop-types';
import TextField from '../../components/TextField';
import {
  INTAKE_EDIT_ISSUE_CHANGE_MESSAGE
} from 'app/../COPY';

const renderCheckbox = (option, onChange, values = {}, disabled = false, justifications,
  // eslint-disable-next-line max-params
  filterIssuesForJustification, errorState, justificationFeatureToggle) => <div className="checkbox" key={option.id}>
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
  {option.requiresJustification && filterIssuesForJustification(justifications, option.id)[0].hasChanged &&
    justificationFeatureToggle &&

        <TextField
          name={INTAKE_EDIT_ISSUE_CHANGE_MESSAGE}
          defaultValue={filterIssuesForJustification(justifications, option.id)[0].justification}
          errorMessage={(errorState.invalid && errorState.highlightModal && !filterIssuesForJustification(justifications, option.id)[0].justification) ? 'Justification field is required' : null}
          required
          onChange={filterIssuesForJustification(justifications, option.id)[0].onJustificationChange}
        />
  }
</div>;

export default class QueueCheckboxGroup extends React.Component {

  // number of options that render horizontally by default
  MAX = 2;

  render() {
    const {
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
      filterIssuesForJustification,
      justificationFeatureToggle
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

    if (errorMessage) {
      fieldClasses += ' usa-input-error';
    }

    const legendClasses = (hideLabel) ? 'hidden-field' : '';

    return <fieldset className={fieldClasses} {...styling}>
      <legend className={legendClasses}>
        {required && <span className="cf-required">Required</span>}
        {strongLabel ? <strong>{labelContents}</strong> : labelContents}
      </legend>
      {options.map((option) => getCheckbox(option, onChange, values, disableAll,
        justifications, filterIssuesForJustification, errorState, justificationFeatureToggle))}
    </fieldset>;
  }
}

QueueCheckboxGroup.defaultProps = {
  required: false,
  getCheckbox: renderCheckbox,
  hideErrorMessage: false
};

QueueCheckboxGroup.propTypes = {
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
  errorState: PropTypes.shape({
    highlightModal: PropTypes.bool,
    invalid: PropTypes.bool,
  }),
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
  filterIssuesForJustification: PropTypes.func,
  justificationFeatureToggle: PropTypes.bool
};
