import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
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
  onHearingTimeUpdate
} from '../actions';

export class DailyDocketContainer extends React.Component {

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
      date: hearing.editedDate ? hearing.editedDate : null,
      time: hearing.editedTime ? hearing.editedTime : null
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

  createHearingPromise = () => Promise.all([this.loadHearingDay()]);

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
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  dailyDocket: state.hearingSchedule.dailyDocket,
  hearings: state.hearingSchedule.hearings,
  hearingDayOptions: state.hearingSchedule.hearingDayOptions,
  saveSuccessful: state.hearingSchedule.saveSuccessful
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveDailyDocket,
  onReceiveSavedHearing,
  onResetSaveSuccessful,
  onCancelHearingUpdate,
  onHearingNotesUpdate,
  onHearingDispositionUpdate,
  onHearingDateUpdate,
  onHearingTimeUpdate
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DailyDocketContainer);
