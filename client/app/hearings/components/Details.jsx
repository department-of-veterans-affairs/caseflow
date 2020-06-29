import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React, { useState, useContext } from 'react';
import { isEmpty, isUndefined, get } from 'lodash';

import { DetailsHeader } from './details/DetailsHeader';
import { HearingsFormContext, SET_UPDATED, RESET_HEARING } from '../contexts/HearingsFormContext';
import { deepDiff, pollVirtualHearingData, getChanges } from '../utils';
import { onReceiveAlerts, onReceiveTransitioningAlert, transitionAlert } from '../../components/common/actions';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import DetailsForm from './details/DetailsForm';
import UserAlerts from '../../components/UserAlerts';
import VirtualHearingModal from './VirtualHearingModal';
import { HearingConversion } from './HearingConversion';

const inputFix = css({
  '& .question-label': {
    marginBottom: '2rem !important'
  }
});

const HearingDetails = (props) => {
  // Map the state and dispatch to relevant names
  const { state: { initialHearing, hearing }, dispatch } = useContext(HearingsFormContext);

  const updateHearing = (type, changes) => {
    const payload = type === 'hearing' ? {
      ...hearing,
      ...changes
    } : {
      ...hearing,
      [type]: {
        ...hearing[type],
        ...changes
      }
    };

    return dispatch({ type: SET_UPDATED, payload });
  };

  const resetHearing = (payload) => dispatch({ type: RESET_HEARING, payload });

  const { saveHearing, setHearing, goBack, disabled } = props;

  const {
    aod,
    externalId,
    veteranFirstName,
    veteranLastName,
    veteranFileNumber,
    scheduledFor,
    docketName,
    docketNumber,
    readableRequestType,
    hearingDayId,
    regionalOfficeName,
    readableLocation,
    disposition
  } = hearing;

  const isLegacy = docketName !== 'hearing';

  const [converting, convertHearing] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);
  const [virtualHearingErrors, setVirtualHearingErrors] = useState({});
  const [virtualHearingModalOpen, setVirtualHearingModalOpen] = useState(false);
  const [virtualHearingModalType, setVirtualHearingModalType] = useState(null);
  const [shouldStartPolling, setShouldStartPolling] = useState(null);

  // Get the hearing details state
  const { state: { formsUpdated } } = useContext(HearingsFormContext);

  const openVirtualHearingModal = ({ type }) => {
    setVirtualHearingModalOpen(true);
    setVirtualHearingModalType(type);
  };

  const closeVirtualHearingModal = () => setVirtualHearingModalOpen(false);

  const getEditedEmails = () => {
    const changes = deepDiff(initialHearing.virtualHearing, hearing.virtualHearing || {});

    return {
      appellantEmailEdited: !isUndefined(changes.appellantEmail),
      representativeEmailEdited: !isUndefined(changes.representativeEmail)
    };
  };

  const submit = async (editedEmails) => {
    try {
      const virtual = hearing.isVirtual || hearing.wasVirtual;

      if (
        virtual &&
      (!hearing.virtualHearing?.representativeEmail || !hearing.virtualHearing?.appellantEmail)
      ) {
      // Set the Virtual Hearing errors
        setVirtualHearingErrors({
          [!hearing.virtualHearing.appellantEmail && 'appellantEmail']: 'Appellant email is required',
          [!hearing.virtualHearing.representativeEmail && 'representativeEmail']: 'Representative email is required'
        });

        // Focus to the error
        return document.getElementById('email-section').scrollIntoView();
      } else if (editedEmails?.representativeEmailEdited || editedEmails?.appellantEmailEdited) {
        return openVirtualHearingModal({ type: 'change_email' });
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
            ...(transcription ? hearing.transcription : {})
          },
          virtual_hearing_attributes: {
            ...(virtualHearing || {})
          }
        }
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
        setVirtualHearingErrors({});
        setLoading(false);
        setError(false);
        resetHearing(hearingResp);
      });

    } catch (respError) {
      const code = get(respError, 'response.body.errors[0].code') || '';

      if (code === 1002) {
        // 1002 is returned with an invalid email. rethrow respError, then re-catch it in VirtualHearingModal
        throw respError;
      }
      setLoading(false);
      setError(respError.message);

    }
  };

  const startPolling = () => {
    return pollVirtualHearingData(externalId, (response) => {
      // response includes jobCompleted, aliasWithHost, guestPin, hostPin,
      // guestLink, and hostLink
      const resp = ApiUtil.convertToCamelCase(response);

      if (resp.jobCompleted) {
        setShouldStartPolling(false);

        // Reset the state with the new details
        resetHearing({
          ...hearing,
          virtualHearing: {
            ...hearing.virtualHearing,
            ...resp
          }
        });
        props.transitionAlert('virtualHearing');
      }

      // continue polling if return true (opposite of job_completed)
      return !response.job_completed;
    });
  };

  const cancelConvert = () => {
    convertHearing('');

    // Focus the top of the page
    window.scrollTo(0, 0);
  };

  const editedEmails = getEditedEmails();

  if (shouldStartPolling) {
    startPolling();
  }

  return (
    <React.Fragment>
      <UserAlerts />
      {error && (
        <div>
          <Alert type="error" title="There was an error updating the hearing" />
        </div>
      )}
      {converting ? (
        <HearingConversion type={converting} update={updateHearing} hearing={hearing} scheduledFor={scheduledFor} />
      ) : (
        <AppSegment filledBackground>
          <div {...inputFix}>
            <DetailsHeader
              aod={aod}
              disposition={disposition}
              docketName={docketName}
              docketNumber={docketNumber}
              isVirtual={hearing.isVirtual}
              hearingDayId={hearingDayId}
              readableLocation={readableLocation}
              readableRequestType={readableRequestType}
              regionalOfficeName={regionalOfficeName}
              scheduledFor={scheduledFor}
              veteranFileNumber={veteranFileNumber}
              veteranFirstName={veteranFirstName}
              veteranLastName={veteranLastName}
            />
            <DetailsForm
              hearing={hearing}
              update={updateHearing}
              convertHearing={convertHearing}
              errors={virtualHearingErrors}
              isLegacy={isLegacy}
              openVirtualHearingModal={openVirtualHearingModal}
              readOnly={disabled}
              requestType={readableRequestType}
            />
          </div>
        </AppSegment>
      )}
      <div {...css({ overflow: 'hidden' })}>
        <Button
          name="Cancel"
          linkStyling
          onClick={converting ? cancelConvert : goBack}
          styling={css({ float: 'left', paddingLeft: 0, paddingRight: 0 })}
        >
          Cancel
        </Button>
        <span {...css({ float: 'right' })}>
          <Button
            name="Save"
            disabled={(!formsUpdated || disabled)}
            loading={loading}
            className="usa-button"
            onClick={async () => await submit(editedEmails)}
          >
            {converting ? 'Convert to Virtual Hearing' : 'Save'}
          </Button>
        </span>
      </div>
      <VirtualHearingModal
        open={virtualHearingModalOpen}
        hearing={hearing}
        virtualHearing={hearing?.virtualHearing}
        update={updateHearing}
        submit={submit}
        closeModal={closeVirtualHearingModal}
        reset={() => resetHearing(initialHearing)}
        type={virtualHearingModalType}
        {...editedEmails}
      />
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
  transitionAlert: PropTypes.func
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      onReceiveAlerts,
      onReceiveTransitioningAlert,
      transitionAlert
    },
    dispatch
  );

export default connect(
  null,
  mapDispatchToProps
)(HearingDetails);
