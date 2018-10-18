import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import DailyDocket from '../components/DailyDocket';
import { LOGO_COLORS } from '../../constants/AppConstants';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ApiUtil from '../../util/ApiUtil';
import { onReceiveDailyDocket } from '../actions';

export class DailyDocketContainer extends React.Component {

  loadHearingDay = () => {
    const requestUrl = `/hearings/hearing_day/${this.props.match.params.hearingDayId}`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveDailyDocket(resp.hearingDay);
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
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  dailyDocket: state.hearingSchedule.dailyDocket
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveDailyDocket
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(DailyDocketContainer);
