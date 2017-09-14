import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import HearingWorksheetIssues from './HearingWorksheetIssues';

class HearingWorksheetStream extends Component {

  render() {

    let {
     worksheetStreams
    } = this.props;

    return <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Issues</h2>

            {Object.keys(worksheetStreams).map((appeal, key) => {
                // Iterates over all apeals to create appeal streams inside worksheet
                // TODO line between appeals
              let appealId = appeal;

              return <div key={appealId} id={key + 1}>
              <p className="cf-appeal-stream-label">APPEAL STREAM <span>{key + 1}</span></p>
              <HearingWorksheetIssues
                worksheetStreamsIssues={this.props.worksheet.streams[appealId].issues}
                {...this.props}
              />
              </div>;
            })}
        </div>;
  }
}

const mapStateToProps = (state) => ({
  HearingWorksheetStream: state
});

HearingWorksheetStream.propTypes = {
  worksheetStreams: PropTypes.object.isRequired
};

export default connect(
  mapStateToProps
)(HearingWorksheetStream);

