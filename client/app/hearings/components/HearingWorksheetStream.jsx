import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import HearingWorksheetIssues from './HearingWorksheetIssues';

class HearingWorksheetStream extends Component {

  render() {

    let {
     worksheetStreamsIssues
    } = this.props;

    return <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Issues</h2>
          <p className="cf-appeal-stream-label">APPEAL STREAM 01</p>
            <HearingWorksheetIssues
              worksheetStreamsIssues={worksheetStreamsIssues}
              {...this.props}
            />
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheetStreamsIssues: state.worksheet.streams.appeal_0.issues.issue_0
});

HearingWorksheetStream.propTypes = {
  worksheetStreamsIssues: PropTypes.object.isRequired
};

export default connect(
  mapStateToProps
)(HearingWorksheetStream);

