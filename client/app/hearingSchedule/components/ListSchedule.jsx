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
import { toggleTypeFilterVisibility, toggleLocationFilterVisibility, toggleVljFilterVisibility } from '../actions'
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

class ListSchedule extends React.Component {

  render() {
    const {
      hearingSchedule
    } = this.props;

    const setTypeSelectedValue = (value) => {
      console.log("this is the Type selected value: ", value);
      this.props.toggleTypeFilterVisibility();
    };

    const setLocationSelectedValue = (value) => {
      console.log("this is the Location selected value: ", value);
      this.props.toggleLocationFilterVisibility();
    };

    const setVljSelectedValue = (value) => {
      console.log("this is the VLJ selected value: ", value);
      this.props.toggleVljFilterVisibility();
    };

    const setRoSelectedValue = (value) => {
      console.log("this is the selected value: ", value);
    };

    const hearingScheduleRows = _.map(hearingSchedule, (hearingDay) => ({
      hearingDate: formatDate(hearingDay.hearingDate),
      hearingType: hearingDay.hearingType,
      regionalOffice: hearingDay.regionalOffice,
      room: hearingDay.roomInfo,
      vlj: formatVljName(hearingDay.judgeLastName, hearingDay.judgeFirstName)
    }));

    const removeCoDuplicates = _.uniqWith(hearingScheduleRows, _.isEqual);

    let hearingTypeList = _.uniqBy(hearingScheduleRows, "hearingType");
    let uniqueHearingTypes = _.map(hearingTypeList, (hearingDay) => {
      return {value: hearingDay.hearingType, displayText: hearingDay.hearingType};
    });
    uniqueHearingTypes = _.sortBy(uniqueHearingTypes, "displayText");

    let listOfVljs = _.uniqBy(hearingScheduleRows, "vlj");
    let uniqueVljs = _.map(listOfVljs, (hearingDay) => {
      return {value: hearingDay.vlj, displayText: hearingDay.vlj};
    });
    uniqueVljs = _.sortBy(uniqueVljs, "displayText");

    let listOfLocations = _.countBy(hearingScheduleRows, "regionalOffice");
    let uniqueLocations = [];
    for (var location in listOfLocations) {
      uniqueLocations.push({value: location, displayText: `${location} (${listOfLocations[location]})`});
    };
    uniqueLocations = _.sortBy(uniqueLocations, "displayText");

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
          onChange={this.setRoSelectedValue}
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
  filterVljIsOpen: state.filterVljIsOpen
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleTypeFilterVisibility,
  toggleLocationFilterVisibility,
  toggleVljFilterVisibility
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(ListSchedule);