import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import DocketHearingRow from './components/DocketHearingRow';
import moment from 'moment';
import { Link } from 'react-router-dom';
import PrimaryAppContent from '../components/PrimaryAppContent';

export class DailyDocket extends React.Component {

  render() {
    const docket = this.props.docket;

    return <div>
      <PrimaryAppContent>
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
      </PrimaryAppContent>
      <div className="cf-alt--actions">
        <div className="cf-push-left">
          <Link to="/hearings/dockets">&lt; Back to Your Hearing Days</Link>
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
