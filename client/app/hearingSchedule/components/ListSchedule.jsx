import React from 'react';
import _ from 'lodash';
import { LOGO_COLORS } from '../../constants/AppConstants';
import { css } from 'glamor';
import Table from '../../components/Table';
import { formatDate } from '../../util/DateUtil';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import FilterRibbon from '../../components/FilterRibbon';
import PropTypes from 'prop-types';
import { CSVLink } from 'react-csv';
import {
  toggleTypeFilterVisibility, toggleLocationFilterVisibility,
  toggleVljFilterVisibility, onReceiveHearingSchedule,
  onViewStartDateChange, onViewEndDateChange
} from '../actions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ListScheduleDateSearch from './ListScheduleDateSearch';

const downloadButtonStyling = css({
  marginTop: '60px'
});

export const hearingSchedStyling = css({
  marginTop: '50px'
});

const formatVljName = (lastName, firstName) => {
  if (lastName && firstName) {
    return `${lastName}, ${firstName}`;
  }
};

const populateFilterDropDowns = (resultSet, filterName) => {
  let countByFilterName = _.countBy(resultSet, filterName);
  let uniqueOptions = [];

  for (let key in countByFilterName) {
    if (key && key !== 'null' && key !== 'undefined') {
      uniqueOptions.push({
        value: key,
        displayText: `${key} (${countByFilterName[key]})`
      });
    } else {
      uniqueOptions.push({
        value: 'null',
        displayText: `<<blank>> (${countByFilterName[key]})`
      });
    }
  }

  return _.sortBy(uniqueOptions, 'displayText');
};

const filterSchedule = (scheduleToFilter, filterName, value) => {
  let filteredSchedule = {};

  for (let key in scheduleToFilter) {
    if (String(scheduleToFilter[key][filterName]) === String(value)) {
      filteredSchedule[key] = scheduleToFilter[key];
    }
  }

  return filteredSchedule;
};

const inlineFormStyling = css({
  '> div': {
    ' & .cf-inline-form': {
      lineHeight: '2em',
      marginTop: '20px'
    },
    '& .question-label': {
      paddingLeft: 0
    },
    '& .cf-form-textinput': {
      marginTop: 0,
      marginRight: 30
    },
    '& input': {
      marginRight: 0
    }
  }
});

const clearfix = css({
  '::after': {
    content: ' ',
    clear: 'both',
    display: 'block'
  }
});

