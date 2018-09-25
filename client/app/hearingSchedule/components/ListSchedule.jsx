import React from 'react';
import _ from 'lodash';
import COPY from '../../../COPY.json';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Table from '../../components/Table';
import { formatDate } from '../../util/DateUtil';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import PropTypes from 'prop-types';
import BasicDateRangeSelector from '../../components/BasicDateRangeSelector';
import RoSelectorDropdown from './RoSelectorDropdown'
import InlineForm from '../../components/InlineForm';
import { CSVLink } from 'react-csv';
import { toggleTypeFilterVisibility, toggleLocationFilterVisibility,
  toggleVljFilterVisibility, onRegionalOfficeChange, onReceiveHearingSchedule } from '../actions'
import {bindActionCreators} from "redux";
import connect from "react-redux/es/connect/connect";

const hearingSchedStyling = css({
  marginTop: '50px'
});

const downloadButtonStyling = css({
  marginTop: '60px'
});

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
      marginTop: 0
    },
    '& input': {
      marginRight: 0
    }
  }
});

const formatVljName = (lastName, firstName) => {
  if (lastName && firstName) {
    return `${lastName}, ${firstName}`;
  }
};

const populateFilterDropDowns = (resultSet, filterName) => {
  let countByFilterName = _.countBy(resultSet, filterName);
  let uniqueOptions = [];
  for (var key in countByFilterName) {
    if (key && key !== "null" && key !== "undefined") {
      uniqueOptions.push({value: key, displayText: `${key} (${countByFilterName[key]})`});
    }else {
      uniqueOptions.push({value: "<<blank>>", displayText: `<<blank>> (${countByFilterName[key]})`});
    }
  }
  return _.sortBy(uniqueOptions, "displayText");
};

const filterSchedule = (scheduleToFilter, filterName, value) => {
  let filteredSchedule = {};
  for(var key in scheduleToFilter){
    if (scheduleToFilter[key][filterName] === value){
      filteredSchedule[key] = scheduleToFilter[key];
    }
  }
  return filteredSchedule;
};

class ListSchedule extends React.Component {

  render() {
    const {
      hearingSchedule
    } = this.props;

    const setTypeSelectedValue = (value) => {
      this.props.onReceiveHearingSchedule(filterSchedule(hearingSchedule, "hearingType", value));
      this.props.toggleTypeFilterVisibility();
    };

    const setLocationSelectedValue = (value) => {
      this.props.onReceiveHearingSchedule(filterSchedule(hearingSchedule, "regionalOffice", value));
      this.props.toggleLocationFilterVisibility();
    };

    const setVljSelectedValue = (value) => {
      this.props.onReceiveHearingSchedule(filterSchedule(hearingSchedule, "judgeName", value));
      this.props.toggleVljFilterVisibility();
    };

    const hearingScheduleRows = _.map(hearingSchedule, (hearingDay) => ({
      hearingDate: formatDate(hearingDay.hearingDate),
      hearingType: hearingDay.hearingType,
      regionalOffice: hearingDay.regionalOffice,
      room: hearingDay.roomInfo,
      vlj: formatVljName(hearingDay.judgeLastName, hearingDay.judgeFirstName)
    }));

    const removeCoDuplicates = _.uniqWith(hearingScheduleRows, _.isEqual);
    const uniqueHearingTypes = populateFilterDropDowns(removeCoDuplicates, "hearingType");
    const uniqueVljs = populateFilterDropDowns(removeCoDuplicates, "vlj");
    const uniqueLocations = populateFilterDropDowns(removeCoDuplicates, "regionalOffice");
    const fileName = `HearingSchedule ${this.props.startDateValue}-${this.props.endDateValue}.csv`;

    var options = [{value: 'C', displayText: 'Central'},
      {value: 'V', displayText: 'Video'},
      {value: 'T', displayText: 'Travel Board'}];

    const hearingScheduleColumns = [
      {
        header: 'Date',
        align: 'left',
        valueName: 'hearingDate',
        getSortValue: (hearingDay) => {return hearingDay.hearingDate}
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
        setSelectedValue: setTypeSelectedValue
      },
      {
        header: 'Hearing Location',
        align: 'left',
        valueName: 'regionalOffice',
        label: 'Filter by location',
        getFilterValues: uniqueLocations,
        isDropdownFilterOpen: this.props.filterLocationIsOpen,
        anyFiltersAreSet: false,
        toggleDropdownFilterVisiblity: this.props.toggleLocationFilterVisibility,
        setSelectedValue: setLocationSelectedValue
      },
      {
        header: 'Room',
        align: 'left',
        valueName: 'room',
        getSortValue: (hearingDay) => {return hearingDay.room}
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
        setSelectedValue: setVljSelectedValue
      }
    ];

    return <AppSegment filledBackground>
      <h1 className="cf-push-left">{COPY.HEARING_SCHEDULE_VIEW_PAGE_HEADER}</h1>
      {this.props.userRoleBuild &&
        <span className="cf-push-right"><Link button="primary" to="/schedule/build">Build schedule</Link></span>
      }
      {this.props.userRoleAssign &&
      < span className="cf-push-right"><Link button="primary" to="/schedule/assign">Assign hearings</Link></span>
      }
      <div className="cf-help-divider" {...hearingSchedStyling} ></div>
      <div>
        <RoSelectorDropdown
          onChange={this.props.onRegionalOfficeChange}
          value={this.props.selectedRegionalOffice}
          placeholder="All"
        />
      </div>
      <div className="cf-push-left" {...inlineFormStyling} >
        <InlineForm>
          <BasicDateRangeSelector
            startDateName="fromDate"
            startDateValue={this.props.startDateValue}
            startDateLabel={COPY.HEARING_SCHEDULE_VIEW_START_DATE_LABEL}
            endDateName="toDate"
            endDateValue={this.props.endDateValue}
            endDateLabel={COPY.HEARING_SCHEDULE_VIEW_END_DATE_LABEL}
            onStartDateChange={this.props.startDateChange}
            onEndDateChange={this.props.endDateChange}
          />
          &nbsp;&nbsp;&nbsp;&nbsp;
          <div {...hearingSchedStyling}>
            <Link
              name="apply"
              to="/schedule"
              onClick={this.props.onApply}>
              {COPY.HEARING_SCHEDULE_VIEW_PAGE_APPLY_LINK}
            </Link>
          </div>
        </InlineForm>
      </div>
      <div className="cf-push-right" {...downloadButtonStyling} >
        <Button
          classNames={['usa-button-secondary']}>
          <CSVLink
            data={removeCoDuplicates}
            target="_blank"
            filename={fileName}>
            Download current view
          </CSVLink>
        </Button>
      </div>
      <div {...hearingSchedStyling} className="section-hearings-list">
        <Table
          columns={hearingScheduleColumns}
          rowObjects={removeCoDuplicates}
          summary="hearing-schedule"
        />
      </div>
    </AppSegment>;
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
  filterTypeIsOpen: state.filterTypeIsOpen,
  filterLocationIsOpen: state.filterLocationIsOpen,
  filterVljIsOpen: state.filterVljIsOpen,
  selectedRegionalOffice: state.selectedRegionalOffice
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleTypeFilterVisibility,
  toggleLocationFilterVisibility,
  toggleVljFilterVisibility,
  onRegionalOfficeChange,
  onReceiveHearingSchedule
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(ListSchedule);