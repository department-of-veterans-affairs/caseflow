import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import Button from '../../components/Button';

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
                <Button
                classNames={['usa-button-outline']}
                name="+ Add Issue"
                onClick={this.addIssue}
              />
    </div>;
  }
}

const mapStateToProps = (state) => ({
  worksheetStreamsIssues: state.worksheet.streams[8873].issues
});

HearingWorksheetStream.propTypes = {
  worksheetStreamsIssues: PropTypes.object.isRequired
};

export default connect(
  mapStateToProps
)(HearingWorksheetStream);
