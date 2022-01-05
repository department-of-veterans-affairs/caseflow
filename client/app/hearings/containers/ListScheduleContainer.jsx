import React from 'react';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import _ from 'lodash';
import HearingSchedule from 'app/hearings/components/HearingSchedule';
import {
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule,
  onInputInvalidDates,
  onResetInvalidDates,
  onSelectedHearingDayChange,
  selectRequestType,
  onResetDeleteSuccessful,
  onAssignHearingRoom,
} from '../actions/hearingScheduleActions';
import {
  selectVlj,
  selectHearingCoordinator,
  setNotes,
} from '../actions/dailyDocketActions';
import { bindActionCreators } from 'redux';
import { formatDateStr, getMinutesToMilliseconds } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import PropTypes from 'prop-types';
import QueueCaseSearchBar from '../../queue/SearchBar';
import AddHearingDay from '../components/AddHearingDay';
import { onRegionalOfficeChange } from '../../components/common/actions';
import moment from 'moment';
import { formatTableData } from 'app/hearings/utils';
import { HearingScheduleAlerts } from 'app/hearings/components/HearingSchedule/Alerts';

import { LIST_SCHEDULE_VIEWS, ENDPOINT_NAMES } from '../constants';

const dateFormatString = 'YYYY-MM-DD';

