import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import DocketHearingRow from './DocketHearingRow';
import moment from 'moment';
import { Link } from 'react-router-dom';

export class DailyDocket extends React.Component {

  render() {
    const docket = this.props.docket;

    return <div>
      <div className="cf-app-segment cf-app-segment--alt cf-hearings">
        <div className="cf-title-meta-right">
          <div className="title cf-hearings-title-and-judge">
            <h1>Daily Docket</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
          <div className="meta">
            <div>{moment(docket[0].date).format('ddd l')}</div>
            <div>Hearing Type: {docket[0].request_type}</div>
          </div>
        </div>
        <table className="cf-hearings-docket">
          <thead>
            <tr>
              <th>Time/Regional Office</th>
              <th>Appellant/Veteran ID</th>
              <th>Representative</th>
              <th>
                Actions
              </th>
            </tr>
          </thead>
          {docket.map((hearing, index) =>
            <DocketHearingRow
              key={hearing.id}
              index={index}
              hearing={hearing}
              hearingDate={this.props.date}
            />
          )}
        </table>
      </div>
      <div className="cf-alt--actions cf-alt--app-width">
        <div className="cf-push-left">
          <Link to="/hearings/dockets">&lt; Back to Upcoming Hearing Days</Link>
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  dockets: state.dockets
});

export default connect(
  mapStateToProps
)(DailyDocket);

DailyDocket.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired
};
