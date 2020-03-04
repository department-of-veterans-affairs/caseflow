/* eslint-disable react/prop-types */

import React from 'react';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
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
    const inboxFeature = this.props.featureToggles.inbox;
    const unreadMessages = this.props.unreadMessages;

    const rampEnabled = this.props.featureToggles.rampIntake;
    const enabledFormTypes = rampEnabled ? FORM_TYPES : _.pickBy(FORM_TYPES, { category: 'decisionReview' });

    const restrictAppealIntakes = this.props.featureToggles.restrictAppealIntakes;
    const userCanIntakeAppeals = this.props.userCanIntakeAppeals;

    if (restrictAppealIntakes && !userCanIntakeAppeals) {
      delete enabledFormTypes.APPEAL;
    }

    const radioOptions = _.map(enabledFormTypes, (form) => ({
      value: form.key,
      displayText: form.name,
      label: form.name
    }));

    const enableSearchableDropdown = radioOptions.length > 3;

    if (this.props.intakeId) {
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    }

    return <div>
      <h1>Welcome to Caseflow Intake!</h1>

      { inboxFeature && unreadMessages && <Alert
        title="Intake Jobs"
        type="warning"
        lowerMargin>You have <a href="/inbox">unread messages</a>.
      </Alert>
      }

      { !enableSearchableDropdown && <RadioField
        name="form-select"
        label="Which form are you processing?"
        vertical
        strongLabel
        options={radioOptions}
        onChange={this.props.setFormType}
        value={this.props.formType}
      />
      }

      { enableSearchableDropdown && <SearchableDropdown
        name="form-select"
        label="Which form are you processing?"
        placeholder="Enter or select form"
        options={radioOptions}
        onChange={this.setFormTypeFromDropdown}
        value={this.props.formType} />
      }
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
