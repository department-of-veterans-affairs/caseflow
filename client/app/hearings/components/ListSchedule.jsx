import React from 'react';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';
import { LOGO_COLORS } from '../../constants/AppConstants';
import { css } from 'glamor';
import QueueTable from '../../queue/QueueTable';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import PropTypes from 'prop-types';
import { CSVLink } from 'react-csv';
import {
  toggleTypeFilterVisibility, toggleLocationFilterVisibility,
  toggleVljFilterVisibility, onReceiveHearingSchedule,
  onViewStartDateChange, onViewEndDateChange
} from '../actions/hearingScheduleActions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ListScheduleDateSearch from './ListScheduleDateSearch';
import moment from 'moment';

import { LIST_SCHEDULE_VIEWS, VIDEO_HEARING } from '../constants';
import DropdownButton from '../../components/DropdownButton';

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

const exportHeaders = [
  { label: 'Scheduled For',
    key: 'scheduledFor' },
  { label: 'Type',
    key: 'requestType' },
  { label: 'Regional Office',
    key: 'regionalOffice' },
  { label: 'Room',
    key: 'room' },
  { label: 'VLJ',
    key: 'vlj' }
];

const SwitchViewDropdown = ({ onSwitchView }) => {
  return (
    <DropdownButton
      lists={[
        {
          title: 'Your Hearing Schedule',
          value: LIST_SCHEDULE_VIEWS.DEFAULT_VIEW },
        {
          title: 'Complete Hearing Schedule',
          value: LIST_SCHEDULE_VIEWS.SHOW_ALL }
      ]}
      onClick={onSwitchView}
      label="Switch View" />
  );
};

SwitchViewDropdown.propTypes = { onSwitchView: PropTypes.func };

class ListTable extends React.Component {
  render() {
    return (
      <LoadingDataDisplay
        createLoadPromise={this.props.onApply}
        loadingComponentProps={{
          spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
          message: 'Loading the hearing schedule...'
        }}
        failStatusMessageProps={{
          title: 'Unable to load the hearing schedule.'
        }}>
        {this.props.user.userCanBuildHearingSchedule && <div style={{ marginBottom: 25 }}>
          <Button linkStyling
            onClick={this.props.openModal}>
            Add Hearing Date
          </Button>
        </div>}
        <QueueTable
          columns={this.props.hearingScheduleColumns}
          rowObjects={this.props.hearingScheduleRows}
          summary="hearing-schedule"
          slowReRendersAreOk />

      </LoadingDataDisplay>
    );
  }
}

ListTable.propTypes = {
  hearingScheduleColumns: PropTypes.array,
  hearingScheduleRows: PropTypes.array,
  onApply: PropTypes.func,
  openModal: PropTypes.func,
  user: PropTypes.shape({
    userCanBuildHearingSchedule: PropTypes.bool
  })
};

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

  getHearingScheduleRows = () => {
    const { hearingSchedule } = this.props;

    return _.orderBy(hearingSchedule, (hearingDay) => hearingDay.scheduledFor, 'asc').
      map((hearingDay) => ({
        id: hearingDay.id,
        scheduledFor: hearingDay.scheduledFor,
        readableRequestType: hearingDay.readableRequestType,
        regionalOffice: hearingDay.regionalOffice,
        room: hearingDay.room,
        vlj: formatVljName(hearingDay.judgeLastName, hearingDay.judgeFirstName)
      }));
  };

  getHearingScheduleColumns = (hearingScheduleRows) => {
    return [
      {
        header: 'Date',
        align: 'left',
        valueName: 'scheduledFor',
        valueFunction: (row) => <Link to={`/schedule/docket/${row.id}`}>
          {moment(row.scheduledFor).format('ddd M/DD/YYYY')}
        </Link>,
        getSortValue: (row) => {
          return row.scheduledFor;
        }
      },
      {
        header: 'Type',
        cellClass: 'type-column',
        align: 'left',
        tableData: hearingScheduleRows,
        enableFilter: true,
        filterValueTransform: (hearingType) => {
          if (hearingType.toLowerCase().startsWith('video')) {
            return VIDEO_HEARING;
          }

          return hearingType;
        },
        anyFiltersAreSet: true,
        label: 'Filter by type',
        columnName: 'readableRequestType',
        valueName: 'Hearing Type',
        valueFunction: (row) => row.readableRequestType
      },
      {
        header: 'Regional Office',
        name: 'Regional Office',
        tableData: hearingScheduleRows,
        enableFilter: true,
        anyFiltersAreSet: true,
        enableFilterTextTransform: false,
        label: 'Filter by RO',
        columnName: 'regionalOffice',
        valueName: 'regionalOffice'
      },
      {
        header: 'Room',
        align: 'left',
        valueName: 'room',
        tableData: hearingScheduleRows,
        getSortValue: (hearingDay) => {
          return hearingDay.room;
        }
      },
      {
        header: 'VLJ',
        name: 'VLJ',
        tableData: hearingScheduleRows,
        enableFilter: true,
        anyFiltersAreSet: true,
        label: 'Filter by VLJ',
        columnName: 'vlj',
        valueName: 'vlj'
      }
    ];
  }

  getListView = (hearingScheduleColumns, hearingScheduleRows) => {

    const { user, view, onApply, openModal } = this.props;

    if (!user.userHasHearingPrepRole || view === LIST_SCHEDULE_VIEWS.DEFAULT_VIEW) {
      return <ListTable onApply={onApply}
        openModal={openModal}
        key={`hearings${this.state.dateRangeKey}`}
        user={user}
        hearingScheduleRows={hearingScheduleRows}
        hearingScheduleColumns={hearingScheduleColumns} />;
    }

    return <ListTable onApply={() => onApply({ showAll: true })}
      openModal={openModal}
      key={`allHearings${this.state.dateRangeKey}`}
      user={user}
      hearingScheduleRows={hearingScheduleRows}
      hearingScheduleColumns={hearingScheduleColumns} />;
  }

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
          <div className="cf-push-right list-schedule-buttons" {...downloadButtonStyling} >
            {this.props.user.userHasHearingPrepRole && <SwitchViewDropdown onSwitchView={this.props.switchListView} />}
            <CSVLink
              data={hearingScheduleRows}
              headers={exportHeaders}
              target="_blank"
              filename={`HearingSchedule ${this.props.startDate}-${this.props.endDate}.csv`}>
              <Button classNames={['usa-button-secondary']}>
                Download current view
              </Button>
            </CSVLink>
          </div>
        </div>
        <div className="section-hearings-list">
          {this.getListView(hearingScheduleColumns, hearingScheduleRows)}
        </div>
      </React.Fragment>

    );
  }
}

ListSchedule.propTypes = {
  endDate: PropTypes.string,
  hearingSchedule: PropTypes.shape({
    scheduledFor: PropTypes.string,
    readableRequestType: PropTypes.string,
    regionalOffice: PropTypes.string,
    room: PropTypes.string,
    judgeId: PropTypes.string,
    judgeName: PropTypes.string,
    updatedOn: PropTypes.string,
    updatedBy: PropTypes.string
  }),
  onApply: PropTypes.func,
  onViewStartDateChange: PropTypes.func,
  onViewEndDateChange: PropTypes.func,
  openModal: PropTypes.func,
  startDate: PropTypes.string,
  switchListView: PropTypes.func,
  user: PropTypes.object,
  view: PropTypes.string
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

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ListSchedule));
