import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import { isUndefined, get } from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React, { useState, useContext, useEffect } from 'react';
import { sprintf } from 'sprintf-js';

import { DetailsHeader } from './details/DetailsHeader';
import { HearingConversion } from './HearingConversion';
import {
  HearingsFormContext,
  updateHearingDispatcher,
  RESET_HEARING
} from '../contexts/HearingsFormContext';
import { HearingsUserContext } from '../contexts/HearingsUserContext';
import {
  deepDiff,
  getChanges,
  getAppellantTitle,
  processAlerts,
  startPolling,
  parseVirtualHearingErrors
} from '../utils';
import { inputFix } from './details/style';
import {
  onReceiveAlerts,
  onReceiveTransitioningAlert,
  transitionAlert,
  clearAlerts
} from '../../components/common/actions';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import DetailsForm from './details/DetailsForm';
import UserAlerts from '../../components/UserAlerts';
import VirtualHearingModal from './VirtualHearingModal';

import COPY from '../../../COPY';

/**
 * Hearing Details Component
 * @param {Object} props -- React props inherited from client/app/hearings/containers/DetailsContainer.jsx
 * @component
 */
const HearingDetails = (props) => {
  // Map the state and dispatch to relevant names
  const { state: { initialHearing, hearing, formsUpdated }, dispatch } = useContext(HearingsFormContext);

  // Pull out feature flag
  const { userUseFullPageVideoToVirtual } = useContext(HearingsUserContext);

  // Create the update hearing dispatcher
  const updateHearing = updateHearingDispatcher(hearing, dispatch);

  // Pull out the inherited state to handle actions
  const { saveHearing, goBack, disabled } = props;

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

  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);
  const convertingToVirtual = converting === 'change_to_virtual';
  // Method to reset the state
  const resetState = (resetHearingObj) => {
    // Reset the state
    setVirtualHearingErrors({});
    convertHearing('');
    setLoading(false);
    setError(false);

    // reset hearing
    if (resetHearingObj) {
      dispatch({ type: RESET_HEARING, payload: resetHearingObj });
    }

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

  const getEditedEmailsAndTz = () => {
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

  const submit = async (editedEmailsAndTz) => {
    try {
      // Determine the current state and whether to error
      const virtual = hearing.isVirtual || hearing.wasVirtual || converting;
      const noAppellantEmail = !hearing.virtualHearing?.appellantEmail;
      const noRepTimezone = convertingToVirtual ?
        !hearing.virtualHearing?.representativeTz && hearing.virtualHearing?.representativeEmail :
        editedEmailsAndTz?.representativeEmailEdited && !hearing.virtualHearing?.representativeTz;
      const noAppellantTimezone = convertingToVirtual ? !hearing.virtualHearing?.appellantTz :
        editedEmailsAndTz?.appellantEmailEdited && !hearing.virtualHearing?.appellantTz;

      const emailUpdated = (
        editedEmailsAndTz?.appellantEmailEdited ||
        (editedEmailsAndTz?.representativeEmailEdited && hearing.virtualHearing?.representativeEmail)
      );
      const timezoneUpdated = editedEmailsAndTz?.representativeTzEdited || editedEmailsAndTz?.appellantTzEdited;
      const errors = noAppellantEmail || noAppellantTimezone || noRepTimezone;

      if (virtual && errors) {
        // Set the Virtual Hearing errors
        setVirtualHearingErrors({
          [noAppellantEmail && 'appellantEmail']: `${appellantTitle} email is required`,
          [noRepTimezone && 'representativeTz']: COPY.VIRTUAL_HEARING_TIMEZONE_REQUIRED,
          [noAppellantTimezone && 'appellantTz']: COPY.VIRTUAL_HEARING_TIMEZONE_REQUIRED
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

      if (alerts) {
        processAlerts(alerts, props, setShouldStartPolling);
      }

      // Reset the state
      resetState(hearingResp);
    } catch (respError) {
      const code = get(respError, 'response.body.errors[0].code') || '';

      // Retrieve the error message from the body
      const msg = respError?.response?.body?.errors.length > 0 && respError?.response?.body?.errors[0]?.message;

      // Set the state with the error
      setLoading(false);

      // email validations should be thrown inline
      if (code === 1002) {
        // API errors from the server need to be bubbled up to the VirtualHearingModal so it can
        // update the email components with the validation error messages.
        const changingFromVideoToVirtualWithModalFlow = (
          hearing?.readableRequestType === 'Video' &&
          !hearing.isVirtual &&
          !userUseFullPageVideoToVirtual
        );

        if (changingFromVideoToVirtualWithModalFlow) {
          // 1002 is returned with an invalid email. rethrow respError, then re-catch it in VirtualHearingModal
          throw respError;
        } else {
          const errors = parseVirtualHearingErrors(msg);

          document.getElementById('email-section').scrollIntoView();

          setVirtualHearingErrors(errors);
        }
      } else {
        setError(msg);
      }
    }
  };

  const poll = () => startPolling(hearing, {
    resetState,
    setShouldStartPolling,
    dispatch,
    props
  });

  const editedEmailsAndTz = getEditedEmailsAndTz();
  const convertLabel = convertingToVirtual ?
    sprintf(COPY.CONVERT_HEARING_TITLE, 'Virtual') : sprintf(COPY.CONVERT_HEARING_TITLE, hearing.readableRequestType);

  return (
    <React.Fragment>
      <UserAlerts />
      {error && (
        <div>
          <Alert
            type="error"
            title={error === '' ? COPY.FAILED_HEARING_UPDATE : error}
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
              initialHearing={initialHearing}
              update={updateHearing}
              convertHearing={convertHearing}
              errors={virtualHearingErrors}
              isLegacy={isLegacy}
              openVirtualHearingModal={openVirtualHearingModal}
              readOnly={disabled}
              requestType={hearing?.readableRequestType}
            />
            {shouldStartPolling && poll()}
          </div>
        </AppSegment>
      )}
      <div {...css({ overflow: 'hidden' })}>
        <Button
          name="Cancel"
          linkStyling
          onClick={converting ? () => resetState(initialHearing) : goBack}
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
            onClick={async () => await submit(editedEmailsAndTz)}
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
          reset={() => resetState(initialHearing)}
          type={virtualHearingModalType}
          {...editedEmailsAndTz}
        />
      )}
    </React.Fragment>
  );
};

HearingDetails.propTypes = {
  saveHearing: PropTypes.func,
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
