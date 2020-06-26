import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React, { useState, useEffect, useContext } from 'react';
import _ from 'lodash';

import { DetailsHeader } from './details/DetailsHeader';
import {
  HearingsFormContext,
  UPDATE_VIRTUAL_HEARING,
  SET_UPDATED
} from '../contexts/HearingsFormContext';
import { deepDiff, pollVirtualHearingData, getChanges } from '../utils';
import { onReceiveAlerts, onReceiveTransitioningAlert, transitionAlert } from '../../components/common/actions';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import DetailsForm from './details/DetailsForm';
import UserAlerts from '../../components/UserAlerts';
import VirtualHearingModal from './VirtualHearingModal';
import { ConvertToVirtual } from './ConvertToVirtual';

const inputFix = css({
  '& .question-label': {
    marginBottom: '2rem !important'
  }
});

const HearingDetails = (props) => {
  // Map the state and dispatch to relevant names
  const { state: hearing, dispatch: updateHearing } = useContext(HearingsFormContext);

  const { saveHearing, setHearing, goBack, disabled } = props;

  const {
    aod,
    appellantIsNotVeteran,
    bvaPoc,
    judgeId,
    isVirtual,
    wasVirtual,
    externalId,
    veteranFirstName,
    veteranLastName,
    veteranFileNumber,
    room,
    notes,
    evidenceWindowWaived,
    scheduledFor,
    scheduledForIsPast,
    docketName,
    docketNumber,
    transcriptSentDate,
    readableRequestType,
    hearingDayId,
    regionalOfficeName,
    readableLocation,
    disposition
  } = hearing;

  const isLegacy = docketName !== 'hearing';

  const [converting, convertHearing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);
  const [virtualHearingErrors, setVirtualHearingErrors] = useState({});
  const [virtualHearingModalOpen, setVirtualHearingModalOpen] = useState(false);
  const [virtualHearingModalType, setVirtualHearingModalType] = useState(null);
  const [shouldStartPolling, setShouldStartPolling] = useState(null);

  const hearingsFormContext = useContext(HearingsFormContext);
  const hearingsFormDispatch = hearingsFormContext.dispatch;
  const hearingForms = hearingsFormContext.state.hearingForms;
  const formsUpdated = hearingsFormContext.state.updated;

  const openVirtualHearingModal = ({ type }) => {
    setVirtualHearingModalOpen(true);
    setVirtualHearingModalType(type);
  };

  const updateVirtualHearing = (newVirtualHearingValues) => {
    hearingsFormDispatch({ type: UPDATE_VIRTUAL_HEARING, payload: newVirtualHearingValues });

    // Calculate the form changes
    const updates = getChanges(hearing, { virtualHearingsForm: newVirtualHearingValues });

    hearingsFormDispatch({
      type: SET_UPDATED,
      payload: !_.isEmpty(updates)
    });
    setVirtualHearingErrors({});
  };

  const closeVirtualHearingModal = () => setVirtualHearingModalOpen(false);

  const resetVirtualHearing = () => {
    // if (hearing.virtualHearing) {
    //   // Reset the jobCompleted so that we dont disable the hearings dropdown
    //   // Addresses issue where frontend overrides backend on cancelling hearing change
    //   // REMINDER: Refactor to get state from the backend
    //   updateVirtualHearing({
    //     ...hearing.virtualHearing,
    //     jobCompleted: true,
    //     requestCancelled: initialFormData.virtualHearing?.requestCancelled
    //   });
    // } else {
    //   hearingsFormDispatch({ type: UPDATE_VIRTUAL_HEARING, payload: null });
    // }
  };

  const getEditedEmails = () => {
    const { virtualHearing } = hearing;
    const changes = deepDiff(hearing.virtualHearing, virtualHearing || {});

    return {
      appellantEmailEdited: !_.isUndefined(changes.appellantEmail),
      representativeEmailEdited: !_.isUndefined(changes.representativeEmail)
    };
  };

  const submit = () => {
    // if (!formsUpdated) {
    //   return;
    // }

    // // only send updated properties
    // const { hearingDetailsForm, transcriptionDetailsForm, virtualHearing } = getChanges(
    //   initialFormData,
    //   hearingForms
    // );

    // const submitData = {
    //   hearing: {
    //     ...(hearingDetailsForm || {}),
    //     transcription_attributes: {
    //       // Always send full transcription details because a new record is created each update
    //       ...(transcriptionDetailsForm ? hearingForms.transcriptionDetailsForm : {})
    //     },
    //     virtual_hearing_attributes: {
    //       ...(virtualHearing || {})
    //     }
    //   }
    // };

    // setLoading(true);

    // return saveHearing(submitData).
    //   then((response) => {
    //     const hearingResp = ApiUtil.convertToCamelCase(response.body.data);
    //     const alerts = response.body?.alerts;

    //     setLoading(false);
    //     setError(false);

    //     // set hearing on DetailsContainer
    //     setHearing(hearingResp, () => {
    //       if (alerts) {
    //         const { hearing: hearingAlerts, virtual_hearing: virtualHearingAlerts } = alerts;

    //         if (hearingAlerts) {
    //           props.onReceiveAlerts(hearingAlerts);
    //         }

    //         if (!_.isEmpty(virtualHearingAlerts)) {
    //           props.onReceiveTransitioningAlert(virtualHearingAlerts, 'virtualHearing');
    //           setShouldStartPolling(true);
    //         }
    //       }
    //     });
    //   }).
    //   catch((respError) => {
    //     const code = _.get(respError, 'response.body.errors[0].code') || '';

    //     if (code === 1002) {
    //       // 1002 is returned with an invalid email. rethrow respError, then re-catch it in VirtualHearingModal
    //       throw respError;
    //     }
    //     setLoading(false);
    //     setError(respError.message);
    //   });
  };

  const handleSave = (editedEmails) => {
    // const virtual = hearing.isVirtual || wasVirtual;

    // if (
    //   virtual &&
    //   (!hearingForms.virtualHearing?.representativeEmail || !hearingForms.virtualHearing?.appellantEmail)
    // ) {
    //   setLoading(true);
    //   setVirtualHearingErrors({
    //     appellantEmail: !hearingForms.virtualHearing.appellantEmail && 'Appellant email is required',
    //     representativeEmail: !hearingForms.virtualHearing.representativeEmail && 'Representative email is required'
    //   });
    // } else if (editedEmails.representativeEmailEdited || editedEmails.appellantEmailEdited) {
    //   openVirtualHearingModal({ type: 'change_email' });
    // } else {
    //   submit();
    // }
  };

  const startPolling = () => {
    return pollVirtualHearingData(externalId, (response) => {
      // response includes jobCompleted, aliasWithHost, guestPin, hostPin,
      // guestLink, and hostLink
      const resp = ApiUtil.convertToCamelCase(response);

      if (resp.jobCompleted) {
        setShouldStartPolling(false);
        hearingsFormDispatch({ type: UPDATE_VIRTUAL_HEARING, payload: resp });
        hearingsFormDispatch({ type: SET_UPDATED, payload: false });
        props.transitionAlert('virtualHearing');
      }

      // continue polling if return true (opposite of job_completed)
      return !response.job_completed;
    });
  };

  // const editedEmails = getEditedEmails();

  const cancelConvert = () => {
    convertHearing(false);

    // Focus the top of the page
    window.scrollTo(0, 0);
  };

  return (
    <React.Fragment>
      <UserAlerts />
      {error && (
        <div>
          <Alert type="error" title="There was an error updating the hearing" />
        </div>
      )}
      {converting ? (
        <ConvertToVirtual hearing={hearing} scheduledFor={scheduledFor} />
      ) : (
        <AppSegment filledBackground>
          <div {...inputFix}>
            <DetailsHeader
              aod={aod}
              disposition={disposition}
              docketName={docketName}
              docketNumber={docketNumber}
              isVirtual={isVirtual}
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
              updateHearing={updateHearing}
              convertHearing={convertHearing}
              errors={virtualHearingErrors}
              isLegacy={isLegacy}
              isVirtual={isVirtual}
              openVirtualHearingModal={openVirtualHearingModal}
              readOnly={disabled}
              requestType={readableRequestType}
              updateVirtualHearing={updateVirtualHearing}
              wasVirtual={wasVirtual}
            />
          </div>
          {shouldStartPolling && startPolling()}
          {virtualHearingModalOpen && (
            <VirtualHearingModal
              hearing={hearing}
              virtualHearing={hearingForms?.virtualHearing}
              update={updateVirtualHearing}
              submit={submit}
              closeModal={closeVirtualHearingModal}
              reset={resetVirtualHearing}
              type={virtualHearingModalType}
              // {...editedEmails}
            />
          )}
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
            disabled={!converting && (!formsUpdated || disabled)}
            loading={loading}
            className="usa-button"
            onClick={() => handleSave()}
          >
            {converting ? 'Convert to Virtual Hearing' : 'Save'}
          </Button>
        </span>
      </div>
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
