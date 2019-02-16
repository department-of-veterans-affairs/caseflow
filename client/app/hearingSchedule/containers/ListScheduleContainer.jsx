import React from 'react';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ListSchedule from '../components/ListSchedule';
import { hearingSchedStyling } from '../components/ListScheduleDateSearch';
import {
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule,
  onSelectedHearingDayChange,
  selectRequestType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onResetDeleteSuccessful,
  onAssignHearingRoom
} from '../actions';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../../components/Alert';
import COPY from '../../../COPY.json';
import { formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import PropTypes from 'prop-types';
import QueueCaseSearchBar from '../../queue/SearchBar';
import HearingDayAddModal from '../components/HearingDayAddModal';
import { onRegionalOfficeChange } from '../../components/common/actions';
import moment from 'moment';

const dateFormatString = 'YYYY-MM-DD';

const actionButtonsStyling = css({
  marginRight: '25px'
});

export class ListScheduleContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      dateRangeKey: `${props.startDate}->${props.endDate}`,
      modalOpen: false,
      showModalAlert: false
    };
  }

  componentDidMount = () => {
    this.props.onSelectedHearingDayChange('');
    this.setState({ showModalAlert: false });
  };

  componentWillUnmount = () => {
    this.props.onResetDeleteSuccessful();
  };

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

  openModal = () => {
    this.setState({ showModalAlert: false,
      modalOpen: true,
      serverError: false,
      noRoomsAvailable: false });
    this.props.onSelectedHearingDayChange('');
    this.props.selectRequestType('');
    this.props.onRegionalOfficeChange('');
    this.props.selectVlj(null);
    this.props.selectHearingCoordinator(null);
    this.props.setNotes('');
    this.props.onAssignHearingRoom(true);
  };

  closeModal = () => {
    this.setState({
      modalOpen: false,
      showModalAlert: true
    });
  };

  cancelModal = () => {
    this.setState({ modalOpen: false });
  };

  getAlertTitle = () => {
    if (this.props.successfulHearingDayDelete) {
      return `You have successfully removed Hearing Day ${formatDateStr(this.props.successfulHearingDayDelete)}`;
    }

    if (['Saturday', 'Sunday'].includes(moment(this.props.selectedHearingDay).format('dddd'))) {
      return `The Hearing day you created for ${formatDateStr(this.props.selectedHearingDay)} is a Saturday or Sunday.`;
    }

    return `You have successfully added Hearing Day ${formatDateStr(this.props.selectedHearingDay)}`;

  };

  getAlertMessage = () => {
    if (this.props.successfulHearingDayDelete) {
      return '';
    }

    if (['Saturday', 'Sunday'].includes(moment(this.props.selectedHearingDay).format('dddd'))) {
      return 'If this was done in error, please remove hearing day from Hearing Schedule.';
    }

    return <p>To add Veterans to this date, click Schedule Veterans</p>;
  };

  getAlertType = () => {
    if (['Saturday', 'Sunday'].includes(moment(this.props.selectedHearingDay).format('dddd'))) {
      return 'warning';
    }

    return 'success';
  };

  showAlert = () => {
    return this.state.showModalAlert;
  };

  render() {
    return (
      <React.Fragment>
        <QueueCaseSearchBar />
        {(this.showAlert() || this.props.successfulHearingDayDelete) &&
        <Alert type={this.getAlertType()} title={this.getAlertTitle()} scrollOnAlert={false}>
          {this.getAlertMessage()}
        </Alert>}
        <AppSegment filledBackground>
          <h1 className="cf-push-left">{COPY.HEARING_SCHEDULE_VIEW_PAGE_HEADER}</h1>
          {this.props.userRoleBuild &&
            <span className="cf-push-right">
              <Link button="secondary" to="/schedule/build">Build Schedule</Link>
            </span>
          }{this.props.userRoleAssign &&
            <span className="cf-push-right"{...actionButtonsStyling} >
              <Link button="primary" to="/schedule/assign">Schedule Veterans</Link>
            </span>
          }
          <div className="cf-help-divider" {...hearingSchedStyling} ></div>
          <ListSchedule
            hearingSchedule={this.props.hearingSchedule}
            onApply={this.createHearingPromise}
            openModal={this.openModal}
            userRoleBuild={this.props.userRoleBuild} />
          {this.state.modalOpen &&
            <HearingDayAddModal
              closeModal={this.closeModal}
              cancelModal={this.cancelModal} />
          }
        </AppSegment>
      </React.Fragment>
    );
  }
}

const mapStateToProps = (state) => ({
  hearingSchedule: state.hearingSchedule.hearingSchedule,
  startDate: state.hearingSchedule.viewStartDate,
  endDate: state.hearingSchedule.viewEndDate,
  selectedHearingDay: state.hearingSchedule.selectedHearingDay,
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  requestType: state.hearingSchedule.requestType,
  vlj: state.hearingSchedule.vlj,
  coordinator: state.hearingSchedule.coordinator,
  notes: state.hearingSchedule.notes,
  roomRequired: state.hearingSchedule.roomRequired,
  successfulHearingDayDelete: state.hearingSchedule.successfulHearingDayDelete
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule,
  onSelectedHearingDayChange,
  selectRequestType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onAssignHearingRoom,
  onRegionalOfficeChange,
  onResetDeleteSuccessful
}, dispatch);

ListScheduleContainer.propTypes = {
  userRoleAssign: PropTypes.bool,
  userRoleBuild: PropTypes.bool
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ListScheduleContainer));
