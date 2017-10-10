import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import { onAddIssue } from '../actions/Issue';

import HearingWorksheetIssues from './HearingWorksheetIssues';

class HearingWorksheetStream extends Component {

  onAddIssue = (appealKey) => () => this.props.onAddIssue(appealKey, this.getVacolsSequenceId());

  getMaxVacolsSequenceId = () => {
    let maxValue = 0;
    this.props.worksheetStreams.forEach((appeal) => {
      appeal.worksheet_issues.forEach((issue) => {
        if (issue.vacols_sequence_id > maxValue) {
          maxValue = issue.vacols_sequence_id;
        }
      })
    });
    return maxValue;
  };

  getVacolsSequenceId = () => {
    return Number(this.getMaxVacolsSequenceId()) + 1;
  };

  render() {

    let {
      worksheetStreams
    } = this.props;

    return <div className="cf-hearings-worksheet-data">
          <h2 className="cf-hearings-worksheet-header">Issues</h2>
            {Object.keys(worksheetStreams).map((appeal, key) => {
                // Iterates over all appeals to create appeal streams inside worksheet
              let appealId = appeal;

              return <div key={appealId} id={appealId}>
              <p className="cf-appeal-stream-label">APPEAL STREAM <span>{key + 1}</span></p>
              <HearingWorksheetIssues
                appealKey={key}
                worksheetStreamsAppeal={this.props.worksheet.appeals_ready_for_hearing[key]}
                worksheetStreamsIssues={this.props.worksheet.appeals_ready_for_hearing[key].worksheet_issues}
                {...this.props}
              />
              <Button
                classNames={['usa-button-outline', 'hearings-add-issue']}
                name="+ Add Issue"
                id={`button-addIssue-${appealId}`}
                onClick={this.onAddIssue(key)}
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
