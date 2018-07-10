import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { onReceiveHearingSchedule } from '../actions';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../../constants/AppConstants';

class LoadingScreen extends React.PureComponent {
  loadHearingSchedule = () => {
    var requestUrl = '/hearings/hearing_day.json';
    if (this.props.viewStartDate && this.props.viewEndDate)
      requestUrl=`${requestUrl}?start_date=${this.props.viewStartDate},end_date=${this.props.viewEndDate}`

    console.log("*** request url: ", requestUrl);

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));
      const hearingDays = _.keyBy(resp.hearings, 'id');

      this.props.onReceiveHearingSchedule(hearingDays);
    });
  };

  createHearingPromise = () => Promise.all([
    this.loadHearingSchedule()
  ]);

  render = () => {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createHearingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: 'Loading the hearing schedule...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the hearing schedule.'
      }}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  viewStartDate: state.viewStartDate,
  viewEndDate: state.viewEndDate
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveHearingSchedule
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(LoadingScreen);
