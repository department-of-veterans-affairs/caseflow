import React, { Component } from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import Button from '../../../components/Button';
import TabWindow from '../../../components/TabWindow';
import { filterCurrentIssues, filterPriorIssues, filterIssuesOnAppeal } from '../../utils';
import { onAddIssue } from '../../actions/hearingWorksheetActions';
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

  getVacolsSequenceId = () => (this.getMaxVacolsSequenceId() + 1).toString();

  getIssues = (prior) => {
    let issueCount = 0;

    return (
      <div>
        {
          Object.values(this.props.worksheetAppeals).map((appeal, key) => {
            const appealIssues = filterIssuesOnAppeal(this.props.worksheetIssues, appeal.id);
            const appealWorksheetIssues = prior ? filterPriorIssues(appealIssues) : filterCurrentIssues(appealIssues);
            const currentIssueCount = issueCount;

            issueCount += _.size(appealWorksheetIssues);

            if (_.size(appealWorksheetIssues)) {
              return <div key={appeal.id} id={appeal.id}>
                <HearingWorksheetIssues
                  appealKey={key}
                  issues={appealWorksheetIssues}
                  worksheetStreamsAppeal={appeal}
                  {...this.props}
                  countOfIssuesInPreviousAppeals={currentIssueCount}
                  prior={prior}
                />
                {!prior &&
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

            return null;

          })
        }
      </div>
    );
  };

  getCurrentIssuesCount = () => _.size(filterCurrentIssues(this.props.worksheetIssues));

  getPriorIssuesCount = () => _.size(filterPriorIssues(this.props.worksheetIssues));

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
