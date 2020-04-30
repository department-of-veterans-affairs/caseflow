import React from 'react';
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
  onChangeFormData, onReceiveAlerts, onReceiveTransitioningAlert, transitionAlert
} from '../../components/common/actions';
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

const HEARING_DETAILS_FORM_NAME = 'hearingDetails';
const TRANSCRIPTION_DETAILS_FORM_NAME = 'transcriptionDetails';
const VIRTUAL_HEARING_FORM_NAME = 'virtualHearing';

class HearingDetails extends React.Component {
  constructor(props) {
    super(props);

    const initialFormData = this.getInitialFormData();

    this.state = {
      disabled: this.props.disabled,
      isLegacy: this.props.hearing.docketName !== 'hearing',
      updated: false,
      loading: false,
      success: false,
      error: false,
      virtualHearingErrors: {},
      virtualHearingModalOpen: false,
      virtualHearingModalType: null,
      startPolling: null,
      initialFormData
    };

    this.updateAllFormData(initialFormData);
  }

  openVirtualHearingModal = ({ type }) => this.setState({
    virtualHearingModalOpen: true,
    virtualHearingModalType: type
  })
  closeVirtualHearingModal = () => this.setState({ virtualHearingModalOpen: false })

  getInitialFormData = () => {
    const { hearing } = this.props;
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
        transcriptSentDate: DateUtil.formatDateStr(hearing.transcriptSentDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
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
        guestPin: virtualHearing.guestPin,
        hostLink: virtualHearing.hostLink,
        guestLink: virtualHearing.guestLink
      }
    };
  }

  updateAllFormData = ({ hearingDetailsForm, transcriptionDetailsForm, virtualHearingForm }) => {
    this.props.onChangeFormData(HEARING_DETAILS_FORM_NAME, hearingDetailsForm);
    this.props.onChangeFormData(TRANSCRIPTION_DETAILS_FORM_NAME, transcriptionDetailsForm);
    this.props.onChangeFormData(VIRTUAL_HEARING_FORM_NAME, virtualHearingForm);
  }

  updateHearing = (values) => {
    this.props.onChangeFormData(HEARING_DETAILS_FORM_NAME, values);
    this.setState({ updated: true });
  }

  updateVirtualHearing = (values) => {
    this.props.onChangeFormData(VIRTUAL_HEARING_FORM_NAME, values);

    this.setState({
      updated: !_.isEmpty(deepDiff(values, this.state.initialFormData.virtualHearingForm)),
      virtualHearingErrors: {}
    });
  }

  resetVirtualHearing = () => {
    const { hearing: { virtualHearing } } = this.props;

    if (virtualHearing) {
      // Reset the jobCompleted so that we dont disable the hearings dropdown
      // Addresses issue where frontend overrides backend on cancelling hearing change
      // REMINDER: Refactor to get state from the backend
      this.updateVirtualHearing({
        ...virtualHearing,
        jobCompleted: true,
        requestCancelled: this.state.initialFormData.virtualHearingForm?.requestCancelled
      });
    } else {
      this.updateVirtualHearing(null);
    }

    this.closeVirtualHearingModal();
  }

  getEditedEmails = () => {
    const { hearing: { virtualHearing }, formData: { virtualHearingForm } } = this.props;

    const changes = deepDiff(virtualHearing, virtualHearingForm || {});

    return {
      repEmailEdited: !_.isUndefined(changes.representativeEmail),
      vetEmailEdited: !_.isUndefined(changes.veteranEmail)
    };
  }

  updateTranscription = (values) => {
    this.props.onChangeFormData(TRANSCRIPTION_DETAILS_FORM_NAME, values);
    this.setState({ updated: true });
  }

  handleSave = (editedEmails) => {
    const virtual = this.props.hearing.isVirtual || this.props.hearing.wasVirtual;

    if (
      virtual &&
      (!this.props.formData.virtualHearingForm.representativeEmail ||
      !this.props.formData.virtualHearingForm.veteranEmail)
    ) {
      this.setState({
        loading: false,
        success: false,
        virtualHearingErrors: {
          vetEmail: !this.props.formData.virtualHearingForm.veteranEmail && 'Veteran email is required',
          repEmail: !this.props.formData.virtualHearingForm.representativeEmail && 'Representative email is required'
        }
      });
    } else if (editedEmails.repEmailEdited || editedEmails.vetEmailEdited) {
      this.openVirtualHearingModal({ type: 'change_email' });
    } else {
      this.submit();
    }
  };

  submit = (form = '') => {
    const { hearing: { externalId } } = this.props;
    const { updated } = this.state;

    if (!updated) {
      return;
    }

    const { init, current } = toggleCancelled(this.state.initialFormData, this.props.formData, form);

    // only send updated properties
    const { hearingDetailsForm, transcriptionDetailsForm, virtualHearingForm } = deepDiff(init, current);

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

    this.setState({ loading: true });

    return ApiUtil.patch(`/hearings/${externalId}`, {
      data: ApiUtil.convertToSnakeCase(data)
    }).then((response) => {
      const hearing = ApiUtil.convertToCamelCase(response.body.data);
      const alerts = response.body?.alerts;

      this.setState({
        updated: false,
        loading: false,
        success: true,
        error: false
      });

      // set hearing on DetailsContainer then reset initialFormData
      this.props.setHearing(hearing, () => {
        const initialFormData = this.getInitialFormData();

        this.setState({ initialFormData });

        this.updateAllFormData(initialFormData);

        if (alerts) {
          const {
            hearing: hearingAlerts,
            virtual_hearing: virtualHearingAlerts
          } = alerts;

          if (hearingAlerts) {
            this.props.onReceiveAlerts(hearingAlerts);
          }

          if (!_.isEmpty(virtualHearingAlerts)) {
            this.props.onReceiveTransitioningAlert(virtualHearingAlerts, 'virtualHearing');
            this.setState({ startPolling: true });
          }
        }
      });
    }).
      catch((error) => {
        const code = _.get(error, 'response.body.errors[0].code') || '';

        if (code === 1002) {
          // 1002 is returned with an invalid email. rethrow error, then re-catch it in VirtualHearingModal
          throw error;
        }
        this.setState({
          loading: false,
          error: error.message,
          success: false
        });
      });
  }

  startPolling = () => {
    return pollVirtualHearingData(this.props.hearing.externalId, (response) => {
      // response includes jobCompleted, aliasWithHost, and hostPin
      const resp = ApiUtil.convertToCamelCase(response);

      if (resp.jobCompleted) {
        this.props.onChangeFormData(VIRTUAL_HEARING_FORM_NAME, resp);
        this.props.transitionAlert('virtualHearing');
        this.setState({ startPolling: false });
      }

      // continue polling if return true (opposite of job_completed)
      return !response.job_completed;
    });
  }

  render() {
    const {
      isVirtual,
      wasVirtual,
      veteranFirstName,
      veteranLastName,
      veteranFileNumber,
      scheduledForIsPast
    } = this.props.hearing;

    const { hearingDetailsForm, transcriptionDetailsForm, virtualHearingForm } = this.props.formData;

    const { disabled, error } = this.state;

    const editedEmails = this.getEditedEmails();

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
          <DetailsOverview hearing={this.props.hearing} />
          <div className="cf-help-divider" />
          {this.state.virtualHearingModalOpen && <VirtualHearingModal
            hearing={this.props.hearing}
            virtualHearing={virtualHearingForm}
            update={this.updateVirtualHearing}
            submit={() => this.submit('virtualHearingForm').then(this.closeVirtualHearingModal)}
            closeModal={this.closeVirtualHearingModal}
            reset={this.resetVirtualHearing}
            type={this.state.virtualHearingModalType}
            {...editedEmails} />}
          <DetailsInputs
            errors={this.state.virtualHearingErrors}
            updateTranscription={this.updateTranscription}
            updateHearing={this.updateHearing}
            updateVirtualHearing={this.updateVirtualHearing}
            transcription={transcriptionDetailsForm}
            hearing={hearingDetailsForm}
            scheduledForIsPast={scheduledForIsPast}
            virtualHearing={virtualHearingForm}
            isLegacy={this.state.isLegacy}
            openVirtualHearingModal={this.openVirtualHearingModal}
            requestType={this.props.hearing.readableRequestType}
            readOnly={disabled}
            isVirtual={isVirtual}
            wasVirtual={wasVirtual} />
          <div>
            <a
              className="button-link"
              onClick={this.props.goBack}
              style={{ float: 'left' }}
            >Cancel</a>
            <span {...css({ float: 'right' })}>
              <Button
                name="Save"
                disabled={!this.state.updated || this.state.disabled}
                loading={this.state.loading}
                className="usa-button"
                onClick={() => this.handleSave(editedEmails)}
                styling={css({ float: 'right' })}
              >Save</Button>
            </span>
          </div>
        </div>
        {this.state.startPolling && this.startPolling()}
      </AppSegment>
    );
  }
}

HearingDetails.propTypes = {
  hearing: PropTypes.object.isRequired,
  setHearing: PropTypes.func,
  goBack: PropTypes.func,
  disabled: PropTypes.bool,
  onReceiveAlerts: PropTypes.func,
  onReceiveTransitioningAlert: PropTypes.func,
  transitionAlert: PropTypes.func,
  onChangeFormData: PropTypes.func,
  formData: PropTypes.shape({
    hearingDetailsForm: PropTypes.object,
    transcriptionDetailsForm: PropTypes.object,
    virtualHearingForm: PropTypes.object
  })
};

const mapStateToProps = (state) => ({
  formData: {
    hearingDetailsForm: state.components.forms[HEARING_DETAILS_FORM_NAME],
    transcriptionDetailsForm: state.components.forms[TRANSCRIPTION_DETAILS_FORM_NAME],
    virtualHearingForm: state.components.forms[VIRTUAL_HEARING_FORM_NAME]
  }
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onChangeFormData,
  onReceiveAlerts,
  onReceiveTransitioningAlert,
  transitionAlert
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingDetails);
