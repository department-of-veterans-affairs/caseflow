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
      sort: {
        sortParamName: 'sort_by_scheduled_for',
        sortAscending: true,
      },
      addHearingDay: props.component === 'addHearingDay',
      schedule: formatTableData(props),
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

  loadHearingSchedule = (index, sort, filter, dateRange) => {
    this.setState({
      loading: true,
    });

    let requestUrl = `/hearings/hearing_day.json?page=${index + 1}`;

    if (dateRange) {
      const start = moment(dateRange.startDate, dateFormatString, true);
      const end = moment(dateRange.endDate, dateFormatString, true);

      if (!start.isValid() || !end.isValid() || start.isAfter(end) || end.isBefore(start)) {
        return this.props.onInputInvalidDates();
      }

      requestUrl += `&start_date=${dateRange.startDate}&end_date=${dateRange.endDate}&show_all=${this.state.view}`;
    }

    if (sort?.sortParamName) {
      // append sort criteria
      requestUrl += `&query[${sort.sortParamName}]=${sort.sortAscending ? 'asc' : 'desc'}`;
    }

    if (filter) {
      // append filter criteria
      const filterKeys = Object.keys(filter);

      filterKeys.forEach((key) => {
        const { filterOptions, filterParamName } = this.state.schedule?.columns.find((col) => col.columnName === key);
        const values = Object.values(filter[key]).map((value) => filterOptions.find((opt) => opt.value === value));

        requestUrl += `&query[${filterParamName}]=${values.map((value) => value.queryValue).join(',')}`;
      });
    }

    const requestOptions = {
      timeout: { response: getMinutesToMilliseconds(2) },
    };

    return ApiUtil.get(requestUrl, requestOptions, ENDPOINT_NAMES.HEARINGS_SCHEDULE).then((response) => {
      const resp = ApiUtil.convertToCamelCase(response.body);
      const startDate = dateRange?.startDate || resp.startDate;
      const endDate = dateRange?.endDate || resp.endDate;

      this.props.onViewStartDateChange(formatDateStr(startDate, dateFormatString, dateFormatString));
      this.props.onViewEndDateChange(formatDateStr(endDate, dateFormatString, dateFormatString));
      this.setState({
        sort,
        filter,
        dateRange,
        schedule: formatTableData({ ...resp, ...this.props }),
        loaded: true,
        loading: false,
        pagination: {
          currentPage: resp.pagination.page,
          totalCases: resp.pagination.count,
          currentCases: resp.pagination.in,
          totalPages: resp.pagination.pages,
          pageSize: resp.pagination.items,
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
    return this.state.addHearingDay ? (
      <AddHearingDay cancelModal={this.cancelModal} user={this.props.user} />
    ) : (
      <React.Fragment>
        <QueueCaseSearchBar />
        <HearingScheduleAlerts {...this.props} />
        <HearingSchedule
          setDateRange={() => this.loadHearingSchedule(0, this.state.sort, this.state.filter, {
            startDate: this.props.startDate,
            endDate: this.props.endDate,
          })}
          startDate={this.props.startDate}
          endDate={this.props.endDate}
          pagination={this.state.pagination}
          updatePage={(index) => this.loadHearingSchedule(index, this.state.sort, this.state.filter, this.state.dateRange)}
          loaded={this.state.loaded}
          fetching={this.state.loading}
          hearingSchedule={this.state.schedule}
          fetchHearings={this.loadHearingSchedule}
          user={this.props.user}
          view={this.state.view}
          switchListView={this.switchListView}
          filterOptions={this.state.filterOptions}
        />
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
  component: PropTypes.string,
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
