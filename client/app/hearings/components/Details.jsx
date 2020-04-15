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
import { deepDiff, pollVirtualHearingData } from '../utils';
import _ from 'lodash';

import DetailsInputs from './details/DetailsInputs';
import DetailsOverview from './details/DetailsOverview';
import {
  onReceiveAlerts, onReceiveTransitioningAlert, transitionAlert
} from '../../components/common/actions';
import { HearingsFormContext } from '../contexts/HearingsFormContext';
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

const UPDATE_VIRTUAL_HEARING = 'updateVirtualHearing';
const SET_ALL_HEARING_FORMS = 'setAllHearingForms';
const SET_UPDATED = 'setUpdated';

const HearingDetails = (props) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(false);
  const [virtualHearingModalOpen, setVirtualHearingModalOpen] = useState(false);
  const [virtualHearingModalType, setVirtualHearingModalType] = useState(null);
  const [shouldStartPolling, setShouldStartPolling] = useState(null);

  const hearingsFormContext = useContext(HearingsFormContext);
  const hearingsFormDispatch = hearingsFormContext.dispatch;
  const hearingForms = hearingsFormContext.state.hearingForms;
  const formsUpdated = hearingsFormContext.state.updated;

  const getInitialFormData = () => {
    const { hearing } = props;
    const transcription = hearing.transcription || {};
    const virtualHearing = hearing.virtualHearing || {};

    return {
      hearingDetailsForm: {
        bvaPoc: hearing.bvaPoc,
        judgeId: hearing.judgeId ? hearing.judgeId.toString() : null,
        evidenceWindowWaived: hearing.evidenceWindowWaived || false,
        room: hearing.room,
        notes: hearing.notes,
        scheduledForIsPast: hearing.scheduledForIsPast,
        // Transcription Request
        transcriptRequested: hearing.transcriptRequested,
        transcriptSentDate: DateUtil.formatDateStr(hearing.transcriptSentDate, 'YYYY-MM-DD', 'YYYY-MM-DD')
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
        // not used in form
        jobCompleted: virtualHearing.jobCompleted,
        clientHost: virtualHearing.clientHost,
        alias: virtualHearing.alias,
        hostPin: virtualHearing.hostPin,
        guestPin: virtualHearing.guestPin
      }
    };
  };

  useEffect(() => {
    const initialFormData = getInitialFormData();

    hearingsFormDispatch({ type: SET_ALL_HEARING_FORMS, payload: initialFormData });
  }, [props.hearing]);

  const openVirtualHearingModal = ({ type }) => {
    setVirtualHearingModalOpen(true);
    setVirtualHearingModalType(type);
  };

  const closeVirtualHearingModal = () => setVirtualHearingModalOpen(false);

  const resetVirtualHearing = () => {
    const { hearing: { virtualHearing } } = props;

    if (virtualHearing) {
      hearingsFormDispatch({ type: UPDATE_VIRTUAL_HEARING, payload: virtualHearing });
    } else {
      hearingsFormDispatch({ type: UPDATE_VIRTUAL_HEARING, payload: null });
    }
    hearingsFormDispatch({ type: SET_UPDATED, payload: false });

    closeVirtualHearingModal();
  };

  const getEditedEmails = () => {
    const { hearing: { virtualHearing } } = props;

    const { virtualHearingForm } = hearingForms;
    const changes = deepDiff(virtualHearing, virtualHearingForm || {});

    return {
      repEmailEdited: !_.isUndefined(changes.representativeEmail),
      vetEmailEdited: !_.isUndefined(changes.veteranEmail)
    };
  };

  const submit = () => {
    const { saveHearing, setHearing } = props;

    if (!formsUpdated) {
      return;
    }

    // only send updated properties
    const {
      hearingDetailsForm, transcriptionDetailsForm, virtualHearingForm
    } = deepDiff(getInitialFormData(), hearingForms);

    const data = {
      hearing: {
        ...(hearingDetailsForm || {}),
        transcription_attributes: {
          ...(transcriptionDetailsForm || {})
        },
        virtual_hearing_attributes: {
          ...(virtualHearingForm || {})
        }
      }
    };

    setLoading(true);

    return saveHearing(data).then((response) => {
      const hearing = ApiUtil.convertToCamelCase(response.body.data);
      const alerts = response.body?.alerts;

      setLoading(false);
      setError(false);

      // set hearing on DetailsContainer
      setHearing(hearing, () => {
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

  const startPolling = () => {
    return pollVirtualHearingData(props.hearing.externalId, (response) => {
      // response includes jobCompleted, alias, and hostPin
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

  const {
    isVirtual,
    wasVirtual,
    veteranFirstName,
    veteranLastName,
    veteranFileNumber,
    scheduledForIsPast,
    docketName
  } = props.hearing;
  const { disabled } = props;
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
        <DetailsOverview hearing={props.hearing} />
        <div className="cf-help-divider" />
        {virtualHearingModalOpen && <VirtualHearingModal
          hearing={props.hearing}
          virtualHearing={virtualHearingForm}
          update={(values) => hearingsFormDispatch({ type: UPDATE_VIRTUAL_HEARING, payload: values })}
          submit={() => submit().then(closeVirtualHearingModal)}
          closeModal={closeVirtualHearingModal}
          reset={resetVirtualHearing}
          type={virtualHearingModalType}
          {...editedEmails} />}
        <DetailsInputs
          transcription={transcriptionDetailsForm}
          hearing={hearingDetailsForm}
          scheduledForIsPast={scheduledForIsPast}
          virtualHearing={virtualHearingForm}
          isLegacy={isLegacy}
          openVirtualHearingModal={openVirtualHearingModal}
          requestType={props.hearing.readableRequestType}
          readOnly={disabled}
          isVirtual={isVirtual}
          wasVirtual={wasVirtual} />
        <div>
          <a
            className="button-link"
            onClick={props.goBack}
            style={{ float: 'left' }}
          >Cancel</a>
          <span {...css({ float: 'right' })}>
            <Button
              name="Save"
              disabled={!formsUpdated || disabled}
              loading={loading}
              className="usa-button"
              onClick={() => {
                if (editedEmails.repEmailEdited || editedEmails.vetEmailEdited) {
                  openVirtualHearingModal({ type: 'change_email' });
                } else {
                  submit();
                }
              }}
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
