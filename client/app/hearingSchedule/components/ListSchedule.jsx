import React from 'react';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';
import { LOGO_COLORS } from '../../constants/AppConstants';
import { css } from 'glamor';
import moment from 'moment';

import NewTable from '../../components/NewTable';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import PropTypes from 'prop-types';
import { CSVLink } from 'react-csv';
import {
  onViewStartDateChange,
  onViewEndDateChange
} from '../actions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ListScheduleDateSearch from './ListScheduleDateSearch';
import { COLUMN_NAMES } from '../constants';

const downloadButtonStyling = css({
  marginTop: '60px'
});

const formatVljName = (lastName, firstName) => {
  if (lastName && firstName) {
    return `${lastName}, ${firstName}`;
  }
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
      dateRangeKey: `${props.startDate}->${props.endDate}`
    };
  }

  // forces remount of LoadingDataDisplay
  setDateRangeKey = () => {
    this.setState({ dateRangeKey: `${this.props.startDate}->${this.props.endDate}` });
  }

  getHearingScheduleRows = (forCsv = false) => {
    const { hearingSchedule } = this.props;

    return _.orderBy(hearingSchedule, (hearingDay) => hearingDay.scheduledFor, 'asc').
      map((hearingDay) => ({
        scheduledFor: forCsv ? hearingDay.scheduledFor : <Link to={`/schedule/docket/${hearingDay.id}`}>
          {moment(hearingDay.scheduledFor).format('ddd M/DD/YYYY')}
        </Link>,
        requestType: hearingDay.requestType,
        regionalOffice: hearingDay.regionalOffice,
        room: hearingDay.room,
        vlj: formatVljName(hearingDay.judgeLastName, hearingDay.judgeFirstName)
      }));
  };

  getHearingScheduleColumns = () => {
    return [
      {
        header: 'Date',
        align: 'left',
        valueName: 'scheduledFor',
        getSortValue: (hearingDay) => {
          return hearingDay.scheduledFor;
        }
      },
      {
        header: 'Type',
        cellClass: 'type-column',
        align: 'left',
        valueName: 'requestType',
        enableFilter: true,
        columnName: 'requestType',
        tableData: this.getHearingScheduleRows(false),
        label: 'Filter by type',
        disableClearFiltersRow: true
      },
      {
        header: 'Regional Office',
        align: 'left',
        valueName: 'regionalOffice',
        enableFilter: true,
        columnName: 'regionalOffice',
        tableData: this.getHearingScheduleRows(false),
        label: 'Filter by location',
        disableClearFiltersRow: true
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
        enableFilter: true,
        columnName: 'vlj',
        tableData: this.getHearingScheduleRows(false),
        label: 'Filter by VLJ',
        disableClearFiltersRow: true
      }
    ];
  }

  render() {
    const hearingScheduleRows = this.getHearingScheduleRows(false);
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
                data={this.getHearingScheduleRows(true)}
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

            <div {...clearfix}>
              <div className="cf-push-left">
                { this.props.userRoleBuild &&
                  <Button
                    linkStyling
                    onClick={this.props.openModal} >
                    Add Hearing Date
                  </Button>
                }
              </div>
            </div>
            <NewTable
              columns={hearingScheduleColumns}
              rowObjects={hearingScheduleRows}
              summary="hearing-schedule"
              alternateColumnNames={COLUMN_NAMES}
              slowReRendersAreOk />
          </LoadingDataDisplay>
        </div>
      </React.Fragment>

    );
  }
}

ListSchedule.propTypes = {
  hearingSchedule: PropTypes.shape({
    scheduledFor: PropTypes.string,
    requestType: PropTypes.string,
    regionalOffice: PropTypes.string,
    room: PropTypes.string,
    judgeId: PropTypes.string,
    judgeName: PropTypes.string,
    updatedOn: PropTypes.string,
    updatedBy: PropTypes.string
  }),
  onApply: PropTypes.func,
  openModal: PropTypes.func
};

const mapStateToProps = (state) => ({
  startDate: state.hearingSchedule.viewStartDate,
  endDate: state.hearingSchedule.viewEndDate,
  hearingSchedule: state.hearingSchedule.hearingSchedule
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onViewStartDateChange,
  onViewEndDateChange
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ListSchedule));
