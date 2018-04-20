import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setIssueSelected } from '../../actions/supplementalClaim';
import Checkbox from '../../../components/Checkbox';

class RatedIssues extends React.PureComponent {
  onCheckIssue = (issueId) => (checked) => this.props.setIssueSelected(issueId, checked)

  render() {
    const ratedIssuesData = [
      {
        rba_issue_id: '123',
        decision_date: '01/28/2018',
        decision_text: 'I am a rated issue'
      },
      {
        rba_issue_id: '456',
        decision_date: '01/28/2018',
        decision_text: 'I am another rated issue'
      },
      {
        rba_issue_id: '789',
        decision_date: '02/28/2018',
        decision_text: 'I am a rated issue on a different date'
      }
    ];

    const ratedIssuesByDecisionDate = _.groupBy(ratedIssuesData, 'decision_date');

    const ratedIssuesSections = _.map(ratedIssuesByDecisionDate, (dateWithIssues) => {
      const ratedIssueCheckboxes = _.map(dateWithIssues, (issue) => {
        return (
          <Checkbox
            label={issue.decision_text}
            name={issue.rba_issue_id}
            key={issue.rba_issue_id}
            onChange={this.onCheckIssue(issue.rba_issue_id)}
          />
        )
      });

      return (<div key={dateWithIssues[0].rba_issue_id}>
        <p key={dateWithIssues[0].rba_issue_id}>
          Decision date: { dateWithIssues[0].decision_date }
        </p>

        { ratedIssueCheckboxes }
      </div>
      );
    })

    return <div>
      { ratedIssuesSections }
    </div>;
  }
};

const RatedIssuesConnected = connect(
  ({ supplementalClaim, intake }) => ({
    intakeId: intake.id,
    supplementalClaim
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected
  }, dispatch)
)(RatedIssues);

export default RatedIssuesConnected;
