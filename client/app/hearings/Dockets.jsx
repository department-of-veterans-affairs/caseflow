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

  getType = (type) => {
    return (type === 'central_office') ? 'CO' : type;
  }

  getKeyForRow = (index) => {
    return index;
  }

  linkToDailyDocket = (docket) => {
    if (docket.master_record) {
      return moment(docket.date).format('ddd M/DD/YYYY');
    }

    return <Link to={`/hearings/dockets/${moment(docket.date).format('YYYY-MM-DD')}`}>
      {moment(docket.date).format('ddd M/DD/YYYY')}
    </Link>;
  }

  getScheduledCount = (docket) => {
    return (docket.master_record ? 0 : docket.hearings_count);
  }

  getRowObjects = (hearings) => {
    const docketIndex = Object.keys(hearings).sort();
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
    const pastRowObjects = this.getRowObjects(groupedHearings.past);

    const tabs = [
      {
        label: 'Upcoming',
        page: <Table
          className="hearings"
          columns={columns}
          rowObjects={upcomingRowObjects}
          summary="Your Upcoming Hearing Days?"
          getKeyForRow={this.getKeyForRow}
          styling={tableBorder}
          bodyStyling={tableBodyStyling}
        />
      },
      {
        label: 'Past',
        page: <Table
          className="hearings"
          columns={columns}
          rowObjects={pastRowObjects}
          summary="Your Past Hearing Days?"
          getKeyForRow={this.getKeyForRow}
          styling={tableBorder}
          bodyStyling={tableBodyStyling}
        />
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
