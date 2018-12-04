import React from 'react';
import { withRouter } from "react-router-dom";
import { connect } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ListSchedule from '../components/ListSchedule';
import { hearingSchedStyling } from '../components/ListScheduleDateSearch';
import {
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule,
  onSelectedHearingDayChange,
  selectHearingType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onReceiveJudges,
  onReceiveCoordinators
} from '../actions';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';
import { formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import PropTypes from 'prop-types';
import QueueCaseSearchBar from '../../queue/SearchBar';
import Alert from "../../components/Alert";
import HearingDayAddModal from '../components/HearingDayAddModal'
import _ from "lodash";

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
    this.setState({showModalAlert: false})
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

      console.log("coordinators from user:", resp);
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
    this.loadHearingSchedule(),
    this.loadActiveJudges(),
    this.loadActiveCoordinators()
  ]);

  openModal = () => {
    this.setState({showModalAlert: false});
    this.setState({modalOpen: true});
    this.props.onSelectedHearingDayChange('');
    this.props.selectHearingType('');
    this.props.selectVlj('');
    this.props.selectHearingCoordinator('');
    this.props.setNotes('');
  }

  closeModal = () => {
    this.setState({modalOpen: false});
    this.setState({showModalAlert: true});

    let data = {
      hearing_type: this.props.hearingType.value,
      hearing_date: this.props.selectedHearingDay,
      room_info: "1",
      judge_id: this.props.vlj.value,
      notes: this.props.notes
    };

    if (this.props.selectedRegionalOffice && this.props.selectedRegionalOffice.value !== '') {
      data["regional_office"] = this.props.selectedRegionalOffice.value
    }

    ApiUtil.post('/hearings/hearing_day.json', {data: data})
      .then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      console.log("added hearing day result: ", resp);
    });
  }

  cancelModal = () => {
    this.setState({modalOpen: false})
  }

  getAlertTitle = () => {
    return `You have successfully added Hearing Day ${formatDateStr(this.props.selectedHearingDay)} `
  };

  getAlertMessage = () => {
    return <p>To add Veterans to this date, click Schedule Veterans</p>;
  };

  showAlert = () => {
    return this.state.showModalAlert;
  }

  render() {
    return (
      <React.Fragment>
        <QueueCaseSearchBar />
        {this.showAlert() && <Alert type="success" title={this.getAlertTitle()} scrollOnAlert={false}>
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
            openModal={this.openModal} />
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
  hearingType: state.hearingSchedule.hearingType,
  vlj: state.hearingSchedule.vlj,
  coordinator: state.hearingSchedule.coordinator,
  notes: state.hearingSchedule.notes,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule,
  onSelectedHearingDayChange,
  selectHearingType,
  selectVlj,
  selectHearingCoordinator,
  setNotes,
  onReceiveJudges,
  onReceiveCoordinators
}, dispatch);

ListScheduleContainer.propTypes = {
  userRoleAssign: PropTypes.bool,
  userRoleBuild: PropTypes.bool
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ListScheduleContainer));
