import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import Table from '../components/Table';
import moment from 'moment';
import _ from 'lodash';

export class Dockets extends React.Component {

  getType = (type) => {
    return (type === 'central_office') ? 'CO' : type;
  }

  getStartTime = () => {
    let startTime = `${moment().
      add(_.random(0, 120), 'minutes').
      format('LT')} EST`;

    return startTime.replace('AM', 'a.m.').replace('PM', 'p.m.');
  }

  render() {
    let columns = [
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
        header: 'Field Office',
        valueName: 'field_office'
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

    let rowObjects = this.props.dockets.map((docket) => {
      return {
        date: moment(docket.date).format('l'),
        start_time: this.getStartTime(),
        type: this.getType(docket.type),
        field_office: `${docket.venue.city}, ${docket.venue.state} RO`,
        slots: _.random(8, 12),
        scheduled: docket.hearings.length
      };
    });

    return <div className="cf-hearings-schedule">
      <div className="cf-hearings-title-and-judge">
        <h1>Hearings Schedule</h1>
        <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
      </div>
      <Table className="dockets" columns={columns} rowObjects={rowObjects} summary={'Hearings Prep Schedule?'}/>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  veteran_law_judge: state.veteran_law_judge,
  dockets: state.dockets
});

const mapDispatchToProps = () => ({
  // TODO: pass dispatch into method and use it
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Dockets);

Dockets.propTypes = {
  veteran_law_judge: PropTypes.object,
  dockets: PropTypes.arrayOf(PropTypes.object)
};
