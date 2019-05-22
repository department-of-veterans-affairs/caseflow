import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import Button from '../../components/Button';
import TabWindow from '../../components/TabWindow';
import { onAddIssue } from '../actions/Issue';
import { filterIssuesOnAppeal, currentIssues, priorIssues } from '../util/IssuesUtil';
import { CATEGORIES, ACTIONS } from '../analytics';

import HearingWorksheetIssues from './HearingWorksheetIssues';

const PAST_ISSUES_TAB_INDEX = 1;

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

  getVacolsSequenceId = () => (this.getMaxVacolsSequenceId() + 1).toString();

  getIssues = (prior) => {
    let issueCount = 0;

    /* eslint-disable array-callback-return */
    return <div> {Object.values(this.props.worksheetAppeals).map((appeal, key) => {
    /* eslint-enable array-callback-return */

      const appealIssues = filterIssuesOnAppeal(this.props.worksheetIssues, appeal.id);

      let appealWorksheetIssues;

      if (prior) {
        appealWorksheetIssues = priorIssues(appealIssues);
      } else {
        appealWorksheetIssues = currentIssues(appealIssues);
      }

      const currentIssueCount = issueCount;

      issueCount += _.size(appealWorksheetIssues);

      if (_.size(appealWorksheetIssues)) {
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
            classNames={['usa-button-secondary', 'hearings-add-issue']}
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

  getCurrentIssuesCount = () => _.size(currentIssues(this.props.worksheetIssues));

  getPriorIssuesCount = () => _.size(priorIssues(this.props.worksheetIssues));

  issuesTabSelected = (tabIndex) => {
    if (tabIndex === PAST_ISSUES_TAB_INDEX) {
      window.analyticsEvent(CATEGORIES.HEARING_WORKSHEET_PAGE, ACTIONS.OPEN_PAST_ISSUES_TAB);
    }
  }

  render() {
    const tabs = [{
      label: `Current Issues (${this.getCurrentIssuesCount()})`,
      page: this.getIssues()
    }, {
      label: `Prior Issues (${this.getPriorIssuesCount()})`,
      page: this.getIssues(true),
      disable: !this.getPriorIssuesCount()
    }];

    return <div className="cf-hearings-worksheet-data">
      <TabWindow
        name="issues-tabwindow"
        tabs={tabs}
        onChange={this.issuesTabSelected}
      />
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onAddIssue
}, dispatch);

const mapStateToProps = (state) => ({
  worksheetAppeals: state.hearings.worksheetAppeals,
  worksheetIssues: state.hearings.worksheetIssues
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetStream);
