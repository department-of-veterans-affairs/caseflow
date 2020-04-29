import React, { useState, useEffect, useContext } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import CopyTextButton from '../../components/CopyTextButton';
import Alert from '../../components/Alert';
import Button from '../../components/Button';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import * as DateUtil from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import { deepDiff, toggleCancelled, pollVirtualHearingData } from '../utils';
import _ from 'lodash';

import DetailsInputs from './details/DetailsInputs';
import DetailsOverview from './details/DetailsOverview';
import {
  onReceiveAlerts, onReceiveTransitioningAlert, transitionAlert
} from '../../components/common/actions';
import {
  HearingsFormContext,
  UPDATE_VIRTUAL_HEARING, SET_ALL_HEARING_FORMS, SET_UPDATED
} from '../contexts/HearingsFormContext';
import UserAlerts from '../../components/UserAlerts';
import VirtualHearingModal from './VirtualHearingModal';

const row = css({
  marginLeft: '-15px',
  marginRight: '-15px',
  '& > *': {
    display: 'inline-block',
    paddingRight: '15px',
    paddingLeft: '15px',
    verticalAlign: 'middle',
    margin: 0
  }
});

const inputFix = css({
  '& .question-label': {
    marginBottom: '2rem !important'
  }
});

const HearingDetails = (props) => {
  const {
    hearing, saveHearing, setHearing, goBack, disabled
  } = props;

  const {
    bvaPoc, judgeId, isVirtual, wasVirtual,
    externalId, veteranFirstName, veteranLastName,
    veteranFileNumber, room, notes, evidenceWindowWaived,
    scheduledForIsPast, docketName, transcriptSentDate,
    readableRequestType
  } = hearing;

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

  const getInitialFormData = () => {
    const transcription = hearing.transcription || {};
    const virtualHearing = hearing.virtualHearing || {};

    return {
      hearingDetailsForm: {
        bvaPoc,
        judgeId: judgeId ? judgeId.toString() : null,
        evidenceWindowWaived: evidenceWindowWaived || false,
        room,
        notes,
        scheduledForIsPast,
        // Transcription Request
        transcriptRequested: hearing.transcriptRequested,
        transcriptSentDate: DateUtil.formatDateStr(transcriptSentDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
        emailEvents: _.values(hearing.emailEvents)
      },
      transcriptionDetailsForm: {
        // Transcription Details
        taskNumber: transcription.taskNumber,
        transcriber: transcription.transcriber,
        sentToTranscriberDate: DateUtil.formatDateStr(transcription.sentToTranscriberDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
        expectedReturnDate: DateUtil.formatDateStr(transcription.expectedReturnDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
        uploadedToVbmsDate: DateUtil.formatDateStr(transcription.uploadedToVbmsDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
        // Transcription Problem
        problemType: transcription.problemType,
        problemNoticeSentDate: DateUtil.formatDateStr(transcription.problemNoticeSentDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
        requestedRemedy: transcription.requestedRemedy
      },
      virtualHearingForm: {
        veteranEmail: virtualHearing.veteranEmail,
        representativeEmail: virtualHearing.representativeEmail,
        status: virtualHearing.status,
        requestCancelled: virtualHearing.requestCancelled,
        // not used in form
        jobCompleted: virtualHearing.jobCompleted,
        clientHost: virtualHearing.clientHost,
        aliasWithHost: virtualHearing.aliasWithHost,
        hostPin: virtualHearing.hostPin,
        guestPin: virtualHearing.guestPin
      }
    };
  };

  const initialFormData = getInitialFormData();

  useEffect(() => {
    hearingsFormDispatch({ type: SET_ALL_HEARING_FORMS, payload: getInitialFormData() });
  }, [props.hearing]);

  const openVirtualHearingModal = ({ type }) => {
    setVirtualHearingModalOpen(true);
    setVirtualHearingModalType(type);
  };

  const updateVirtualHearing = (newVirtualHearingValues) => {
    hearingsFormDispatch({ type: UPDATE_VIRTUAL_HEARING, payload: newVirtualHearingValues });
    hearingsFormDispatch({
      type: SET_UPDATED,
      payload: !_.isEmpty(deepDiff(newVirtualHearingValues, initialFormData.virtualHearingForm))
    });
    setVirtualHearingErrors({});
  };

  const closeVirtualHearingModal = () => setVirtualHearingModalOpen(false);

  const resetVirtualHearing = () => {
    if (hearing.virtualHearing) {
      // Reset the jobCompleted so that we dont disable the hearings dropdown
      // Addresses issue where frontend overrides backend on cancelling hearing change
      // REMINDER: Refactor to get state from the backend
      updateVirtualHearing({
        ...hearing.virtualHearing,
        jobCompleted: true,
        requestCancelled: initialFormData.virtualHearingForm?.requestCancelled
      });
    } else {
      hearingsFormDispatch({ type: UPDATE_VIRTUAL_HEARING, payload: null });
    }

    closeVirtualHearingModal();
  };

  const getEditedEmails = () => {
    const { virtualHearingForm } = hearingForms;
    const changes = deepDiff(hearing.virtualHearing, virtualHearingForm || {});

    return {
      repEmailEdited: !_.isUndefined(changes.representativeEmail),
      vetEmailEdited: !_.isUndefined(changes.veteranEmail)
    };
  };

  const submit = (form = '') => {
    if (!formsUpdated) {
      return;
    }

    const { init, current } = toggleCancelled(initialFormData, hearingForms, form);

    // only send updated properties
    const {
      hearingDetailsForm, transcriptionDetailsForm, virtualHearingForm
    } = deepDiff(init, current);

    const submitData = {
      hearing: {
        ...(hearingDetailsForm || {}),
        transcription_attributes: { ...(transcriptionDetailsForm || {}) },
        virtual_hearing_attributes: { ...(virtualHearingForm || {}) }
      }
    };

    setLoading(true);

    return saveHearing(submitData).
      then((response) => {
        const hearingResp = ApiUtil.convertToCamelCase(response.body.data);
        const alerts = response.body?.alerts;

        setLoading(false);
        setError(false);

        // set hearing on DetailsContainer
        setHearing(hearingResp, () => {
          if (alerts) {
            const {
              hearing: hearingAlerts,
              virtual_hearing: virtualHearingAlerts
            } = alerts;

            if (hearingAlerts) {
              props.onReceiveAlerts(hearingAlerts);
            }

            if (!_.isEmpty(virtualHearingAlerts)) {
              props.onReceiveTransitioningAlert(virtualHearingAlerts, 'virtualHearing');
              setShouldStartPolling(true);
            }
          }
        });
      }).
      catch((respError) => {
        const code = _.get(respError, 'response.body.errors[0].code') || '';

        if (code === 1002) {
          // 1002 is returned with an invalid email. rethrow respError, then re-catch it in VirtualHearingModal
          throw respError;
        }
        setLoading(false);
        setError(respError.message);
      });
  };

  const handleSave = (editedEmails) => {
    const virtual = hearing.isVirtual || hearing.wasVirtual;

    if (
      virtual &&
      (!hearingForms.virtualHearingForm?.representativeEmail || !hearingForms.virtualHearingForm?.veteranEmail)
    ) {
      setLoading(false);
      setVirtualHearingErrors({
        vetEmail: !hearingForms.virtualHearingForm.veteranEmail && 'Veteran email is required',
        repEmail: !hearingForms.virtualHearingForm.representativeEmail && 'Representative email is required'
      });
    } else if (editedEmails.repEmailEdited || editedEmails.vetEmailEdited) {
      openVirtualHearingModal({ type: 'change_email' });
    } else {
      submit();
    }
  };

  const startPolling = () => {
    return pollVirtualHearingData(externalId, (response) => {
      // response includes jobCompleted, aliasWithHost, and hostPin
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

  const { hearingDetailsForm, transcriptionDetailsForm, virtualHearingForm } = hearingForms;
  const isLegacy = docketName !== 'hearing';
  const editedEmails = getEditedEmails();

  return (
    <AppSegment filledBackground>
      <UserAlerts />
      {error &&
        <div {...css({ marginBottom: '4rem' })}>
          <Alert type="error" title="There was an error updating the hearing" />
        </div>
      }
      <div {...inputFix}>
        <div {...row}>
          <h1 className="cf-margin-bottom-0">{`${veteranFirstName} ${veteranLastName}`}</h1>
          <div>Veteran ID: <CopyTextButton text={veteranFileNumber} label="Veteran ID" /></div>
        </div>

        <div className="cf-help-divider" />
        <h2>Hearing Details</h2>
        <DetailsOverview hearing={hearing} />
        <div className="cf-help-divider" />
        {virtualHearingModalOpen && <VirtualHearingModal
          hearing={hearing}
          virtualHearing={virtualHearingForm}
          update={updateVirtualHearing}
          submit={() => submit('virtualHearingForm').then(closeVirtualHearingModal)}
          closeModal={closeVirtualHearingModal}
          reset={resetVirtualHearing}
          type={virtualHearingModalType}
          {...editedEmails} />}
        <DetailsInputs
          errors={virtualHearingErrors}
          transcription={transcriptionDetailsForm}
          hearing={hearingDetailsForm}
          scheduledForIsPast={scheduledForIsPast}
          virtualHearing={virtualHearingForm}
          isLegacy={isLegacy}
          openVirtualHearingModal={openVirtualHearingModal}
          requestType={readableRequestType}
          readOnly={disabled}
          isVirtual={isVirtual}
          wasVirtual={wasVirtual} />
        <div>
          <a
            className="button-link"
            onClick={goBack}
            style={{ float: 'left' }}
          >Cancel</a>
          <span {...css({ float: 'right' })}>
            <Button
              name="Save"
              disabled={!formsUpdated || disabled}
              loading={loading}
              className="usa-button"
              onClick={() => handleSave(editedEmails)}
              styling={css({ float: 'right' })}
            >Save</Button>
          </span>
        </div>
      </div>
      {shouldStartPolling && startPolling()}
    </AppSegment>
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

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveAlerts,
  onReceiveTransitioningAlert,
  transitionAlert
}, dispatch);

export default connect(null, mapDispatchToProps)(HearingDetails);
