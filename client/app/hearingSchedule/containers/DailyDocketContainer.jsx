import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import moment from 'moment';
import DailyDocket from '../components/DailyDocket';
import { LOGO_COLORS } from '../../constants/AppConstants';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ApiUtil from '../../util/ApiUtil';
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
  onReceiveCoordinators
} from '../actions';
import HearingDayEditModal from "../components/HearingDayEditModal";
import Alert from "../../components/Alert";

export class DailyDocketContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      modalOpen: false,
      showModalAlert: false
    };
  }

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

  formatHearing = (hearing) => {
    return {
      disposition: hearing.editedDisposition ? hearing.editedDisposition : hearing.disposition,
      notes: hearing.editedNotes ? hearing.editedNotes : hearing.notes,
      master_record_updated: hearing.editedDate ? hearing.editedDate : null,
      date: hearing.editedTime ? moment(hearing.date).set({
        // eslint-disable-next-line id-length
        h: hearing.editedTime.split(':')[0],
        // eslint-disable-next-line id-length
        m: hearing.editedTime.split(':')[1]

      }) : hearing.date
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

      let activeJudges = [];

      _.forEach(resp.judges, (value, key) => {
        activeJudges.push({
          label: value.fullName,
          value: value.cssId
        });
      });

      this.props.onReceiveJudges(_.orderBy(activeJudges, (judge) => judge.label, 'asc'));
    })

  };

  loadActiveCoordinators = () => {
    let requestUrl = '/users?role=Hearing';

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      let activeCoordinators = [];

      _.forEach(resp.coordinators, (value, key) => {
        activeCoordinators.push({
          label: value.fullName,
          value: value.cssId
        });
      });

      this.props.onReceiveCoordinators(_.orderBy(activeCoordinators, (coordinator) => coordinator.label, 'asc'));
    })

  };

  createHearingPromise = () => Promise.all([
    this.loadHearingDay(),
    this.loadActiveJudges(),
    this.loadActiveCoordinators()
  ]);

  openModal = () => {
    this.setState({showModalAlert: false});
    this.setState({modalOpen: true});

    this.props.selectHearingRoom(this.props.dailyDocket.roomInfo);
    this.props.selectVlj(this.props.dailyDocket.judgeId);
    this.props.selectHearingCoordinator(this.props.dailyDocket.bvaPoc);
    this.props.setNotes(this.props.dailyDocket.notes);
    this.props.onHearingDayModified(false);
  }

  closeModal = () => {
    this.setState({modalOpen: false});
    this.setState({showModalAlert: true})

    if (this.props.hearingDayModified) {
      let data = {hearing_key: this.props.dailyDocket.id}

      if (this.props.hearingRoom) {
        data["room_info"] = this.props.hearingRoom.value;
      }

      if (this.props.vlj) {
        data["judge_id"] = this.props.vlj.value;
      }

      if (this.props.coordinator) {
        data["bva_poc"] = this.props.coordinator.label;
      }

      if (this.props.notes) {
        data["notes"] = this.props.notes;
      }

      ApiUtil.put(`/hearings/${this.props.dailyDocket.id}/hearing_day`, {data: data}).then((response) => {
        const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

        console.log("updated hearing: ", resp);
      });
    }
  }

  cancelModal = () => {
    this.setState({modalOpen: false})
  }

  getAlertTitle = () => {
    return 'You have successfully completed this action'
  };

  getAlertMessage = () => {
    return <p>You can view your new updates, listed below</p>;
  };

  showAlert = () => {
    return this.state.showModalAlert;
  }

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
      {this.showAlert() && <Alert type="success" title={this.getAlertTitle()} scrollOnAlert={false}>
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
  hearingDayModified: state.hearingSchedule.hearingDayModified
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
  onReceiveCoordinators
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DailyDocketContainer);
