import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import Table from '../components/Table';
import moment from 'moment';
import { Link } from 'react-router-dom';
import { getDateTime } from './util/DateUtil';
import PrimaryAppContent from '../components/PrimaryAppContent';
export class Dockets extends React.Component {

  getType = (type) => {
    return (type === 'central_office') ? 'CO' : type;
  }

  getKeyForRow = (index) => {
    return index;
  }

  linkToDailyDocket = (docket) => {
    if (docket.master_record) {
      return moment(docket.date).format('l');
    }

    return <Link to={`/hearings/dockets/${moment(docket.date).format('YYYY-MM-DD')}`}>
      {moment(docket.date).format('l')}
    </Link>;
  }

  getScheduledCount = (docket) => {
    return (docket.master_record ? 0 : docket.hearings_count);
  }

  render() {

    const docketIndex = Object.keys(this.props.upcomingHearings).sort();

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

    const rowObjects = docketIndex.map((docketDate) => {

      let docket = this.props.upcomingHearings[docketDate];

      return {
        date: this.linkToDailyDocket(docket),
        start_time: getDateTime(docket.date),
        type: this.getType(docket.type),
        regional_office: docket.regional_office_name,
        slots: docket.slots,
        scheduled: this.getScheduledCount(docket)
      };
    });

    return <PrimaryAppContent extraClassNames="cf-hearings-schedule">
      <div className="cf-hearings-title-and-judge">
        <h1>Your Hearing Days</h1>
        <span>VLJ: {this.props.veteranLawJudge.full_name}</span>
      </div>
      <Table
        className="dockets"
        columns={columns}
        rowObjects={rowObjects}
        summary="Your Hearing Days?"
        getKeyForRow={this.getKeyForRow}
      />
    </PrimaryAppContent>;
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
