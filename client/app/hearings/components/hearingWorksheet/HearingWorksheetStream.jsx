import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import Button from '../../../components/Button';
import TabWindow from '../../../components/TabWindow';
import { onAddIssue } from '../../actions/hearingWorksheetActions';
import HearingWorksheetIssues from './HearingWorksheetIssues';

class HearingWorksheetStream extends Component {

  filterIssuesOnAppeal = (issues, appealId) =>
    _(issues).
      omitBy('_destroy').
      pickBy({ appeal_id: appealId }).
      value();

  currentIssues = (issues) => {
    return _.omitBy(issues, (issue) => {
      /* eslint-disable no-underscore-dangle */
      return issue._destroy || (issue.disposition && !issue.disposition.includes('Remand') && issue.from_vacols);
      /* eslint-enable no-underscore-dangle */
    });
  };

  priorIssues = (issues) => (
    _.pickBy(issues, (issue) => (
      /* eslint-disable no-underscore-dangle */
      !issue._destroy && issue.disposition && !issue.disposition.includes('Remand') && issue.from_vacols
      /* eslint-enable no-underscore-dangle */
    ))
  );

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

      const appealIssues = this.filterIssuesOnAppeal(this.props.worksheetIssues, appeal.id);

      let appealWorksheetIssues;

      if (prior) {
        appealWorksheetIssues = this.priorIssues(appealIssues);
      } else {
        appealWorksheetIssues = this.currentIssues(appealIssues);
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

  getCurrentIssuesCount = () => _.size(this.currentIssues(this.props.worksheetIssues));

  getPriorIssuesCount = () => _.size(this.priorIssues(this.props.worksheetIssues));

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
      />
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onAddIssue
}, dispatch);

const mapStateToProps = (state) => ({
  worksheetAppeals: state.hearingWorksheet.worksheetAppeals,
  worksheetIssues: state.hearingWorksheet.worksheetIssues
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetStream);
