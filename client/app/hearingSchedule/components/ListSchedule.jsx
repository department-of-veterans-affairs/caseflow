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
import InlineForm from '../../components/InlineForm';
import { CSVLink } from 'react-csv';
import { toggleDropdownFilterVisibility } from '../actions'
import {bindActionCreators} from "redux";
import connect from "react-redux/es/connect/connect";

const hearingSchedStyling = css({
  marginTop: '70px'
});

class ListSchedule extends React.Component {

  render() {
    const {
      hearingSchedule
    } = this.props;

    var options = React.createElement(
      'ul', {
        className: 'cf-form-dropdown'
      },
      React.createElement('li', {id: 'C'},'Central'),
      React.createElement('li', {id: 'V'},'Video'),
      React.createElement('li', {id: 'T'},'Travel Board')
    );

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
        getFilterValues: options,
        isDropdownFilterOpen: this.props.filterDropdownIsOpen,
        anyFiltersAreSet: false,
        toggleDropdownFilterVisiblity: this.props.toggleDropdownFilterVisibility
      },
      {
        header: 'Regional Office',
        align: 'left',
        valueName: 'regionalOffice',
        getSortValue: (hearingDay) => {return hearingDay.regionalOffice}
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
        getSortValue: (hearingDay) => {return hearingDay.vlj}
      }
    ];

    const formatVljName = (lastName, firstName) => {
      if (lastName && firstName) {
        return `${lastName}, ${firstName}`;
      }
    };

    const hearingScheduleRows = _.map(hearingSchedule, (hearingDay) => ({
      hearingDate: formatDate(hearingDay.hearingDate),
      hearingType: hearingDay.hearingType,
      regionalOffice: hearingDay.regionalOffice,
      room: hearingDay.roomInfo,
      vlj: formatVljName(hearingDay.judgeLastName, hearingDay.judgeFirstName)
    }));

    const removeCoDuplicates = _.uniqWith(hearingScheduleRows, _.isEqual);

    const fileName = `HearingSchedule ${this.props.startDateValue}-${this.props.endDateValue}.csv`;

    return <AppSegment filledBackground>
      <h1 className="cf-push-left">{COPY.HEARING_SCHEDULE_VIEW_PAGE_HEADER}</h1>
      {this.props.userRoleBuild &&
        <span className="cf-push-right"><Link button="primary" to="/schedule/build">Build schedule</Link></span>
      }
      {this.props.userRoleAssign &&
      < span className="cf-push-right"><Link button="primary" to="/schedule/assign">Assign hearings</Link></span>
      }
      <div className="cf-help-divider" {...hearingSchedStyling} ></div>
      <div className="cf-push-left">
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
      <div className="cf-push-right" {...hearingSchedStyling}>
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
  filterDropdownIsOpen: state.filterDropdownIsOpen
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleDropdownFilterVisibility,
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(ListSchedule);