class ListSchedule extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      filteredByList: [],
      dateRangeKey: `${props.startDate}->${props.endDate}`
    };
  }

  // forces remount of LoadingDataDisplay
  setDateRangeKey = () => {
    this.setState({ dateRangeKey: `${this.props.startDate}->${this.props.endDate}` });
  }

  getHearingScheduleRows = () => {
    const { hearingSchedule } = this.props;

    return _.map(hearingSchedule, (hearingDay) => ({
      hearingDate: <Link to={`/schedule/docket/${hearingDay.id}`}>{formatDate(hearingDay.hearingDate)}</Link>,
      hearingType: hearingDay.hearingType,
      regionalOffice: hearingDay.regionalOffice,
      room: hearingDay.roomInfo,
      vlj: formatVljName(hearingDay.judgeLastName, hearingDay.judgeFirstName)
    }));
  };

  getHearingScheduleColumns = (hearingScheduleRows) => {

    const uniqueHearingTypes = populateFilterDropDowns(hearingScheduleRows, 'hearingType');
    const uniqueVljs = populateFilterDropDowns(hearingScheduleRows, 'vlj');
    const uniqueLocations = populateFilterDropDowns(hearingScheduleRows, 'regionalOffice');

    return [
      {
        header: 'Date',
        align: 'left',
        valueName: 'hearingDate',
        getSortValue: (hearingDay) => {
          return hearingDay.hearingDate;
        }
      },
      {
        header: 'Type',
        cellClass: 'type-column',
        align: 'left',
        valueName: 'hearingType',
        label: 'Filter by type',
        getFilterValues: uniqueHearingTypes,
        isDropdownFilterOpen: this.props.filterTypeIsOpen,
        anyFiltersAreSet: false,
        toggleDropdownFilterVisiblity: this.props.toggleTypeFilterVisibility,
        setSelectedValue: this.setTypeSelectedValue
      },
      {
        header: 'Regional Office',
        align: 'left',
        valueName: 'regionalOffice',
        label: 'Filter by location',
        getFilterValues: uniqueLocations,
        isDropdownFilterOpen: this.props.filterLocationIsOpen,
        anyFiltersAreSet: false,
        toggleDropdownFilterVisiblity: this.props.toggleLocationFilterVisibility,
        setSelectedValue: this.setLocationSelectedValue
      },
      {
        header: 'Room',
        align: 'left',
        valueName: 'room',
        getSortValue: (hearingDay) => {
          return hearingDay.room;
        }
      },
      {
        header: 'VLJ',
        align: 'left',
        valueName: 'vlj',
        label: 'Filter by VLJ',
        getFilterValues: uniqueVljs,
        isDropdownFilterOpen: this.props.filterVljIsOpen,
        anyFiltersAreSet: false,
        toggleDropdownFilterVisiblity: this.props.toggleVljFilterVisibility,
        setSelectedValue: this.setVljSelectedValue
      }
    ];
  }

  clearFilteredByList = () => {
    this.setState({
      filteredByList: []
    });
    this.props.onApply();
  };

  setTypeSelectedValue = (value) => {
    this.props.onReceiveHearingSchedule(filterSchedule(this.props.hearingSchedule, 'hearingType', value));
    this.setState({
      filteredByList: this.state.filteredByList.concat(['Hearing Type'])
    });
    this.props.toggleTypeFilterVisibility();
  };

  setLocationSelectedValue = (value) => {
    this.props.onReceiveHearingSchedule(filterSchedule(this.props.hearingSchedule, 'regionalOffice', value));
    this.setState({
      filteredByList: this.state.filteredByList.concat(['Hearing Location'])
    });
    this.props.toggleLocationFilterVisibility();
  };

  setVljSelectedValue = (value) => {
    this.props.onReceiveHearingSchedule(filterSchedule(this.props.hearingSchedule, 'judgeName', value));
    this.setState({
      filteredByList: this.state.filteredByList.concat(['VLJ'])
    });
    this.props.toggleVljFilterVisibility();
  };

  render() {
    const hearingScheduleRows = this.getHearingScheduleRows();
    const hearingScheduleColumns = this.getHearingScheduleColumns(hearingScheduleRows);

    return (
      <React.Fragment>
        <div {...clearfix}>
          <div className="cf-push-left" {...inlineFormStyling} >
            <ListScheduleDateSearch
              startDateValue={this.props.startDate}
              startDateChange={this.props.onViewStartDateChange}
              endDateValue={this.props.endDate}
              endDateChange={this.props.onViewEndDateChange}
              onApply={this.setDateRangeKey} />
          </div>
          <div className="cf-push-right" {...downloadButtonStyling} >
            <Button
              classNames={['usa-button-secondary']}>
              <CSVLink
                data={hearingScheduleRows}
                target="_blank"
                filename={`HearingSchedule ${this.props.startDate}-${this.props.endDate}.csv`}>
                Download current view
              </CSVLink>
            </Button>
          </div>
        </div>
        <div className="section-hearings-list">
          <LoadingDataDisplay
            key={this.state.dateRangeKey}
            createLoadPromise={this.props.onApply}
            loadingComponentProps={{
              spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
              message: 'Loading the hearing schedule...'
            }}
            failStatusMessageProps={{
              title: 'Unable to load the hearing schedule.'
            }}>

            <div className="cf-push-left">
              <FilterRibbon
                filteredByList={this.state.filteredByList}
                clearAllFilters={this.clearFilteredByList} />
            </div>
            <Table
              columns={hearingScheduleColumns}
              rowObjects={hearingScheduleRows}
              summary="hearing-schedule"
              slowReRendersAreOk />

          </LoadingDataDisplay>
        </div>
      </React.Fragment>

    );
  }
}

ListSchedule.propTypes = {
  hearingSchedule: PropTypes.shape({
    hearingDate: PropTypes.string,
    hearingType: PropTypes.string,
    regionalOffice: PropTypes.string,
    roomInfo: PropTypes.string,
    judgeId: PropTypes.string,
    judgeName: PropTypes.string,
    updatedOn: PropTypes.string,
    updatedBy: PropTypes.string
  }),
  onApply: PropTypes.func
};

const mapStateToProps = (state) => ({
  filterTypeIsOpen: state.hearingSchedule.filterTypeIsOpen,
  filterLocationIsOpen: state.hearingSchedule.filterLocationIsOpen,
  filterVljIsOpen: state.hearingSchedule.filterVljIsOpen,
  startDate: state.hearingSchedule.viewStartDate,
  endDate: state.hearingSchedule.viewEndDate,
  hearingSchedule: state.hearingSchedule.hearingSchedule
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleTypeFilterVisibility,
  toggleLocationFilterVisibility,
  toggleVljFilterVisibility,
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(ListSchedule);
