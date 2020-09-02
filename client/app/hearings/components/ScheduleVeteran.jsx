import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import { sprintf } from 'sprintf-js';

import COPY from '../../../COPY';
import { appealWithDetailSelector, scheduleHearingTasksForAppeal } from '../../queue/selectors';
import { showErrorMessage, requestPatch } from '../../queue/uiReducer/uiActions';
import { onReceiveAppealDetails } from '../../queue/QueueActions';
import { formatDateStr } from '../../util/DateUtil';
import Alert from '../../components/Alert';
import { marginTop, regionalOfficeSection, saveButton, cancelButton } from './details/style';
import { find } from 'lodash';
import { getAppellantTitleForHearing } from '../utils';
import { onChangeFormData } from '../../components/common/actions';
import { ScheduleVeteranForm } from './ScheduleVeteranForm';
import { HEARING_REQUEST_TYPES } from '../constants';
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
  ...props
}) => {
  console.log('APPEAL: ', appeal);

  console.log('HEARING DAY: ', hearingDay);

  // Create and manage the loading state
  const [loading, setLoading] = useState(false);

  // Create and manage the error state
  const [errors, setErrors] = useState({});

  // Get the appellant title ('Veteran' or 'Appellant')
  const appellantTitle = getAppellantTitleForHearing(appeal);

  // Get the selected hearing day
  const selectedHearingDay = assignHearingForm?.hearingDay || hearingDay;

  // Check whether to display the warning about full hearing days
  const fullHearingDay = selectedHearingDay?.filledSlots >= selectedHearingDay?.totalSlots;

  // Set the open hearing day message
  const openHearingDayError =
   `This appeal has an open hearing on ${formatDateStr(openHearing?.date)}. You cannot schedule another hearing.`;

  // Set the header for the page
  const header = `Schedule ${appellantTitle} for a Hearing`;

  // Determine the Request Type for the hearing
  const virtual = assignHearingForm?.virtualHearing;
  const requestType = HEARING_REQUEST_TYPES[selectedHearingDay?.requestType] || 'Video';

  // Create a hearing object for the form
  const hearing = {
    /* eslint-disable camelcase */
    ...assignHearingForm,
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
    requestType
    /* eslint-enable camelcase */
  };

  // Reset the component state
  const reset = () => {
    // Clear the loading state
    setLoading(false);

    // Clear any lingering errors
    setErrors({});

    // Remove any erroneous virtual hearing data
    props.onChangeFormData('assignHearing', { virtualHearing: null });
  };

  // Initialize the state
  useEffect(() => () => reset(), []);

  const getSuccessMsg = () => {
    // Format the hearing date string
    const hearingDateStr = formatDateStr(hearing?.hearingDay?.hearingDate, 'YYYY-MM-DD', 'MM/DD/YYYY');

    // Format the alert title
    const title = sprintf(
      COPY.SCHEDULE_VETERAN_SUCCESS_MESSAGE_TITLE,
      appeal.appellantFullName,
      hearing.regionalOffice ? HEARING_REQUEST_TYPES.V : HEARING_REQUEST_TYPES.C,
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
        regionalOffice: hearing.regionalOffice ? null : 'Please select a Regional Office '
      };

      // First validate the form
      if (openHearing || Object.values(formErrors).filter((err) => err !== null).length > 0) {
        return setErrors(formErrors);
      }

      // Set the loading state
      setLoading(true);

      // Format the payload to send to the API
      const payload = {
        data: {
          task: {
            status: 'completed',
            business_payloads: {
              description: 'Update Task',
              values: {
                scheduled_time_string: hearing.scheduledTimeString,
                hearing_day_id: hearing.hearingDay.hearingId,
                hearing_location: hearing.hearingLocation ? ApiUtil.convertToSnakeCase(hearing.hearingLocation) : null,
                override_full_hearing_day_validation: fullHearingDay,
                virtual_hearing_attributes: hearing.virtualHearing
              },
            },
          },
        },
      };

      console.log('DATA: ', payload);

      // Patch the hearing task with the form data
      await props.requestPatch(`/tasks/${scheduleHearingTask.taskId}`, payload, getSuccessMsg());

      // Reset the state and navigate the user back
      reset();
      history.goBack();
    } catch (err) {
      // Remove the loading state on error
      setLoading(false);

      // Handle legacy appeals
      if (appeal.isLegacyAppeal) {
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
    }
  };

  return (
    <div {...regionalOfficeSection}>

      <AppSegment filledBackground >
        <h1>{header}</h1>
        {virtual ?
          <div {...marginTop(0)}>{COPY.SCHEDULE_VETERAN_DIRECT_TO_VIRTUAL_HELPER_LABEL}</div> :
          !fullHearingDay && <div {...marginTop(45)} />}

        {fullHearingDay && (
          <Alert
            title={COPY.SCHEDULE_VETERAN_FULL_HEARING_DAY_TITLE}
            type="warning"
          >
            {COPY.SCHEDULE_VETERAN_FULL_HEARING_DAY_MESSAGE_DETAIL}
          </Alert>
        )}
        {error && <Alert title={error.title} type="error">{error.detail}</Alert>}
        {openHearing ? <Alert title="Open Hearing" type="error">{openHearingDayError}</Alert> : (
          <ScheduleVeteranForm
            initialRegionalOffice={hearingDay?.regionalOffice || appeal?.regionalOffice?.key}
            errors={errors}
            appeal={appeal}
            virtual={Boolean(virtual)}
            hearing={hearing}
            appellantTitle={appellantTitle}
            onChange={(key, value) => props.onChangeFormData('assignHearing', { [key]: value })}
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
          disabled={openHearing}
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
  appeals: PropTypes.array,
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
  requestPatch: PropTypes.func,
  showErrorMessage: PropTypes.func,
  onChangeFormData: PropTypes.func,
  selectedRegionalOffice: PropTypes.string,
  error: PropTypes.object,
};

const mapStateToProps = (state, ownProps) => ({
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
      onChangeFormData,
      showErrorMessage,
      requestPatch,
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
