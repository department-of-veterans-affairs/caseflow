import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { onAddIssue } from '../actions/Issue';

import HearingWorksheetIssues from './HearingWorksheetIssues';

class HearingWorksheetStream extends Component {

  onAddIssue = (key) => this.props.onAddIssue(key);

  render() {

    let {
     worksheetStreams
    } = this.props;

    return <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Issues</h2>
            {Object.keys(worksheetStreams).map((appeal, key) => {
                // Iterates over all apeals to create appeal streams inside worksheet
              let appealId = appeal;

              return <div key={appealId} id={appealId}>
              <p className="cf-appeal-stream-label">APPEAL STREAM <span>{key + 1}</span></p>
              <HearingWorksheetIssues
                appealKey={key}
                worksheetStreamsAppeal={this.props.worksheet.streams[key]}
                worksheetStreamsIssues={this.props.worksheet.streams[key].worksheet_issues}
                {...this.props}
              />
              <Button
              classNames={['usa-button-outline', 'hearings-add-issue']}
              name="+ Add Issue"
              id={`button-addIssue-${appealId}`}
              onClick={this.onAddIssue}
              />
              <hr />
              </div>;
            })}
        </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onAddIssue
}, dispatch);

const mapStateToProps = (state) => ({
  HearingWorksheetStream: state
});

HearingWorksheetStream.propTypes = {
  worksheetStreams: PropTypes.array.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetStream);
