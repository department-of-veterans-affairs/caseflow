/* eslint-disable camelcase */
import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import { sprintf } from 'sprintf-js';
import { isNil, maxBy, omit, find, get } from 'lodash';

import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import COPY from '../../../COPY';
import HEARING_DISPOSITION_TYPES from '../../../constants/HEARING_DISPOSITION_TYPES';
import { CENTRAL_OFFICE_HEARING_LABEL, VIDEO_HEARING_LABEL, VIRTUAL_HEARING_LABEL } from '../constants';
import { appealWithDetailSelector, scheduleHearingTasksForAppeal } from '../../queue/selectors';
import { showSuccessMessage, showErrorMessage, requestPatch } from '../../queue/uiReducer/uiActions';
import { onReceiveAppealDetails } from '../../queue/QueueActions';
import { formatDateStr } from '../../util/DateUtil';
import Alert from '../../components/Alert';
import { setMargin, marginTop, regionalOfficeSection, saveButton, cancelButton } from './details/style';
import { getAppellantTitle, processAlerts, parseVirtualHearingErrors } from '../utils';
import {
  onChangeFormData,
  onReceiveAlerts,
  onReceiveTransitioningAlert,
  transitionAlert,
  startPollingHearing,
} from '../../components/common/actions';
import { ScheduleVeteranForm } from './ScheduleVeteranForm';
import ApiUtil from '../../util/ApiUtil';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export const ScheduleVeteran = ({
  scheduleHearingTask,
  history,
  error,
  assignHearingForm,
  hearingDay,
  openHearing,
  appeal,
  scheduledHearing,
  ...props
}) => {
  // Create and manage the loading state
  const [loading, setLoading] = useState(false);

  // Create and manage the error state
  const [errors, setErrors] = useState({});

  // Get the appellant title ('Veteran' or 'Appellant')
  const appellantTitle = getAppellantTitle(appeal?.apppellantIsNotVeteran);

  // Get the selected hearing day
  const selectedHearingDay = assignHearingForm?.hearingDay || hearingDay;
  const initialRegionalOffice =
   selectedHearingDay?.regionalOffice || appeal?.closestRegionalOffice || appeal?.regionalOffice?.key;

  // Check whether to display the warning about full hearing days
  const fullHearingDay = selectedHearingDay?.filledSlots >= selectedHearingDay?.totalSlots;

  // Set the open hearing day message
  const openHearingDayError =
   `This appeal has an open hearing on ${formatDateStr(openHearing?.date)}. You cannot schedule another hearing.`;

  // Set the header for the page
  const header = `Schedule ${appellantTitle} for a Hearing`;

  // Determine the Request Type for the hearing
  const virtual = assignHearingForm?.virtualHearing;
  const requestType = selectedHearingDay?.regionalOffice === 'C' ?
    CENTRAL_OFFICE_HEARING_LABEL :
    VIDEO_HEARING_LABEL;

  // Determine whether we are rescheduling
  const reschedule = scheduledHearing?.action === 'reschedule';

  // Determine what disposition to assign for previous hearing
  const prevHearingDisposition = scheduledHearing?.disposition;

  // Set the task ID
  const taskId = scheduleHearingTask ? scheduleHearingTask.taskId : scheduledHearing?.taskId;

  // Create a hearing object for the form
  const hearing = {
    ...assignHearingForm,
    regionalOffice: assignHearingForm?.regionalOffice?.key,
    regionalOfficeTimezone: assignHearingForm?.regionalOffice?.timezone,
    representative: appeal?.powerOfAttorney?.representative_name,
    representativeType: appeal?.powerOfAttorney?.representative_type,
    representativeAddress: {
      addressLine1: appeal?.powerOfAttorney?.representative_address?.address_line_1,
      city: appeal?.powerOfAttorney?.representative_address?.city,
      state: appeal?.powerOfAttorney?.representative_address?.state,
      zip: appeal?.powerOfAttorney?.representative_address?.zip,
    },
    appellantFullName: appeal?.appellantFullName,
    appellantAddressLine1: appeal?.appellantAddress?.address_line_1,
    appellantCity: appeal?.appellantAddress?.city,
    appellantState: appeal?.appellantAddress?.state,
    appellantZip: appeal?.appellantAddress?.zip,
    veteranFullName: appeal?.veteranFullName,
  };

  // Reset the component state
  const reset = () => {
    // Clear any lingering errors
    setErrors({});

    // Remove any erroneous virtual hearing data
    props.onChangeFormData('assignHearing', { virtualHearing: null });
  };

  // Reset the state on unmount
  useEffect(() => {
    if (appeal?.readableHearingRequestType === VIRTUAL_HEARING_LABEL) {
      props.onChangeFormData('assignHearing', { virtualHearing: { status: 'pending' } });
    }

    return reset;
  }, []);

  const getSuccessMsg = () => {
    // Format the hearing date string
    const hearingDateStr = formatDateStr(hearing?.hearingDay?.hearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');

    // Format the alert title
    const title = sprintf(
      COPY.SCHEDULE_VETERAN_SUCCESS_MESSAGE_TITLE,
      appeal.appellantFullName,
      requestType,
      hearingDateStr
    );

    // Set the location to allow users to navigate
    const href = `/hearings/schedule/assign?regional_office_key=${hearing.hearingDay.regionalOffice}`;

    // Create the alert details
    const detail = (
      <p>
        {COPY.SCHEDULE_VETERAN_SUCCESS_MESSAGE_DETAIL}
        <br />
        <br />
        <Link href={href}>Back to Schedule Veterans</Link>
      </p>
    );

    // Return the alert data
    return { title, detail };
  };

  // Format the payload for the API
  const getPayload = () => {
    // The API can't accept a payload if the field `status` is provided because it is a generated
    // (not editable) field.
    //
    // `omit` returns an empty object if `null` is provided as an argument, so the `isNil` check here
    // prevents `omit` from returning an empty object.`
    const virtualHearing = isNil(hearing.virtualHearing) ? null : omit(hearing.virtualHearing, ['status']);

    // Format the shared hearing values
    const hearingValues = {
      scheduled_time_string: hearing.scheduledTimeString,
      hearing_day_id: hearing.hearingDay.hearingId,
      hearing_location: hearing.hearingLocation ? ApiUtil.convertToSnakeCase(hearing.hearingLocation) : null,
      virtual_hearing_attributes: virtualHearing ? ApiUtil.convertToSnakeCase(virtualHearing) : null
    };

    // Determine whether to send the reschedule payload
    const task = reschedule ? {
      status: TASK_STATUSES.cancelled,
      business_payloads: {
        values: {
          disposition: prevHearingDisposition,
          after_disposition_update: {
            action: 'reschedule',
            new_hearing_attrs: hearingValues,
          },
          ...(prevHearingDisposition === HEARING_DISPOSITION_TYPES.scheduled_in_error && {
            hearing_notes: scheduledHearing?.notes
          })
        }
      }
    } : {
      status: TASK_STATUSES.completed,
      business_payloads: {
        description: 'Update Task',
        values: {
          ...hearingValues,
          override_full_hearing_day_validation: fullHearingDay,
        },
      }
    };

    // Return the formatted data
    return { data: { task } };
  };

  // Submit the data to create the hearing
  const submit = async () => {
    try {
      // Check for form errors
      const formErrors = {
        hearingDay: (hearing.hearingDay && hearing.hearingDay.hearingId) ?
          null :
          'Please select a hearing date',
        hearingLocation: hearing.hearingLocation || hearing.virtualHearing ? null : 'Please select a hearing location',
        scheduledTimeString: hearing.scheduledTimeString ? null : 'Please select a hearing time',
        regionalOffice: hearing.regionalOffice || hearing.virtualHearing ? null : 'Please select a Regional Office '
      };

      // First validate the form
      if ((openHearing && !reschedule) || Object.values(formErrors).filter((err) => err !== null).length > 0) {
        return setErrors(formErrors);
      }

      // Set the loading state
      setLoading(true);

      // Format the payload to send to the API
      const payload = getPayload();

      // Patch the hearing task with the form data
      const { body } = await ApiUtil.patch(`/tasks/${taskId}`, payload);

      // Find the most recently created AssignHearingDispositionTask. This task will have the ID of the
      // most recently created hearing.
      const mostRecentTask = maxBy(
        body?.tasks?.data?.filter((task) => task.attributes?.type === 'AssignHearingDispositionTask') ?? [],
        (task) => task.id
      );

      const alerts = body?.tasks?.alerts;

      if (alerts && hearing.virtualHearing) {
        processAlerts(alerts, props, () => props.startPollingHearing(mostRecentTask?.attributes?.external_hearing_id));
      } else {
        props.showSuccessMessage(getSuccessMsg());
      }

      // Reset the state and navigate the user back
      reset();
      history.push(`/queue/appeals/${appeal.externalId}`);
    } catch (err) {
      const code = get(err, 'response.body.errors[0].code') || '';

      const [msg] = err?.response?.body?.errors.length > 0 && err?.response?.body?.errors;

      // Handle inline errors
      if (code === 1002) {
        // Parse the errors into a list
        const errList = parseVirtualHearingErrors(msg.message, appeal);

        // Scroll errors into view
        document.getElementById('email-section').scrollIntoView();

        setErrors(errList);

      // Handle errors in the standard format
      } else if (msg?.title) {
        props.showErrorMessage({
          title: msg?.title,
          detail: msg?.detail ?? msg?.message
        });

      // Handle legacy appeals
      } else if (appeal.isLegacyAppeal) {
        props.showErrorMessage({
          title: 'No Available Slots',
          detail:
                'Could not find any available slots for this regional office and hearing day combination. ' +
                'Please select a different date.',
        });
      } else {
        props.showErrorMessage({
          title: 'No Hearing Day',
          detail:
                'Until April 1st hearing days for AMA appeals need to be created manually. ' +
                'Please contact the Caseflow Team for assistance.',
        });
      }
    } finally {
      // Clear the loading state
      setLoading(false);
    }
  };

  // Method to handle changing the form fields when toggling between virtual
  const convertToVirtual = () => {
    if (virtual) {
      return props.onChangeFormData('assignHearing', {
        virtualHearing: null
      });
    }

    return props.onChangeFormData('assignHearing', {
      virtualHearing: { status: 'pending' }
    });
  };

  // Create the header styling based on video/virtual type
  const headerStyle = virtual ? setMargin('0 0 0.75rem 0') : setMargin(0);
  const helperTextStyle = virtual ? setMargin('0 0 2rem 0') : setMargin(0);

  return (
    <div {...regionalOfficeSection}>
      <AppSegment filledBackground >
        <h1 {...headerStyle}>{header}</h1>
        {error && <Alert title={error.title} type="error">{error.detail}</Alert>}
        {virtual ?
          <div {...helperTextStyle}>{COPY.SCHEDULE_VETERAN_DIRECT_TO_VIRTUAL_HELPER_LABEL}</div> :
          !fullHearingDay && <div {...marginTop(45)} />}

        {fullHearingDay && (
          <Alert
            title={COPY.SCHEDULE_VETERAN_FULL_HEARING_DAY_TITLE}
            type="warning"
          >
            {COPY.SCHEDULE_VETERAN_FULL_HEARING_DAY_MESSAGE_DETAIL}
          </Alert>
        )}
        {openHearing && !reschedule ? <Alert title="Open Hearing" type="error">{openHearingDayError}</Alert> : (
          <ScheduleVeteranForm
            initialHearingDate={selectedHearingDay?.hearingDate}
            initialRegionalOffice={initialRegionalOffice}
            errors={errors}
            appeal={appeal}
            virtual={Boolean(virtual)}
            hearing={hearing}
            appellantTitle={appellantTitle}
            onChange={(key, value) => props.onChangeFormData('assignHearing', { [key]: value })}
            convertToVirtual={convertToVirtual}
          />
        )}

      </AppSegment>
      <Button
        name="Cancel"
        linkStyling
        onClick={() => history.goBack()}
        styling={cancelButton}
      >
          Cancel
      </Button>
      <span {...saveButton}>
        <Button
          disabled={openHearing && !reschedule}
          name="Schedule"
          loading={loading}
          className="usa-button"
          onClick={async () => await submit()}
        >
          Schedule
        </Button>
      </span>
    </div>
  );
};

ScheduleVeteran.propTypes = {
  appeals: PropTypes.object,
  // Router inherited props
  history: PropTypes.object,
  appealId: PropTypes.string,
  // The open hearing for an appeal (if it exists).
  openHearing: PropTypes.shape({
    date: PropTypes.string,
  }),
  appeal: PropTypes.shape({
    appellantAddress: PropTypes.object,
    externalId: PropTypes.string,
    isLegacyAppeal: PropTypes.bool,
    regionalOffice: PropTypes.object,
    powerOfAttorney: PropTypes.object,
    appellantFullName: PropTypes.string,
  }),
  assignHearingForm: PropTypes.shape({
    apiFormattedValues: PropTypes.object,
    errorMessages: PropTypes.shape({
      hasErrorMessages: PropTypes.bool,
    }),
    hearingDay: PropTypes.shape({
      hearingDate: PropTypes.string,
      regionalOffice: PropTypes.string,
    }),
  }),
  hearingDay: PropTypes.shape({
    hearingDate: PropTypes.string,
    regionalOffice: PropTypes.string,
  }),
  scheduleHearingTask: PropTypes.shape({
    taskId: PropTypes.string,
  }),
  onReceiveAppealDetails: PropTypes.func,
  startPollingHearing: PropTypes.func,
  requestPatch: PropTypes.func,
  showErrorMessage: PropTypes.func,
  onChangeFormData: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  selectedRegionalOffice: PropTypes.object,
  error: PropTypes.object,
  scheduledHearing: PropTypes.object,
};

const mapStateToProps = (state, ownProps) => ({
  scheduledHearing: state.components.scheduledHearing,
  scheduleHearingTask: scheduleHearingTasksForAppeal(state, {
    appealId: ownProps.appealId,
  })[0],
  openHearing: find(
    appealWithDetailSelector(state, ownProps).hearings,
    (hearing) => hearing.disposition === null
  ),
  assignHearingForm: state.components.forms.assignHearing,
  appeal: appealWithDetailSelector(state, ownProps),
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  hearingDay: state.ui.hearingDay,
  error: state.ui.messages.error
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      onReceiveAlerts,
      onReceiveTransitioningAlert,
      transitionAlert,
      onChangeFormData,
      showErrorMessage,
      showSuccessMessage,
      requestPatch,
      startPollingHearing,
      onReceiveAppealDetails,
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(ScheduleVeteran)
);

/* eslint-enable camelcase */
