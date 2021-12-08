import React from 'react';
import { withRouter } from 'react-router-dom';
import { LOGO_COLORS } from '../../constants/AppConstants';
import { css } from 'glamor';
import QueueTable from '../../queue/QueueTable';
import Button from '../../components/Button';
import PropTypes from 'prop-types';
import { CSVLink } from 'react-csv';
import { formatTableData } from '../utils';
import {
  toggleTypeFilterVisibility, toggleLocationFilterVisibility,
  toggleVljFilterVisibility, onReceiveHearingSchedule,
  onViewStartDateChange, onViewEndDateChange, onResetDeleteSuccessful
} from '../actions/hearingScheduleActions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import ListScheduleDateSearch from './ListScheduleDateSearch';
import { LIST_SCHEDULE_VIEWS } from '../constants';
import DropdownButton from '../../components/DropdownButton';
import WindowUtil from '../../util/WindowUtil';

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
      <React.Fragment>
        {this.props.user.userCanBuildHearingSchedule && <div style={{ marginBottom: 25 }}>
          <Button linkStyling
            onClick={() => this.props.history.push('/schedule/add_hearing_day')}>
            Add Hearing Day
          </Button>
        </div>}
        <QueueTable
          columns={this.props.hearingScheduleColumns}
          rowObjects={this.props.hearingScheduleRows}
          summary="hearing-schedule"
          slowReRendersAreOk
        />
      </React.Fragment>
    );
  }
}

ListTable.propTypes = {
  hearingScheduleColumns: PropTypes.array,
  hearingScheduleRows: PropTypes.array,
  history: PropTypes.object,
  user: PropTypes.shape({
    userCanBuildHearingSchedule: PropTypes.bool
  })
};

class ListSchedule extends React.Component {
  constructor(props) {
    super(props);

    const data = formatTableData(this.props);

    this.state = {
      ...data,
      dateRangeKey: `${props.startDate}->${props.endDate}`
    };
  }

  componentWillUnmount = () => {
    this.props.onResetDeleteSuccessful();
  };

  componentDidUpdate = (prevProps) => {
    if (prevProps.hearingSchedule !== this.props.hearingSchedule) {
      const data = formatTableData(this.props);

      this.setState({
        ...data
      });
    }
  }

  setDateRangeKey = () => {
    this.setState({ dateRangeKey: `${this.props.startDate}->${this.props.endDate}` });
    // show first page by default by sending index of 0
    this.props.fetchHearings(0)
  }

  formatHearingsScheduled = (filledSlots) => {
    return filledSlots;
  }

  getListView = (hearingScheduleColumns, hearingScheduleRows) => {

    const { user, view, history } = this.props;

    if (!user.userHasHearingPrepRole || view === LIST_SCHEDULE_VIEWS.DEFAULT_VIEW) {
      return <ListTable history={history}
        key={`hearings${this.state.dateRangeKey}`}
        user={user}
        hearingScheduleRows={hearingScheduleRows}
        hearingScheduleColumns={hearingScheduleColumns} />;
    }

    return <ListTable history={history}
      key={`allHearings${this.state.dateRangeKey}`}
      user={user}
      hearingScheduleRows={hearingScheduleRows}
      hearingScheduleColumns={hearingScheduleColumns} />;
  }

  render() {
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
              data={this.state.rows}
              headers={this.state.headers}
              target="_blank"
              filename={`HearingSchedule ${this.props.startDate}-${this.props.endDate}.csv`}>
              <Button classNames={['usa-button-secondary']}>
                Download current view
              </Button>
            </CSVLink>
          </div>
        </div>
        <div className="section-hearings-list">
          {this.getListView(this.state.columns, this.state.rows)}
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
  fetchHearings: PropTypes.func.isRequired,
  onResetDeleteSuccessful: PropTypes.func,
  onViewStartDateChange: PropTypes.func,
  onViewEndDateChange: PropTypes.func,
  history: PropTypes.object,
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
  onResetDeleteSuccessful,
  toggleTypeFilterVisibility,
  toggleLocationFilterVisibility,
  toggleVljFilterVisibility,
  onViewStartDateChange,
  onViewEndDateChange,
  onReceiveHearingSchedule
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ListSchedule));
