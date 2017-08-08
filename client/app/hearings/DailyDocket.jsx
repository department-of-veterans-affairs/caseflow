import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import DocketHearingRow from './DocketHearingRow';
import moment from 'moment';
import { Link } from 'react-router-dom';
import { setNotes, setDisposition, setHoldOpen, setAOD, setTranscriptRequested } from './actions/Dockets';

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
              <th>Appellant</th>
              <th>Representative</th>
              <th>
                <span>Actions</span>
                <span className="saving">Last saved at 10:30am</span>
              </th>
            </tr>
          </thead>
          {docket.map((hearing, index) =>
            <DocketHearingRow key={index}
              index={index}
              hearing={hearing}
              hearingDate={this.props.date}
              setNotes={this.props.setNotes}
              setDisposition={this.props.setDisposition}
              setHoldOpen={this.props.setHoldOpen}
              setAOD={this.props.setAOD}
              setTranscriptRequested={this.props.setTranscriptRequested}
            />
          )}
        </table>
      </div>
      <div className="cf-alt--actions cf-alt--app-width">
        <div className="cf-push-left">
          <Link to="/hearings/dockets">&lt; Back to Dockets</Link>
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  dockets: state.dockets
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setNotes,
  setDisposition,
  setHoldOpen,
  setAOD,
  setTranscriptRequested
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DailyDocket);

DailyDocket.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired
};
