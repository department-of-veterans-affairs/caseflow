import PropTypes from 'prop-types';
import React, { useContext, useEffect } from 'react';

import {
  HearingsFormContext,
  UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION
} from '../../contexts/HearingsFormContext';
import SearchableDropdown from '../../../components/SearchableDropdown';
import TextareaField from '../../../components/TextareaField';

const ScheduleHearingLaterWithAdminActionForm = (props) => {
  const { adminActionOptions, showErrorMessages } = props;
  const hearingsFormContext = useContext(HearingsFormContext);
  const scheduleHearingLaterWithAdminActionForm =
    hearingsFormContext.state.hearingForms?.scheduleHearingLaterWithAdminActionForm || {};

  useEffect(
    () => {
      const getErrorMessages = () => {
        return {
          withAdminActionKlass: (
            scheduleHearingLaterWithAdminActionForm.withAdminActionKlass ? null : 'Please enter an action'
          ),
          hasErrorMessages: !scheduleHearingLaterWithAdminActionForm.withAdminActionKlass
        };
      };

      const getApiFormattedValues = () => {
        return {
          with_admin_action_klass: scheduleHearingLaterWithAdminActionForm.withAdminActionKlass,
          admin_action_instructions: scheduleHearingLaterWithAdminActionForm.adminActionInstructions
        };
      };

      hearingsFormContext.dispatch({
        type: UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION,
        payload: {
          errorMessages: getErrorMessages(),
          apiFormattedValues: getApiFormattedValues()
        }
      });
    },
    [
      scheduleHearingLaterWithAdminActionForm.withAdminActionKlass,
      scheduleHearingLaterWithAdminActionForm.adminActionInstructions
    ]
  );

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
        onChange={(val) => {
          hearingsFormContext.dispatch({
            type: UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION,
            payload: {
              withAdminActionKlass: val?.value
            }
          });
        }}
      />
      <TextareaField
        label="Instructions"
        strongLabel
        name="adminActionInstructions"
        value={scheduleHearingLaterWithAdminActionForm?.adminActionInstructions}
        onChange={(val) => {
          hearingsFormContext.dispatch({
            type: UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION,
            payload: {
              adminActionInstructions: val
            }
          });
        }}
      />
    </div>
  );
};

ScheduleHearingLaterWithAdminActionForm.propTypes = {
  adminActionOptions: PropTypes.array,
  showErrorMessages: PropTypes.bool
};

export default ScheduleHearingLaterWithAdminActionForm;
