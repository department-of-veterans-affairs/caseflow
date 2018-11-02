import React from 'react';
import { connect } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ListSchedule from '../components/ListSchedule';
import ListScheduleDateSearch, { hearingSchedStyling } from '../components/ListScheduleDateSearch';
import { onViewStartDateChange, onViewEndDateChange, onReceiveHearingSchedule } from '../actions';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { CSVLink } from 'react-csv';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY.json';
import { formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import PropTypes from 'prop-types';
import QueueCaseSearchBar from '../../queue/SearchBar';

const dateFormatString = 'YYYY-MM-DD';

const actionButtonsStyling = css({
  marginRight: '25px'
});

export class ListScheduleContainer extends React.Component {

  constructor(props){
    super(props);
    this.state = {
      dateRangeKey: `${props.startDate}->${props.endDate}`
    }
  }

  // forces remount of LoadingDataDisplay
  setDateRangeKey = () => {
    this.setState({ dateRangeKey: `${this.props.startDate}->${this.props.endDate}` });
    console.log(this.props.endDate);
  }

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
    return (
      <AppSegment filledBackground>
        <h1 className="cf-push-left">{COPY.HEARING_SCHEDULE_VIEW_PAGE_HEADER}</h1>
        {this.props.userRoleBuild &&
          <span className="cf-push-right">
            <Link button="secondary" to="/schedule/build">Build schedule</Link>
          </span>
        }{this.props.userRoleAssign &&
          <span className="cf-push-right"{...actionButtonsStyling} >
            <Link button="primary" to="/schedule/assign">Schedule Veterans</Link>
          </span>
        }
        <div className="cf-help-divider" {...hearingSchedStyling} ></div>
        <ListScheduleDateSearch
          startDateValue={this.props.startDate}
          startDateChange={this.props.onViewStartDateChange}
          endDateValue={this.props.endDate}
          endDateChange={this.props.onViewEndDateChange}
          onApply={this.setDateRangeKey} />
        <LoadingDataDisplay
          createLoadPromise={this.createHearingPromise}
          key={this.state.dateRangeKey}
          loadingComponentProps={{
            spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
            message: 'Loading the hearing schedule...'
          }}
          failStatusMessageProps={{
            title: 'Unable to load the hearing schedule.'
          }}>
            {/*<QueueCaseSearchBar />*/}
            <ListSchedule
              hearingSchedule={this.props.hearingSchedule}
              userRoleAssign={this.props.userRoleAssign}
              userRoleBuild={this.props.userRoleBuild}
              onApply={this.createHearingPromise} />
        </LoadingDataDisplay>
    </AppSegment>
    );
  }
}

const mapStateToProps = (state) => ({
  hearingSchedule: state.hearingSchedule.hearingSchedule,
  startDate: state.hearingSchedule.viewStartDate,
  endDate: state.hearingSchedule.viewEndDate
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule
}, dispatch);

ListScheduleContainer.propTypes = {
  userRoleAssign: PropTypes.bool,
  userRoleBuild: PropTypes.bool
};

export default connect(mapStateToProps, mapDispatchToProps)(ListScheduleContainer);
