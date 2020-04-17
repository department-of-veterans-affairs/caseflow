import React from 'react';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../../components/SearchableDropdown';
import TextareaField from '../../../components/TextareaField';

import {
  HearingsFormContext,
  UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION_FORM
} from '../../contexts/HearingsFormContext';

class ScheduleHearingLaterWithAdminActionForm extends React.Component {
  getErrorMessages = (newValues) => {
    const values = { ...this.props.scheduleHearingLaterWithAdminActionForm, ...newValues };

    return {
      withAdminActionKlass: values.withAdminActionKlass ? false : 'Please enter an action',
      hasErrorMessages: !values.withAdminActionKlass
    };
  }

  getApiFormattedValues = (newValues) => {
    const values = { ...this.props.scheduleHearingLaterWithAdminActionForm, ...newValues };

    return {
      with_admin_action_klass: values.withAdminActionKlass,
      admin_action_instructions: values.adminActionInstructions
    };
  }

  onChange = (value) => {
    const { dispatch } = this.context;

    dispatch({ type: UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION_FORM,
      payload: {
        ...value,
        errorMessages: this.getErrorMessages(value),
        apiFormattedValues: this.getApiFormattedValues(value)
      } });
  }

  render () {
    const { adminActionOptions, showErrorMessages, scheduleHearingLaterWithAdminActionForm } = this.props;

    return (
      <div>
        <SearchableDropdown
          errorMessage={
            showErrorMessages ? scheduleHearingLaterWithAdminActionForm?.errorMessages.withAdminActionKlass : ''
          }
          label="Select Reason"
          strongLabel
          name="postponementReason"
          options={adminActionOptions}
          value={scheduleHearingLaterWithAdminActionForm?.withAdminActionKlass}
          onChange={(val) => this.onChange({ withAdminActionKlass: val ? val.value : null })}
        />
        <TextareaField
          label="Instructions"
          strongLabel
          name="adminActionInstructions"
          value={scheduleHearingLaterWithAdminActionForm?.adminActionInstructions}
          onChange={(val) => this.onChange({ adminActionInstructions: val })}
        />
      </div>
    );
  }
}

ScheduleHearingLaterWithAdminActionForm.contextType = HearingsFormContext;

ScheduleHearingLaterWithAdminActionForm.propTypes = {
  adminActionOptions: PropTypes.object,
  showErrorMessages: PropTypes.bool,
  scheduleHearingLaterWithAdminActionForm: PropTypes.object
};

export default ScheduleHearingLaterWithAdminActionForm;
