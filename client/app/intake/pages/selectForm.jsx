import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import { Redirect } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setFormType, clearSearchErrors } from '../actions/intake';
import { PAGE_PATHS, FORM_TYPES } from '../constants';
import _ from 'lodash';

class SelectForm extends React.PureComponent {
  setFormTypeFromDropdown = (formObject) => {
    this.props.setFormType(formObject.value);
  }

  render() {

    const enabledFormTypes = FORM_TYPES;

    const radioOptions = _.map(enabledFormTypes, (form) => ({
      value: form.key,
      displayText: form.name,
      label: form.name
    }));

    // Switch from radio buttons to searchable dropdown if there are more than 3 forms

    if (this.props.intakeId) {
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    }

    return <div>
      <h1>Welcome to Caseflow Intake!</h1>

      <SearchableDropdown
        name="form-select"
        label="Which form are you processing?"
        placeholder="Enter or select form"
        options={radioOptions}
        onChange={this.setFormTypeFromDropdown}
        value={this.props.formType} />
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
    this.props.clearSearchErrors();
    this.props.history.push('/search');
  }

  render = () =>
    <Button
      name="continue-to-search"
      onClick={this.handleClick}
      disabled={!this.props.formType}
    >
      Continue to search
    </Button>;
}

export const SelectFormButton = connect(
  ({ intake }) => ({ formType: intake.formType }),
  (dispatch) => bindActionCreators({
    clearSearchErrors
  }, dispatch)
)(SelectFormButtonUnconnected);
