import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import Button from '../../components/Button';
import TabWindow from '../../components/TabWindow';
import { onAddIssue } from '../actions/Issue';
import { filterIssuesOnAppeal, currentIssues, priorIssues } from '../util/IssuesUtil';

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

  getIssues = (prior) => {
    let issueCount = 0;

    return <div> {Object.values(this.props.worksheetAppeals).map((appeal, key) => {

      let appealWorksheetIssues = currentIssues(filterIssuesOnAppeal(this.props.worksheetIssues, appeal.id));

      if (prior) {
        appealWorksheetIssues = priorIssues(filterIssuesOnAppeal(this.props.worksheetIssues, appeal.id));
      }

      const currentIssueCount = issueCount;

      issueCount += _.size(appealWorksheetIssues);

      if (_.size(appealWorksheetIssues) > 0) {
        return <div key={appeal.id} id={appeal.id}>
          <HearingWorksheetIssues
            appealKey={key}
            issues={appealWorksheetIssues}
            worksheetStreamsAppeal={appeal}
            print={this.props.print}
            {...this.props}
            countOfIssuesInPreviousAppeals={currentIssueCount}
            prior={prior}
          />
          {!this.props.print && !prior &&
          <Button
            classNames={['usa-button-outline', 'hearings-add-issue']}
            name="+ Add Issue"
            id={`button-addIssue-${appeal.id}`}
            onClick={this.onAddIssue(appeal.id)}
          />
          }
          <div className="cf-help-divider" />
        </div>;
      }
    })}
    </div>;
  };

  getCurrentIssuesCount = () => {
    return _.size(currentIssues(this.props.worksheetIssues));
  };

  getPriorIssuesCount = () => {
    return _.size(priorIssues(this.props.worksheetIssues));
  };

  render() {
    const tabs = [{
      label: `Current Issues (${this.getCurrentIssuesCount()})`,
      page: this.getIssues()
    }, {
      label: `Prior Issues (${this.getPriorIssuesCount()})`,
      page: this.getIssues(true)
    }];

    return <div className="cf-hearings-worksheet-data">
      <TabWindow
        name="issues-tabwindow"
        tabs={tabs}
      />
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