export class ListScheduleContainer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      prevQueries: JSON.stringify({ sort: {}, filter: {} }),
      schedule: formatTableData(props),
      dateRangeKey: `${props.startDate}->${props.endDate}`,
      modalOpen: false,
      showModalAlert: false,
      view: LIST_SCHEDULE_VIEWS.DEFAULT_VIEW,
      // This will hold a reference to the button that opens the modal in order to preserve
      // page flow when the modal is closed
      modalButton: null,
      queries: {},
      loading: false,
      pagination: {
        currentPage: 0,
        totalCases: 0,
        currentCases: 0,
        totalPages: 0,
        pageSize: 0,
      }
    };
  }

  switchListView = (view) => {
    this.setState({ view }, () => this.loadHearingSchedule(0));
  };

  componentDidMount = () => {
    this.loadHearingSchedule(this.state.pagination.currentPage);
    this.props.onSelectedHearingDayChange('');
  };

  componentDidUpdate = (prevProps) => {
    if (
      !(
        (_.isNil(prevProps.invalidDates) && this.props.invalidDates) ||
        _.isNil(this.props.invalidDates)
      )
    ) {
      this.props.onResetInvalidDates();
    }
  };

  updateQueries = (newQueries) => {
    this.setState({ queries: newQueries }, () => this.loadHearingSchedule(0));
  };

  loadHearingSchedule = (index) => {
    this.setState({
      loading: true,
    });

    let requestUrl = `/hearings/hearing_day.json?page=${index + 1}`;

    if (this.props.startDate && this.props.endDate) {
      if (
        !moment(this.props.startDate, dateFormatString, true).isValid() ||
        !moment(this.props.endDate, dateFormatString, true).isValid()
      ) {
        return this.props.onInputInvalidDates();
      }

      requestUrl += `?start_date=${this.props.startDate}&end_date=${this.props.endDate}&show_all=${this.state.view}`;
    }

    if (this.state.queries.sort) {
      // append sort criteria
      requestUrl += `&query[${this.state.queries.sort.column}]=${this.state.queries.sort.direction}`;
    }

    if (this.state.queries.filter) {
      // append filter criteria
      const filterKeys = Object.keys(this.state.queries.filter);

      filterKeys.forEach((filter) => {
        requestUrl += `&query[${filter}]=${Object.values(this.state.queries.filter[filter]).join(',')}`;
      });
    }

    const requestOptions = {
      timeout: { response: getMinutesToMilliseconds(2) },
    };

    return ApiUtil.get(requestUrl, requestOptions, ENDPOINT_NAMES.HEARINGS_SCHEDULE).then((response) => {
      const resp = ApiUtil.convertToCamelCase(response.body);

      this.props.onReceiveHearingSchedule(resp.hearings);
      this.props.onViewStartDateChange(formatDateStr(resp.startDate, dateFormatString, dateFormatString));
      this.props.onViewEndDateChange(formatDateStr(resp.endDate, dateFormatString, dateFormatString));

      this.setState({
        schedule: formatTableData({ ...resp.hearings, ...this.props }),
        loaded: true,
        loading: false,
        pagination: {
          currentPage: resp.pagination.page,
          totalCases: resp.pagination.count,
          currentCases: resp.pagination.items,
          totalPages: resp.pagination.pages,
          pageSize: resp.pagination.in,
        },
        filterOptions: resp.filterOptions,
      });
    });
  };

  openModal = (event) => {
    this.setState({
      showModalAlert: false,
      modalOpen: true,
      serverError: false,
      noRoomsAvailable: false,
      modalButton: event.target,
    });
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
      showModalAlert: true,
    });
  };

  cancelModal = () => {
    // Move the focus back to the button that opened the modal
    this.state.modalButton.focus();

    this.setState({
      modalOpen: false,
      modalButton: null,
    });
  };

  render() {
    const user = this.props.user;

    // Determine the path to render the correct component
    const addHearingDay = (/add_hearing_day/).test(this.props.location.pathname);

    return (
      <React.Fragment>
        {!addHearingDay && <QueueCaseSearchBar />}
        <HearingScheduleAlerts {...this.props} />
        {addHearingDay ? (
          <AddHearingDay cancelModal={this.cancelModal} user={user} />
        ) : (
          <HearingSchedule
            pagination={this.state.pagination}
            updatePage={(index) => this.loadHearingSchedule(index)}
            loaded={this.state.loaded}
            fetching={this.state.loading}
            hearingSchedule={this.state.schedule}
            fetchHearings={this.loadHearingSchedule}
            user={user}
            view={this.state.view}
            switchListView={this.switchListView}
            filterOptions={this.state.filterOptions}
            updateQueries={this.updateQueries}
          />
        )}
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
  successfulHearingDayDelete: state.hearingSchedule.successfulHearingDayDelete,
  successfulHearingDayCreate: state.hearingSchedule.successfulHearingDayCreate,
  invalidDates: state.hearingSchedule.invalidDates,
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      onViewStartDateChange,
      onViewEndDateChange,
      onReceiveHearingSchedule,
      onInputInvalidDates,
      onResetInvalidDates,
      onSelectedHearingDayChange,
      selectRequestType,
      selectVlj,
      selectHearingCoordinator,
      setNotes,
      onAssignHearingRoom,
      onRegionalOfficeChange,
      onResetDeleteSuccessful,
    },
    dispatch
  );

ListScheduleContainer.propTypes = {
  endDate: PropTypes.string,
  hearingSchedule: PropTypes.object,
  invalidDates: PropTypes.bool,
  onAssignHearingRoom: PropTypes.func,
  onInputInvalidDates: PropTypes.func,
  onReceiveHearingSchedule: PropTypes.func,
  onRegionalOfficeChange: PropTypes.func,
  onResetDeleteSuccessful: PropTypes.func,
  onResetInvalidDates: PropTypes.func,
  onSelectedHearingDayChange: PropTypes.func,
  onViewEndDateChange: PropTypes.func,
  onViewStartDateChange: PropTypes.func,
  selectedHearingDay: PropTypes.string,
  selectHearingCoordinator: PropTypes.func,
  selectRequestType: PropTypes.func,
  selectVlj: PropTypes.func,
  setNotes: PropTypes.func,
  startDate: PropTypes.string,
  successfulHearingDayDelete: PropTypes.string,
  successfulHearingDayCreate: PropTypes.string,
  user: PropTypes.object,
  history: PropTypes.object,
  location: PropTypes.object,
};

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(ListScheduleContainer)
);
