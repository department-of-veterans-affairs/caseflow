import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';
import moment from 'moment';
import DailyDocket from '../components/DailyDocket';
import { LOGO_COLORS } from '../../constants/AppConstants';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ApiUtil from '../../util/ApiUtil';
import { getTimeWithoutTimeZone } from '../../util/DateUtil';
import {
  onReceiveDailyDocket,
  onReceiveSavedHearing,
  onResetSaveSuccessful,
  onCancelHearingUpdate,
  onHearingNotesUpdate,
  onHearingDispositionUpdate,
  onHearingDateUpdate,
  onTranscriptRequestedUpdate,
  onHearingTimeUpdate,
  onHearingLocationUpdate,
  onHearingRegionalOfficeUpdate,
  selectHearingRoom,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onHearingDayModified,
  onClickRemoveHearingDay,
  onCancelRemoveHearingDay,
  onSuccessfulHearingDayDelete,
  onDisplayLockModal,
  onCancelDisplayLockModal,
  onUpdateLock,
  onResetLockSuccessMessage,
  handleDailyDocketServerError,
  onResetDailyDocketAfterError,
  handleLockHearingServerError,
  onResetLockHearingAfterError,
  onInvalidForm
} from '../actions';
import HearingDayEditModal from '../components/HearingDayEditModal';
import Alert from '../../components/Alert';
import { getAssignHearingTime } from '../components/modalForms/HearingTime';

