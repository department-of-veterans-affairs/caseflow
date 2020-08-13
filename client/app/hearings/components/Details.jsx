import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React, { useState, useContext, useEffect } from 'react';
import { isEmpty, isUndefined, get } from 'lodash';

import { HearingsFormContext, updateHearingDispatcher, RESET_HEARING } from '../contexts/HearingsFormContext';
import {
  onReceiveAlerts,
  onReceiveTransitioningAlert,
  transitionAlert,
  clearAlerts
} from '../../components/common/actions';
import Alert from '../../components/Alert';
import Button from '../../components/Button';
import UserAlerts from '../../components/UserAlerts';
import ApiUtil from '../../util/ApiUtil';
import { deepDiff, pollVirtualHearingData, getChanges, getAppellantTitleForHearing } from '../utils';
import DetailsForm from './details/DetailsForm';
import { DetailsHeader } from './details/DetailsHeader';
import VirtualHearingModal from './VirtualHearingModal';
import { HearingConversion } from './HearingConversion';
import { inputFix } from './details/style';

/**
 * Hearing Details Component
 * @param {Object} props -- React props inherited from client/app/hearings/containers/DetailsContainer.jsx
 * @component
 */
const HearingDetails = (props) => {
  // Map the state and dispatch to relevant names
  const { state: { initialHearing, hearing, formsUpdated }, dispatch } = useContext(HearingsFormContext);

  // Create the update hearing dispatcher
  const updateHearing = updateHearingDispatcher(hearing, dispatch);

  // Pull out the inherited state to handle actions
  const { saveHearing, setHearing, goBack, disabled } = props;

  // Determine whether this is a legacy hearing
  const isLegacy = hearing?.docketName !== 'hearing';

  // Establish the state of the hearing details
  const [converting, convertHearing] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [virtualHearingErrors, setVirtualHearingErrors] = useState({});
  const [virtualHearingModalOpen, setVirtualHearingModalOpen] = useState(false);
  const [virtualHearingModalType, setVirtualHearingModalType] = useState(null);
  const [shouldStartPolling, setShouldStartPolling] = useState(null);

  // Method to reset the state
  const reset = (initialState) => {
    // Reset the state
    setVirtualHearingErrors({});
    convertHearing('');
    setLoading(false);
    setError(false);
    dispatch({ type: RESET_HEARING, payload: initialState });

    // Focus the top of the page
    window.scrollTo(0, 0);
  };

  // Create an effect to remove stale alerts on unmount
  useEffect(() => () => props.clearAlerts(), []);

  const openVirtualHearingModal = ({ type }) => {
    setVirtualHearingModalOpen(true);
    setVirtualHearingModalType(type);
  };

  const closeVirtualHearingModal = () => setVirtualHearingModalOpen(false);

  const getEditedEmails = () => {
    const changes = deepDiff(
      initialHearing.virtualHearing,
      hearing.virtualHearing || {}
    );

    return {
      appellantEmailEdited: !isUndefined(changes.appellantEmail),
      representativeEmailEdited: !isUndefined(changes.representativeEmail),
      representativeTzEdited: !isUndefined(changes.representativeTz),
      appellantTzEdited: !isUndefined(changes.appellantTz)
    };
  };

  const submit = async (editedEmails) => {
    try {
      // Determine the current state and whether to error
      const virtual = hearing.isVirtual || hearing.wasVirtual || converting;
      const noEmail = !hearing.virtualHearing?.appellantEmail;
      const noRepEmail = !hearing.virtualHearing?.representativeEmail && hearing.virtualHearing?.representativeTz;
      const noRepTimezone = !hearing.virtualHearing?.representativeTz && hearing.virtualHearing?.representativeEmail;
      const emailUpdated = editedEmails?.appellantEmailEdited || editedEmails?.representativeEmailEdited;
      const timezoneUpdated = editedEmails?.representativeTzEdited || editedEmails?.appellantTzEdited;
      const errors = noEmail || ((noRepTimezone || noRepEmail) && hearing.readableRequestType !== 'Video');

      if (virtual && errors) {
        // Set the Virtual Hearing errors
        setVirtualHearingErrors({
          [noRepEmail && 'representativeEmail']: 'POA/Representative email is required',
          [noEmail && 'appellantEmail']: `${getAppellantTitleForHearing(hearing)} email is required`,
          [noRepTimezone && 'representativeTz']: 'Timezone is required to send email notifications.'
        });

        // Focus to the error
        return document.getElementById('email-section').scrollIntoView();
      } else if ((emailUpdated || timezoneUpdated) && !converting) {
        return openVirtualHearingModal({ type: 'change_email_or_timezone' });
      }

      // Only send updated properties
      const { virtualHearing, transcription, ...hearingChanges } = getChanges(
        initialHearing,
        hearing
      );

      // Put the UI into a loading state
      setLoading(true);

      // Save the hearing
      const response = await saveHearing({
        hearing: {
          ...(hearingChanges || {}),
          transcription_attributes: {
            // Always send full transcription details because a new record is created each update
            ...(transcription ? hearing.transcription : {}),
          },
          virtual_hearing_attributes: {
            ...(virtualHearing || {}),
          },
        },
      });
      const hearingResp = ApiUtil.convertToCamelCase(response.body?.data);
      const alerts = response.body?.alerts;

      // set hearing on DetailsContainer
      setHearing(hearingResp, () => {
        if (alerts) {
          const { hearing: hearingAlerts, virtual_hearing: virtualHearingAlerts } = alerts;

          if (hearingAlerts) {
            props.onReceiveAlerts(hearingAlerts);
          }

          if (!isEmpty(virtualHearingAlerts)) {
            props.onReceiveTransitioningAlert(virtualHearingAlerts, 'virtualHearing');
            setShouldStartPolling(true);
          }
        }

        // Reset the state
        reset(hearingResp);
      });
    } catch (respError) {
      const code = get(respError, 'response.body.errors[0].code') || '';

      // Retrieve the error message from the body
      const msg = respError?.response?.body?.errors.length > 0 && respError?.response?.body?.errors[0]?.message;

      // Set the state with the error
      setLoading(false);

      if (code === 1002 && hearing?.readableRequestType === 'Video') {
        // 1002 is returned with an invalid email. rethrow respError, then re-catch it in VirtualHearingModal
        setError(msg);
        throw respError;
      }

      // Remove the validation string from th error
      const messages = msg.split(':')[1];

      // Set inline errors if not Video because it doesnt use the VirtualHearingModal
      const errors = messages.split(',').reduce((list, message) => ({
        ...list,
        [(/Representative/).test(message) ? 'representativeEmail' : 'appellantEmail']:
          message.replace('Appellant', getAppellantTitleForHearing(hearing))
      }), {});

      document.getElementById('email-section').scrollIntoView();

      setVirtualHearingErrors(errors);
    }
  };

  const startPolling = () => {
    return pollVirtualHearingData(hearing?.externalId, (response) => {
      // response includes jobCompleted, aliasWithHost, guestPin, hostPin,
      // guestLink, and hostLink
      const resp = ApiUtil.convertToCamelCase(response);

      if (resp.jobCompleted) {
        setShouldStartPolling(false);

        // Reset the state with the new details
        reset({
          ...hearing,
          virtualHearing: {
            ...hearing.virtualHearing,
            ...resp,
          },
        });
        props.transitionAlert('virtualHearing');
      }

      // continue polling if return true (opposite of job_completed)
      return !response.job_completed;
    });
  };

  const editedEmails = getEditedEmails();
  const convertLabel = converting === 'change_to_virtual' ?
    'Convert to Virtual Hearing' : 'Convert to Central Office Hearing';

  return (
    <React.Fragment>
      <UserAlerts />
      {error && (
        <div>
          <Alert
            type="error"
            title={error === '' ? 'There was an error updating the hearing' : error}
          />
        </div>
      )}
      {converting ? (
        <HearingConversion
          title={convertLabel}
          type={converting}
          update={updateHearing}
          hearing={hearing}
          scheduledFor={hearing?.scheduledFor}
          errors={virtualHearingErrors}
        />
      ) : (
        <AppSegment filledBackground>
          <div {...inputFix}>
            <DetailsHeader
              aod={hearing?.aod}
              disposition={hearing?.disposition}
              docketName={hearing?.docketName}
              docketNumber={hearing?.docketNumber}
              isVirtual={hearing?.isVirtual}
              hearingDayId={hearing?.hearingDayId}
              readableLocation={hearing?.readableLocation}
              readableRequestType={hearing?.readableRequestType}
              regionalOfficeName={hearing?.regionalOfficeName}
              scheduledFor={hearing?.scheduledFor}
              veteranFileNumber={hearing?.veteranFileNumber}
              veteranFirstName={hearing?.veteranFirstName}
              veteranLastName={hearing?.veteranLastName}
            />
            <DetailsForm
              hearing={hearing}
              update={updateHearing}
              convertHearing={convertHearing}
              errors={virtualHearingErrors}
              isLegacy={isLegacy}
              openVirtualHearingModal={openVirtualHearingModal}
              readOnly={disabled}
              requestType={hearing?.readableRequestType}
            />
            {shouldStartPolling && startPolling()}
          </div>
        </AppSegment>
      )}
      <div {...css({ overflow: 'hidden' })}>
        <Button
          name="Cancel"
          linkStyling
          onClick={converting ? () => reset(initialHearing) : goBack}
          styling={css({ float: 'left', paddingLeft: 0, paddingRight: 0 })}
        >
          Cancel
        </Button>
        <span {...css({ float: 'right' })}>
          <Button
            name="Save"
            disabled={!formsUpdated || disabled}
            loading={loading}
            className="usa-button"
            onClick={async () => await submit(editedEmails)}
          >
            {converting ? convertLabel : 'Save'}
          </Button>
        </span>
      </div>
      {virtualHearingModalOpen && (
        <VirtualHearingModal
          hearing={hearing}
          virtualHearing={hearing?.virtualHearing}
          update={updateHearing}
          submit={submit}
          closeModal={closeVirtualHearingModal}
          reset={() => reset(initialHearing)}
          type={virtualHearingModalType}
          {...editedEmails}
        />
      )}
    </React.Fragment>
  );
};

HearingDetails.propTypes = {
  hearing: PropTypes.object.isRequired,
  saveHearing: PropTypes.func,
  setHearing: PropTypes.func,
  goBack: PropTypes.func,
  disabled: PropTypes.bool,
  onReceiveAlerts: PropTypes.func,
  onReceiveTransitioningAlert: PropTypes.func,
  transitionAlert: PropTypes.func,
  clearAlerts: PropTypes.func,
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({ clearAlerts, onReceiveAlerts, onReceiveTransitioningAlert, transitionAlert }, dispatch);

export default connect(
  null,
  mapDispatchToProps
)(HearingDetails);
