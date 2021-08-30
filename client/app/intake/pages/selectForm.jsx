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
import COPY from '../../../COPY';
import _ from 'lodash';

class SelectForm extends React.PureComponent {
  setFormTypeFromDropdown = (formObject) => {
    this.props.setFormType(formObject.value);
  }

  render() {
    const { formType, featureToggles, userCanIntakeAppeals } = this.props;
    const unreadMessages = this.props.unreadMessages;
    const rampEnabled = featureToggles.rampIntake;
    const enabledFormTypes = rampEnabled ? FORM_TYPES : _.pickBy(FORM_TYPES, { category: 'decisionReview' });
    const appealPermissionError = !userCanIntakeAppeals && formType === FORM_TYPES.APPEAL.key;

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

      { appealPermissionError && <Alert
        title="Not Authorized"
        type="error"
        lowerMargin>
        {COPY.INTAKE_APPEAL_PERMISSIONS_ALERT}
      </Alert>
      }

      { unreadMessages && <Alert
        title="Intake Jobs"
        type="warning"
        lowerMargin>You have <a href="/inbox">unread messages</a>.
      </Alert>
      }

      { !enableSearchableDropdown && <RadioField
        name="intake-form-select"
        label={COPY.INTAKE_FORM_SELECTION}
        vertical
        strongLabel
        options={radioOptions}
        onChange={this.props.setFormType}
        value={formType}
      />
      }

      { enableSearchableDropdown && <SearchableDropdown
        name="intake-form-select"
        label={COPY.INTAKE_FORM_SELECTION}
        placeholder="Enter or select form"
        options={radioOptions}
        onChange={this.setFormTypeFromDropdown}
        value={formType} />
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

  render() {
    const { formType, userCanIntakeAppeals } = this.props;
    const appealPermissionError = !userCanIntakeAppeals && formType === FORM_TYPES.APPEAL.key;

    return <Button
      name="continue-to-search"
      onClick={this.handleClick}
      disabled={!formType || appealPermissionError}
    >
      Continue to search
    </Button>;
  }
}

export const SelectFormButton = connect(
  ({ intake }) => ({
    formType: intake.formType }),
  (dispatch) => bindActionCreators({
    clearSearchErrors
  }, dispatch)
)(SelectFormButtonUnconnected);