export class DailyDocketContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      modalOpen: false,
      showModalAlert: false,
      serverError: false
    };
  }

  componentDidUpdate = (prevProps) => {
    if (!((_.isNil(prevProps.saveSuccessful) && this.props.saveSuccessful) || _.isNil(this.props.saveSuccessful))) {
      this.props.onResetSaveSuccessful();
    }
    if (!((_.isNil(prevProps.displayLockSuccessMessage) && this.props.displayLockSuccessMessage) ||
        _.isNil(this.props.displayLockSuccessMessage))) {
      this.props.onResetLockSuccessMessage();
    }
    if (!((_.isNil(prevProps.dailyDocketServerError) && this.props.dailyDocketServerError) ||
      _.isNil(this.props.dailyDocketServerError))) {
      this.props.onResetDailyDocketAfterError();
    }
    if (!((_.isNil(prevProps.onErrorHearingDayLock) && this.props.onErrorHearingDayLock) ||
      _.isNil(this.props.onErrorHearingDayLock))) {
      this.props.onResetLockHearingAfterError();
    }
  };

  componentWillUnmount = () => {
    this.props.onResetSaveSuccessful();
    this.props.onCancelRemoveHearingDay();
    this.props.onResetDailyDocketAfterError();
    this.props.onResetLockHearingAfterError();
  };

  loadHearingDay = () => {
    const requestUrl = `/hearings/hearing_day/${this.props.match.params.hearingDayId}`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      const hearings = _.keyBy(resp.hearingDay.hearings, 'id');
      const dailyDocket = _.omit(resp.hearingDay, ['hearings']);

      this.props.onReceiveDailyDocket(dailyDocket, hearings);
    });
  };

  getHearingDay = (hearing) => {
    if (hearing.editedDate) {
      return hearing.editedDate;
    }

    return {
      timezone: hearing.requestType === 'Central' ? 'America/New_York' : hearing.regionalOfficeTimezone,
      scheduledFor: hearing.scheduledFor
    };
  }

  getTimezoneOffsetScheduledTimeObject = (hearing) => {
    const hearingTime = this.getScheduledTime(hearing);
    const hearingDay = this.getHearingDay(hearing);

    return getAssignHearingTime(hearingTime, hearingDay);
  }

  getScheduledTime = (hearing) => {
    if (hearing.editedTime) {
      return hearing.editedTime;
    }

    const timezone = this.getHearingDay(hearing).timezone;

    return getTimeWithoutTimeZone(hearing.scheduledFor, timezone);
  }

  getScheduledFor = (hearing) => {
    if (hearing.editedTime) {
      const scheduledTimeObj = this.getTimezoneOffsetScheduledTimeObject(hearing);

      return moment(hearing.scheduledFor).set(scheduledTimeObj).
        format();
    }

    return hearing.scheduledFor;
  };

  formatHearing = (hearing) => {
    return {
      disposition: hearing.editedDisposition ? hearing.editedDisposition : hearing.disposition,
      transcript_requested: _.isUndefined(hearing.editedTranscriptRequested) ?
        hearing.transcriptRequested : hearing.editedTranscriptRequested,
      notes: _.isUndefined(hearing.editedNotes) ? hearing.notes : hearing.editedNotes,
      hearing_location_attributes: (hearing.editedLocation && !hearing.editedDate) ?
        ApiUtil.convertToSnakeCase(hearing.editedLocation) : null,
      scheduled_time: this.getScheduledTime(hearing),
      scheduled_for: this.getScheduledFor(hearing)
    };
  };

  saveHearing = (hearing) => {
    ApiUtil.patch(`/hearings/${hearing.externalId}`, { data: {
      hearing: this.formatHearing(hearing)
    } }).
      then((response) => {
        const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

        this.props.onReceiveSavedHearing(resp);
      }, (err) => {
        this.props.handleDailyDocketServerError(err);
      });
  };

  updateLockHearingDay = (lock) => () => {
    ApiUtil.patch(`/hearings/hearing_day/${this.props.dailyDocket.id}`, { data: { lock } }).
      then(() => {
        this.props.onUpdateLock(lock);
      }, (err) => {
        this.props.handleLockHearingServerError(err);
      });
  };

  deleteHearingDay = () => {
    ApiUtil.delete(`/hearings/hearing_day/${this.props.dailyDocket.id}`).
      then(() => {
        this.props.onSuccessfulHearingDayDelete(this.props.dailyDocket.scheduledFor);
        this.props.history.push('/schedule');
      }, (err) => {
        this.props.handleDailyDocketServerError(err);
      });
  };

  createHearingPromise = () => Promise.all([
    this.loadHearingDay()
  ]);

  openModal = () => {
    this.setState({ showModalAlert: false,
      modalOpen: true });
  };

  closeModal = () => {
    this.setState({ modalOpen: false });

    if (this.props.hearingDayModified) {
      this.setState({ showModalAlert: true });

      let data = { id: this.props.dailyDocket.id };

      if (this.props.hearingRoom) {
        data.room = this.props.hearingRoom.value;
      }

      if (this.props.vlj) {
        data.judge_id = this.props.vlj.value;
      }

      if (this.props.coordinator) {
        data.bva_poc = this.props.coordinator.value;
      }

      if (this.props.notes) {
        data.notes = this.props.notes;
      }

      ApiUtil.put(`/hearings/hearing_day/${this.props.dailyDocket.id}`, { data }).
        then((response) => {
          const editedHearingDay = ApiUtil.convertToCamelCase(JSON.parse(response.text));

          editedHearingDay.requestType = this.props.dailyDocket.requestType;

          this.props.onReceiveDailyDocket(editedHearingDay, this.props.hearings);
        }, () => {
          this.setState({ serverError: true });
        });
    }
  };

  cancelModal = () => {
    this.setState({ modalOpen: false });
  };

  getAlertTitle = () => {
    if (this.state.serverError) {
      return 'An Error Occurred';
    }

    return 'You have successfully completed this action';
  };

  getAlertMessage = () => {
    if (this.state.serverError) {
      return 'You are unable to complete this action.';
    }

    return <p>You can view your new updates, listed below</p>;
  };

  getAlertType = () => {
    if (this.state.serverError) {
      return 'error';
    }

    return 'success';
  };

  showAlert = () => {
    return this.state.showModalAlert;
  };

  render() {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createHearingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: 'Loading the daily docket...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the daily docket.'
      }}>
      {this.showAlert() && <Alert type={this.getAlertType()} title={this.getAlertTitle()} scrollOnAlert={false}>
        {this.getAlertMessage()}
      </Alert>}
      <DailyDocket
        dailyDocket={this.props.dailyDocket}
        hearings={this.props.hearings}
        onHearingNotesUpdate={this.props.onHearingNotesUpdate}
        onHearingDispositionUpdate={this.props.onHearingDispositionUpdate}
        onHearingDateUpdate={this.props.onHearingDateUpdate}
        onHearingTimeUpdate={this.props.onHearingTimeUpdate}
        onTranscriptRequestedUpdate={this.props.onTranscriptRequestedUpdate}
        onHearingLocationUpdate={this.props.onHearingLocationUpdate}
        onHearingRegionalOfficeUpdate={this.props.onHearingRegionalOfficeUpdate}
        saveHearing={this.saveHearing}
        saveSuccessful={this.props.saveSuccessful}
        onResetSaveSuccessful={this.props.onResetSaveSuccessful}
        onCancelHearingUpdate={this.props.onCancelHearingUpdate}
        openModal={this.openModal}
        onClickRemoveHearingDay={this.props.onClickRemoveHearingDay}
        displayRemoveHearingDayModal={this.props.displayRemoveHearingDayModal}
        onCancelRemoveHearingDay={this.props.onCancelRemoveHearingDay}
        deleteHearingDay={this.deleteHearingDay}
        onDisplayLockModal={this.props.onDisplayLockModal}
        onCancelDisplayLockModal={this.props.onCancelDisplayLockModal}
        displayLockModal={this.props.displayLockModal}
        updateLockHearingDay={this.updateLockHearingDay}
        displayLockSuccessMessage={this.props.displayLockSuccessMessage}
        onResetLockSuccessMessage={this.props.onResetLockSuccessMessage}
        userRoleBuild={this.props.userRoleBuild}
        userRoleAssign={this.props.userRoleAssign}
        userRoleView={this.props.userRoleView}
        userRoleVso={this.props.userRoleVso}
        dailyDocketServerError={this.props.dailyDocketServerError}
        onResetDailyDocketAfterError={this.props.onResetDailyDocketAfterError}
        notes={this.props.notes}
        onErrorHearingDayLock={this.props.onErrorHearingDayLock}
        onResetLockHearingAfterError={this.props.onResetLockHearingAfterError}
        onInvalidForm={this.props.onInvalidForm}
      />
      {this.state.modalOpen &&
      <HearingDayEditModal
        closeModal={this.closeModal}
        cancelModal={this.cancelModal} />
      }
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  dailyDocket: state.hearingSchedule.dailyDocket,
  hearings: state.hearingSchedule.hearings,
  saveSuccessful: state.hearingSchedule.saveSuccessful,
  vlj: state.hearingSchedule.vlj,
  coordinator: state.hearingSchedule.coordinator,
  hearingRoom: state.hearingSchedule.hearingRoom,
  notes: state.hearingSchedule.notes,
  hearingDayModified: state.hearingSchedule.hearingDayModified,
  displayRemoveHearingDayModal: state.hearingSchedule.displayRemoveHearingDayModal,
  displayLockModal: state.hearingSchedule.displayLockModal,
  displayLockSuccessMessage: state.hearingSchedule.displayLockSuccessMessage,
  dailyDocketServerError: state.hearingSchedule.dailyDocketServerError,
  onErrorHearingDayLock: state.hearingSchedule.onErrorHearingDayLock
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveDailyDocket,
  onReceiveSavedHearing,
  onResetSaveSuccessful,
  onCancelHearingUpdate,
  onHearingNotesUpdate,
  onHearingDispositionUpdate,
  onHearingDateUpdate,
  onHearingTimeUpdate,
  onTranscriptRequestedUpdate,
  onHearingLocationUpdate,
  onHearingRegionalOfficeUpdate,
  onInvalidForm,
  selectHearingRoom,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onHearingDayModified,
  onClickRemoveHearingDay,
  onCancelRemoveHearingDay,
  onSuccessfulHearingDayDelete,
  onDisplayLockModal,
  onCancelDisplayLockModal,
  onUpdateLock,
  onResetLockSuccessMessage,
  handleDailyDocketServerError,
  onResetDailyDocketAfterError,
  handleLockHearingServerError,
  onResetLockHearingAfterError
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(DailyDocketContainer));
