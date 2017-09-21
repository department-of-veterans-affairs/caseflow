import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import Table from '../components/Table';
import moment from 'moment';
import _ from 'lodash';
import { Link } from 'react-router-dom';

export class Dockets extends React.Component {

  getType = (type) => {
    return (type === 'central_office') ? 'CO' : type;
  }

  getStartTime = () => {
    const startTime = `${moment().
      add(_.random(0, 120), 'minutes').
      format('LT')} EST`;

    return startTime.replace('AM', 'a.m.').replace('PM', 'p.m.');
  }

  getKeyForRow = (index) => {
    return index;
  }

  masterRecord = (docket) => {
    return docket.hearings_array[0].master_record === true;
  };

  linkToDailyDocket = (docket) => {
    if (this.masterRecord(docket)) {
      return moment(docket.date).format('l');
    }

    return <Link to={`/hearings/dockets/${moment(docket.date).format('YYYY-MM-DD')}`}>
        {moment(docket.date).format('l')}
    </Link>;
  };

  render() {

    const docketIndex = Object.keys(this.props.dockets).sort();

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

      let docket = this.props.dockets[docketDate];

      return {
        date: this.linkToDailyDocket(docket),
        start_time: this.getStartTime(),
        type: this.getType(docket.type),
        regional_office: docket.regional_office_name,
        slots: _.random(8, 12),
        scheduled: docket.hearings_array.length
      };
    });

    return <div>
      <div className="cf-app-segment cf-app-segment--alt cf-hearings-schedule">
        <div className="cf-hearings-title-and-judge">
          <h1>Upcoming Hearing Days</h1>
          <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
        </div>
        <Table
          className="dockets"
          columns={columns}
          rowObjects={rowObjects}
          summary={'Upcoming Hearing Days?'}
          getKeyForRow={this.getKeyForRow}
        />
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  dockets: state.dockets
});

export default connect(
  mapStateToProps
)(Dockets);

Dockets.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  dockets: PropTypes.object.isRequired
};
