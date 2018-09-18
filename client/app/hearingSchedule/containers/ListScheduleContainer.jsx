import React from 'react';
import { connect } from 'react-redux';
import ListSchedule from '../components/ListSchedule';
import { onViewStartDateChange, onViewEndDateChange, onReceiveHearingSchedule } from '../actions';
import { bindActionCreators } from 'redux';
import { LOGO_COLORS } from '../../constants/AppConstants';
import { formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';

const dateFormatString = 'YYYY-MM-DD';

export class ListScheduleContainer extends React.Component {

  loadHearingSchedule = () => {
    let requestUrl = '/hearings/hearing_day.json';

    if (this.props.startDate && this.props.endDate) {
      requestUrl = `${requestUrl}?start_date=${this.props.startDate}&end_date=${this.props.endDate}`;
    }

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveHearingSchedule(resp.hearings);
      this.props.onViewStartDateChange(formatDateStr(resp.startDate, dateFormatString, dateFormatString));
      this.props.onViewEndDateChange(formatDateStr(resp.endDate, dateFormatString, dateFormatString));
    });
  };

  createHearingPromise = () => Promise.all([
    this.loadHearingSchedule()
  ]);

  render() {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createHearingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: 'Loading the hearing schedule...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the hearing schedule.'
      }}>
      <ListSchedule
        hearingSchedule={this.props.hearingSchedule}
        startDateValue={this.props.startDate}
        startDateChange={this.props.onViewStartDateChange}
        endDateValue={this.props.endDate}
        endDateChange={this.props.onViewEndDateChange}
        onApply={this.createHearingPromise}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  hearingSchedule: state.hearingSchedule,
  startDate: state.viewStartDate,
  endDate: state.viewEndDate
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(ListScheduleContainer);
