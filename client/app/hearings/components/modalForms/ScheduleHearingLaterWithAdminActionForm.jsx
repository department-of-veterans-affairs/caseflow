import React, { useContext } from 'react';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../../components/SearchableDropdown';
import TextareaField from '../../../components/TextareaField';

import {
  HearingsFormContext,
  UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION
} from '../../contexts/HearingsFormContext';

const ScheduleHearingLaterWithAdminActionForm = (props) => {
  const { adminActionOptions, showErrorMessages } = props;
  const hearingsFormContext = useContext(HearingsFormContext);
  const scheduleHearingLaterWithAdminActionForm =
    hearingsFormContext.state.hearingForms?.scheduleHearingLaterWithAdminActionForm || {};

  const getErrorMessages = (newValues) => {
    const values = { ...scheduleHearingLaterWithAdminActionForm, ...newValues };

    return {
      withAdminActionKlass: values.withAdminActionKlass ? false : 'Please enter an action',
      hasErrorMessages: !values.withAdminActionKlass
    };
  };

  const getApiFormattedValues = (newValues) => {
    const values = { ...scheduleHearingLaterWithAdminActionForm, ...newValues };

    return {
      with_admin_action_klass: values.withAdminActionKlass,
      admin_action_instructions: values.adminActionInstructions
    };
  };

  const onChange = (value) => {
    hearingsFormContext.dispatch({ type: UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION,
      payload: {
        ...value,
        errorMessages: getErrorMessages(value),
        apiFormattedValues: getApiFormattedValues(value)
      } });
  };

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
        onChange={(val) => onChange({ withAdminActionKlass: val ? val.value : null })}
      />
      <TextareaField
        label="Instructions"
        strongLabel
        name="adminActionInstructions"
        value={scheduleHearingLaterWithAdminActionForm?.adminActionInstructions}
        onChange={(val) => onChange({ adminActionInstructions: val })}
      />
    </div>
  );
};

ScheduleHearingLaterWithAdminActionForm.propTypes = {
  adminActionOptions: PropTypes.array,
  showErrorMessages: PropTypes.bool
};

export default ScheduleHearingLaterWithAdminActionForm;
