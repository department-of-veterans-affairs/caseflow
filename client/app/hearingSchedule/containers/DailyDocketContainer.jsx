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
  onHearingNotesUpdate,
  onHearingDispositionUpdate
} from '../actions';

export class DailyDocketContainer extends React.Component {

  loadHearingDay = () => {
    const requestUrl = `/hearings/hearing_day/${this.props.match.params.hearingDayId}`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      const hearings = _.keyBy(resp.hearingDay.hearings, 'id');
      const dailyDocket = _.omit(resp.hearingDay, ['hearings']);

      this.props.onReceiveDailyDocket(dailyDocket, hearings);
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
        onHearingNotesUpdate={this.props.onHearingNotesUpdate}
        onHearingDispositionUpdate={this.props.onHearingDispositionUpdate}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  dailyDocket: state.hearingSchedule.dailyDocket,
  hearings: state.hearingSchedule.hearings
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveDailyDocket,
  onHearingNotesUpdate,
  onHearingDispositionUpdate
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DailyDocketContainer);
