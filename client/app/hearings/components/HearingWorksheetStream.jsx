import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import Button from '../../components/Button';
import { onAddIssue } from '../actions/Issue';

import HearingWorksheetIssues from './HearingWorksheetIssues';

class HearingWorksheetStream extends Component {

  onAddIssue = (appealId) => () => this.props.onAddIssue(appealId, this.getVacolsSequenceId());

  getMaxVacolsSequenceId = () => {
    let maxValue = 0;

    _.forEach(this.props.worksheetIssues, (issue) => {
      if (issue.vacols_sequence_id > maxValue) {
        maxValue = issue.vacols_sequence_id;
      }
    });

    return maxValue;
  };

  getVacolsSequenceId = () => {
    return this.getMaxVacolsSequenceId() + 1;
  };

  render() {

    let {
      worksheetAppeals
    } = this.props;

    return <div className="cf-hearings-worksheet-data">
      <h2 className="cf-hearings-worksheet-header">Issues</h2>
      {Object.values(worksheetAppeals).map((appeal, key) => {

        return <div key={appeal.id} id={appeal.id}>
          <p className="cf-appeal-stream-label">APPEAL STREAM <span>{key + 1}</span></p>
          <HearingWorksheetIssues
            appealKey={key}
            worksheetStreamsAppeal={appeal}
            {...this.props}
          />
          <Button
            classNames={['usa-button-outline', 'hearings-add-issue']}
            name="+ Add Issue"
            id={`button-addIssue-${appeal.id}`}
            onClick={this.onAddIssue(appeal.id)}
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
  worksheetAppeals: state.worksheetAppeals
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetStream);
