import React from 'react';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';
import Table from '../components/Table';
import TabWindow from '../components/TabWindow';
import moment from 'moment';
import { Link } from 'react-router-dom';
import { getDateTime } from './util/DateUtil';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';

import { CATEGORIES, ACTIONS } from './analytics';
import { selectDocketsPageTabIndex } from './actions/Dockets';

const UPCOMING_TAB_INDEX = 0;
const PAST_TAB_INDEX = 1;

/*
  Day Time for Travel Board
  Monday 12:30pm
  Tuesday 8:30am
  Wednesday 8:30am
  Thursday 8:30am
  Friday 8:30am
*/
const TRAVEL_BOARD_DEFAULT_MONDAY_START_TIME = {
  hour: 12,
  minutes: 30
};
const TRAVEL_BOARD_DEFAULT_WEEKDAY_START_TIME = {
  hour: 8,
  minutes: 30
};
const MONDAY_AS_DAY_OF_THE_WEEK = 1;

export const DOCKETS_TAB_INDEX_MAPPING = {
  [UPCOMING_TAB_INDEX]: 'Upcoming',
  [PAST_TAB_INDEX]: 'Past'
};

const tableBorder = css({
  border: '1px solid #dadbdc',
  marginTop: '0px',
  borderTop: '0px'
});

const tableBodyStyling = css({
  display: 'block',
  maxHeight: '65vh',
  overflow: 'auto',
  width: '100%'
});

const tabBodyStyling = css({
  paddingTop: '0px'
});

export class Dockets extends React.Component {

  getKeyForRow = (index) => {
    return index;
  }

  dateClicked = () => {
    const action = this.props.docketsTabIndex === PAST_TAB_INDEX ? ACTIONS.OPEN_PAST_HEARING_DOCKET :
      ACTIONS.OPEN_CURRENT_HEARING_DOCKET;

    window.analyticsEvent(CATEGORIES.HEARINGS_DAYS_PAGE, action);
  }

  getDocketDateTime = (docket) => {
    let convertedDate = moment(docket.scheduled_for);

    if (docket.type === 'travel' && docket.master_record) {
      if (convertedDate.day() === MONDAY_AS_DAY_OF_THE_WEEK) {
        convertedDate.set({
          hour: TRAVEL_BOARD_DEFAULT_MONDAY_START_TIME.hour,
          minute: TRAVEL_BOARD_DEFAULT_MONDAY_START_TIME.minutes
        });
      } else {
        convertedDate.set({
          hour: TRAVEL_BOARD_DEFAULT_WEEKDAY_START_TIME.hour,
          minute: TRAVEL_BOARD_DEFAULT_WEEKDAY_START_TIME.minutes
        });
      }
    }

    return convertedDate;
  }

  linkToDailyDocket = (docket) => {
    const momentDate = moment(docket.scheduled_for);

    // don't show a link if it's a master record or if the docket date is more
    // than 30 days away from current day.
    if (docket.master_record || momentDate.isAfter(moment().add(30, 'days'))) {
      return moment(docket.scheduled_for).format('ddd M/DD/YYYY');
    }

    return <Link
      onClick={this.dateClicked}
      to={`/hearings/dockets/${moment(docket.scheduled_for).format('YYYY-MM-DD')}`}
    >
      {moment(docket.scheduled_for).format('ddd M/DD/YYYY')}
    </Link>;
  }

  onTabSelected = (tabNumber) => this.props.selectDocketsPageTabIndex(tabNumber);

  getScheduledCount = (docket) => {
    return (docket.master_record ? 0 : docket.hearings_count);
  }

  getCombinedRONames = (docket) => docket.regional_office_names ? docket.regional_office_names.join(' / ') : '';
  getRegionalOffice = (docket) => docket.type === 'central' ? '' : this.getCombinedRONames(docket);

  getRowObjects = (hearings, reverseSort = false) => {
    let docketIndex = Object.keys(hearings).sort();

    docketIndex = reverseSort ? docketIndex.reverse() : docketIndex;
    const rowObjects = docketIndex.map((docketDate) => {

      let docket = hearings[docketDate];

      return {
        date: this.linkToDailyDocket(docket),
        start_time: getDateTime(this.getDocketDateTime(docket)),
        type: docket.readable_request_type,
        regional_office: this.getRegionalOffice(docket),
        slots: docket.slots,
        scheduled: this.getScheduledCount(docket)
      };
    });

    return rowObjects;
  }

  render() {
    const columns = [
      {
        header: 'Date',
        valueName: 'date'
      },
      {
        header: 'Start Time',
        valueName: 'start_time'
      },
      {
        header: 'Type',
        valueName: 'type'
      },
      {
        header: 'Regional Office',
        valueName: 'regional_office'
      },
      {
        header: 'Slots',
        align: 'center',
        valueName: 'slots'
      },
      {
        header: 'Scheduled',
        align: 'center',
        valueName: 'scheduled'
      }
    ];

    const defaultGroupedHearings = {
      upcoming: {},
      past: {}
    };

    const groupedHearings = _.reduce(this.props.upcomingHearings, (result, value, key) => {
      const dateMoment = moment(value.scheduled_for);
      const pastOrUpcoming = dateMoment.isAfter(new Date().setHours(0, 0, 0, 0)) ? 'upcoming' : 'past';

      result[pastOrUpcoming][key] = value;

      return result;
    }, defaultGroupedHearings);

    const upcomingRowObjects = this.getRowObjects(groupedHearings.upcoming);
    let pastRowObjects = this.getRowObjects(groupedHearings.past, true);

    const tabs = [
      {
        label: DOCKETS_TAB_INDEX_MAPPING[UPCOMING_TAB_INDEX],
        page: _.size(upcomingRowObjects) ? <Table
          className="hearings"
          columns={columns}
          rowObjects={upcomingRowObjects}
          summary="Your Upcoming Hearing Days"
          getKeyForRow={this.getKeyForRow}
          styling={tableBorder}
          bodyStyling={tableBodyStyling}
        /> : <p>You currently have no hearings scheduled.</p>
      },
      {
        label: DOCKETS_TAB_INDEX_MAPPING[PAST_TAB_INDEX],
        page: _.size(pastRowObjects) ? <Table
          className="hearings"
          columns={columns}
          rowObjects={pastRowObjects}
          summary="Your Past Hearing Days"
          getKeyForRow={this.getKeyForRow}
          styling={tableBorder}
          bodyStyling={tableBodyStyling}
        /> : <p>You have not held any hearings in the past 365 days.</p>
      }
    ];

    return <AppSegment extraClassNames="cf-hearings-schedule" filledBackground>
      <div className="cf-hearings-title-and-judge">
        <h1>Your Hearing Days</h1>
        <span>VLJ: {this.props.veteranLawJudge.full_name}</span>
      </div>

      <TabWindow
        className="dockets"
        bodyStyling={tabBodyStyling}
        name="dockets"
        tabs={tabs}
        onChange={this.onTabSelected} />
    </AppSegment>;
  }
}

const mapStateToProps = (state) => ({
  upcomingHearings: state.upcomingHearings,
  docketsTabIndex: state.docketsTabIndex
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  selectDocketsPageTabIndex
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Dockets);

Dockets.propTypes = {
  veteranLawJudge: PropTypes.object.isRequired,
  upcomingHearings: PropTypes.object.isRequired
};
