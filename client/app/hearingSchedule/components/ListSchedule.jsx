import React from 'react';
import _ from 'lodash';
import COPY from '../../../COPY.json';
import { css } from 'glamor';
import Table from '../../components/Table';
import { formatDate } from '../../util/DateUtil';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import FilterRibbon from '../../components/FilterRibbon';
import PropTypes from 'prop-types';
import { CSVLink } from 'react-csv';
import { toggleTypeFilterVisibility, toggleLocationFilterVisibility,
  toggleVljFilterVisibility, onReceiveHearingSchedule } from '../actions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';

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

class ListSchedule extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      filteredByList: []
    };
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

  componentDidMount = () => {
    this.setState({
      filteredByList: []
    });
  };

  setVljSelectedValue = (value) => {
    this.props.onReceiveHearingSchedule(filterSchedule(this.props.hearingSchedule, 'judgeName', value));
    this.setState({
      filteredByList: this.state.filteredByList.concat(['VLJ'])
    });
    this.props.toggleVljFilterVisibility();
  };

  render() {
    const { hearingSchedule } = this.props;

    const hearingScheduleRows = _.map(hearingSchedule, (hearingDay) => ({
      hearingDate: <Link to={`/schedule/docket/${hearingDay.id}`}>{formatDate(hearingDay.hearingDate)}</Link>,
      hearingType: hearingDay.hearingType,
      regionalOffice: hearingDay.regionalOffice,
      room: hearingDay.roomInfo,
      vlj: formatVljName(hearingDay.judgeLastName, hearingDay.judgeFirstName)
    }));

    const uniqueHearingTypes = populateFilterDropDowns(hearingScheduleRows, 'hearingType');
    const uniqueVljs = populateFilterDropDowns(hearingScheduleRows, 'vlj');
    const uniqueLocations = populateFilterDropDowns(hearingScheduleRows, 'regionalOffice');
    const fileName = `HearingSchedule ${this.props.startDateValue}-${this.props.endDateValue}.csv`;

    const hearingScheduleColumns = [
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

    return (
      <React.Fragment>
        <div className="cf-push-right" {...downloadButtonStyling} >
          <Button
            classNames={['usa-button-secondary']}>
            <CSVLink
              data={hearingScheduleRows}
              target="_blank"
              filename={fileName}>
              Download current view
            </CSVLink>
          </Button>
        </div>
        <div {...hearingSchedStyling} className="section-hearings-list">
          <FilterRibbon
            filteredByList={this.state.filteredByList}
            clearAllFilters={this.clearFilteredByList} />
          <Table
            columns={hearingScheduleColumns}
            rowObjects={hearingScheduleRows}
            summary="hearing-schedule"/>
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
  startDateValue: PropTypes.string,
  endDateValue: PropTypes.string,
  startDateChange: PropTypes.func,
  endDateChange: PropTypes.func,
  onApply: PropTypes.func,
  userRole: PropTypes.string
};

const mapStateToProps = (state) => ({
  filterTypeIsOpen: state.hearingSchedule.filterTypeIsOpen,
  filterLocationIsOpen: state.hearingSchedule.filterLocationIsOpen,
  filterVljIsOpen: state.hearingSchedule.filterVljIsOpen
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleTypeFilterVisibility,
  toggleLocationFilterVisibility,
  toggleVljFilterVisibility,
  onReceiveHearingSchedule
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(ListSchedule);
