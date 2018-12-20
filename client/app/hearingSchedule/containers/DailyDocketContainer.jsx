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
import { namePartToSortBy } from '../utils';
import {
  onReceiveDailyDocket,
  onReceiveSavedHearing,
  onResetSaveSuccessful,
  onCancelHearingUpdate,
  onHearingNotesUpdate,
  onHearingDispositionUpdate,
  onHearingDateUpdate,
  onHearingTimeUpdate,
  selectHearingRoom,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onHearingDayModified,
  onReceiveJudges,
  onReceiveCoordinators,
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
} from '../actions';
import HearingDayEditModal from '../components/HearingDayEditModal';
import Alert from '../../components/Alert';

const emptyValueEntry = {
  label: '',
  value: ''
};

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
      const hearingDayOptions = _.keyBy(resp.hearingDay.hearingDayOptions, 'id');
      const dailyDocket = _.omit(resp.hearingDay, ['hearings', 'hearingDayOptions']);

      this.props.onReceiveDailyDocket(dailyDocket, hearings, hearingDayOptions);
    });
  };

  getTime = (hearing) => {
    if (hearing.editedTime) {
      return {
        // eslint-disable-next-line id-length
        h: hearing.editedTime.split(':')[0],
        // eslint-disable-next-line id-length
        m: hearing.editedTime.split(':')[1],
        offset: moment.tz('America/New_York').format('Z')
      };
    }
    const timeObject = moment(hearing.date);

    return {
      // eslint-disable-next-line id-length
      h: timeObject.hours(),
      // eslint-disable-next-line id-length
      m: timeObject.minutes(),
      offset: timeObject.format('Z')
    };

  }

  formatHearing = (hearing) => {
    const time = this.getTime(hearing);

    return {
      disposition: hearing.editedDisposition ? hearing.editedDisposition : hearing.disposition,
      notes: hearing.editedNotes ? hearing.editedNotes : hearing.notes,
      master_record_updated: hearing.editedDate ? { id: hearing.editedDate,
        time } : null,
      date: hearing.editedTime ? moment(hearing.date).set(time) : hearing.date
    };
  };

  saveHearing = (hearing) => {
    const formattedHearing = this.formatHearing(hearing);

    ApiUtil.patch(`/hearings/${hearing.id}`, { data: { hearing: formattedHearing } }).
      then((response) => {
        const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

        this.props.onReceiveSavedHearing(resp);
      });
  };

  loadActiveJudges = () => {
    let requestUrl = '/users?role=Judge';

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      const sortedJudges = _.sortBy(resp.judges, (judge) => namePartToSortBy(judge.fullName), 'asc');

      let activeJudges = [];

      _.forEach(sortedJudges, (value) => {
        activeJudges.push({
          label: value.fullName,
          value: value.id
        });
      });

      activeJudges.unshift(emptyValueEntry);
      this.props.onReceiveJudges(activeJudges);
    });

  };

  loadActiveCoordinators = () => {
    let requestUrl = '/users?role=HearingCoordinator';

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      let activeCoordinators = [];

      _.forEach(resp.coordinators, (value) => {
        activeCoordinators.push({
          label: value.fullName,
          value: value.cssId
        });
      });

      activeCoordinators = _.orderBy(activeCoordinators, (coordinator) => coordinator.label, 'asc');
      activeCoordinators.unshift(emptyValueEntry);
      this.props.onReceiveCoordinators(activeCoordinators);
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
        this.props.onSuccessfulHearingDayDelete(this.props.dailyDocket.hearingDate);
        this.props.history.push('/schedule');
      }, (err) => {
        this.props.handleDailyDocketServerError(err);
      });
  };

  createHearingPromise = () => Promise.all([
    this.loadHearingDay(),
    this.loadActiveJudges(),
    this.loadActiveCoordinators()
  ]);

  openModal = () => {
    this.setState({ showModalAlert: false });
    this.setState({ modalOpen: true });

    // find labels in options before passing values to modal
    const coordinator = _.find(this.props.activeCoordinators, { label: this.props.dailyDocket.bvaPoc });

    this.props.selectVlj(this.props.dailyDocket.judgeId);
    this.props.selectHearingCoordinator(coordinator);
    this.props.setNotes(this.props.dailyDocket.notes);
    this.props.onHearingDayModified(false);
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
        data.bva_poc = this.props.coordinator.label;
      }

      if (this.props.notes) {
        data.notes = this.props.notes;
      }

      ApiUtil.put(`/hearings/hearing_day/${this.props.dailyDocket.id}`, { data }).
        then((response) => {
          const editedHearingDay = ApiUtil.convertToCamelCase(JSON.parse(response.text));

          editedHearingDay.hearingType = this.props.dailyDocket.hearingType;

          this.props.onReceiveDailyDocket(editedHearingDay, this.props.hearings, this.props.hearingDayOptions);
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
        hearingDayOptions={this.props.hearingDayOptions}
        onHearingNotesUpdate={this.props.onHearingNotesUpdate}
        onHearingDispositionUpdate={this.props.onHearingDispositionUpdate}
        onHearingDateUpdate={this.props.onHearingDateUpdate}
        onHearingTimeUpdate={this.props.onHearingTimeUpdate}
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
        dailyDocketServerError={this.props.dailyDocketServerError}
        onResetDailyDocketAfterError={this.props.onResetDailyDocketAfterError}
        notes={this.props.notes}
        onErrorHearingDayLock={this.props.onErrorHearingDayLock}
        onResetLockHearingAfterError={this.props.onResetLockHearingAfterError}
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
  hearingDayOptions: state.hearingSchedule.hearingDayOptions,
  saveSuccessful: state.hearingSchedule.saveSuccessful,
  vlj: state.hearingSchedule.vlj,
  coordinator: state.hearingSchedule.coordinator,
  hearingRoom: state.hearingSchedule.hearingRoom,
  notes: state.hearingSchedule.notes,
  hearingDayModified: state.hearingSchedule.hearingDayModified,
  activeCoordinators: state.hearingSchedule.activeCoordinators,
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
  selectHearingRoom,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onHearingDayModified,
  onReceiveJudges,
  onReceiveCoordinators,
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
