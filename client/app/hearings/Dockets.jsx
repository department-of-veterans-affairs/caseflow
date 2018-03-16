import React from 'react';
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

const PAST_HEARING_TAB_INDEX = 1;

const tableBorder = css({
  border: '1px solid #dadbdc',
  marginTop: '0px'
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
  constructor(props) {
    super(props);

    this.state = {
      viewingPastTab: false
    };
  }

  onTabSelected = (tabNumber) => {
    if (tabNumber === PAST_HEARING_TAB_INDEX) {
      this.togglePastDocketsTab(true);
      window.analyticsEvent(CATEGORIES.HEARINGS_DAYS_PAGE, ACTIONS.OPEN_PAST_HEARINGS_TAB);
    } else {
      this.togglePastDocketsTab(false);
    }
  }

  getType = (type) => {
    const capitalizeFirstChar = (str) => str ? str.charAt(0).toUpperCase() + str.slice(1) : '';

    return (type === 'central_office') ? 'CO' :
      capitalizeFirstChar(type);
  }

  getKeyForRow = (index) => {
    return index;
  }

  dateClicked = () => {
    const action = this.state.viewingPastTab ? ACTIONS.OPEN_PAST_HEARING_DOCKET :
      ACTIONS.OPEN_CURRENT_HEARING_DOCKET;

    window.analyticsEvent(CATEGORIES.HEARINGS_DAYS_PAGE, action);
  }

  linkToDailyDocket = (docket) => {
    if (docket.master_record) {
      return moment(docket.date).format('ddd M/DD/YYYY');
    }

    return <Link onClick={this.dateClicked} to={`/hearings/dockets/${moment(docket.date).format('YYYY-MM-DD')}`}>
      {moment(docket.date).format('ddd M/DD/YYYY')}
    </Link>;
  }

  togglePastDocketsTab = (isPastTab) => {
    this.setState({
      viewingPastTab: isPastTab
    });
  }

  getScheduledCount = (docket) => {
    return (docket.master_record ? 0 : docket.hearings_count);
  }

  onTabSelected = (tabNumber) => {
    if (tabNumber === PAST_HEARING_TAB_INDEX) {
      window.analyticsEvent(CATEGORIES.HEARINGS_DAYS_PAGE, ACTIONS.PAST_HEARINGS_TAB);
    }
  }

  getRowObjects = (hearings, reverseSort = false) => {
    let docketIndex = Object.keys(hearings).sort();

    docketIndex = reverseSort ? docketIndex.reverse() : docketIndex;
    const rowObjects = docketIndex.map((docketDate) => {

      let docket = hearings[docketDate];

      return {
        date: this.linkToDailyDocket(docket),
        start_time: getDateTime(docket.date),
        type: this.getType(docket.type),
        regional_office: docket.regional_office_name,
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
      const dateMoment = moment(value.date);
      const pastOrUpcoming = dateMoment.isAfter(new Date().setHours(0, 0, 0, 0)) ? 'upcoming' : 'past';

      result[pastOrUpcoming][key] = value;

      return result;
    }, defaultGroupedHearings);

    const upcomingRowObjects = this.getRowObjects(groupedHearings.upcoming);
    let pastRowObjects = this.getRowObjects(groupedHearings.past, true);

    const tabs = [
      {
        label: 'Upcoming',
        page: _.size(upcomingRowObjects) ? <Table
          className="hearings"
          columns={columns}
          rowObjects={upcomingRowObjects}
          summary="Your Upcoming Hearing Days?"
          getKeyForRow={this.getKeyForRow}
          styling={tableBorder}
          bodyStyling={tableBodyStyling}
        /> : <p>You currently have no hearings scheduled.</p>
      },
      {
        label: 'Past',
        page: _.size(pastRowObjects) ? <Table
          className="hearings"
          columns={columns}
          rowObjects={pastRowObjects}
          summary="Your Past Hearing Days?"
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
  upcomingHearings: state.upcomingHearings
});

export default connect(
  mapStateToProps
)(Dockets);

Dockets.propTypes = {
  veteranLawJudge: PropTypes.object.isRequired,
  upcomingHearings: PropTypes.object.isRequired
};
