import React from 'react';
import RadioField from '../../components/RadioField';
import Button from '../../components/Button';
import { Redirect } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setFormType } from '../actions/common';
import { FORM_TYPES, PAGE_PATHS } from '../constants';
import _ from 'lodash';

class SelectForm extends React.PureComponent {
  render() {
    const radioOptions = _.map(FORM_TYPES,
      (form) => ({ value: form.key,
        displayText: form.name }));

    if (this.props.intakeId) {
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    }

    return <div>
      <h1>Welcome to Caseflow Intake!</h1>
      <p>Please select the form you are processing from the Centralized Mail Portal.</p>

      <RadioField
        name="form-select"
        label="Which form are you processing?"
        vertical
        strongLabel
        options={radioOptions}
        onChange={this.props.setFormType}
        value={this.props.formType}
      />
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
