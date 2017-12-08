import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import Button from '../../components/Button';
import { onAddIssue } from '../actions/Issue';
import { filterIssuesOnAppeal } from '../util/IssuesUtil';

import HearingWorksheetIssues from './HearingWorksheetIssues';

class HearingWorksheetStream extends Component {

  onAddIssue = (appealId) => () => this.props.onAddIssue(appealId, this.getVacolsSequenceId());

  getMaxVacolsSequenceId = () => {
    let maxValue = 0;

    _.forEach(this.props.worksheetIssues, (issue) => {
      if (Number(issue.vacols_sequence_id) > maxValue) {
        maxValue = Number(issue.vacols_sequence_id);
      }
    });

    return maxValue;
  };

  getVacolsSequenceId = () => {
    return (this.getMaxVacolsSequenceId() + 1).toString();
  };

  render() {

    let {
      worksheetAppeals,
      worksheetIssues
    } = this.props;

    let issueCount = 0;

    return <div className="cf-hearings-worksheet-data">
      {Object.values(worksheetAppeals).map((appeal, key) => {

        const appealWorksheetIssues = filterIssuesOnAppeal(worksheetIssues, appeal.id);
        const currentIssueCount = issueCount;

        issueCount += _.size(appealWorksheetIssues);

        return <div key={appeal.id} id={appeal.id}>
          <h2 className="cf-hearings-worksheet-header">Appeal Stream <span>{key + 1}</span></h2>
          <HearingWorksheetIssues
            appealKey={key}
            worksheetStreamsAppeal={appeal}
            print={this.props.print}
            {...this.props}
            countOfIssuesInPreviousAppeals={currentIssueCount}
          />
          {!this.props.print &&
            <Button
              classNames={['usa-button-outline', 'hearings-add-issue']}
              name="+ Add Issue"
              id={`button-addIssue-${appeal.id}`}
              onClick={this.onAddIssue(appeal.id)}
            />
          }
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
  worksheetAppeals: state.worksheetAppeals,
  worksheetIssues: state.worksheetIssues
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetStream);
