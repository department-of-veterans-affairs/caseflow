import React from 'react';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import { Redirect } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setFormType } from '../actions/common';
import { FORM_TYPES, PAGE_PATHS } from '../constants';
import _ from 'lodash';

class SelectForm extends React.PureComponent {
  render() {
    const enabledFormTypes = this.props.featureToggles.intakeAma ? FORM_TYPES : _.filter(FORM_TYPES, {category: 'ramp'});

    const radioOptions = _.map(enabledFormTypes, (form) => ({
      value: form.key,
      displayText: form.name,
      label: form.name
    }));

    // Switch from radio buttons to searchable dropdown if there are more than 3 forms
    const enableSearchableDropdown = radioOptions.length > 3;

    if (this.props.intakeId) {
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    }

    return <div>
      <h1>Welcome to Caseflow Intake!</h1>
      <p>To get started, choose the form you are processing for intake.</p>

      {!enableSearchableDropdown && <RadioField
        name="form-select"
        label="Which form are you processing?"
        vertical
        strongLabel
        options={radioOptions}
        onChange={this.props.setFormType}
        value={this.props.formType}
      />}

      {enableSearchableDropdown && <SearchableDropdown
        name="form-select"
        label="Which form are you processing?"
        placeholder="Enter or select form"
        options={radioOptions}
        onChange={this.props.setFormType}
        value={this.props.formType} />}
    </div>;
  }
}

export default connect(
  ({ intake }) => ({
    formType: intake.formType,
    intakeId: intake.id
  }),
  (dispatch) => bindActionCreators({
    setFormType
  }, dispatch)
)(SelectForm);

class SelectFormButtonUnconnected extends React.PureComponent {
  handleClick = () => {
    this.props.history.push('/search');
  }

  render = () =>
    <Button
      name="continue-to-search"
      onClick={this.handleClick}
      legacyStyling={false}
      disabled={!this.props.formType}
    >
      Continue to search
    </Button>;
}

export const SelectFormButton = connect(
  ({ intake }) => ({ formType: intake.formType }),
)(SelectFormButtonUnconnected);
