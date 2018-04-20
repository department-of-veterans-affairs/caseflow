import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setIssueSelected } from '../../actions/supplementalClaim';
import Checkbox from '../../../components/Checkbox';

class RatedIssues extends React.PureComponent {
  onCheckIssue = (issueId) => (checked) => this.props.setIssueSelected(issueId, checked)

  render() {

    const { supplementalClaim } = this.props

    const ratedIssuesSections = _.map(supplementalClaim.ratings, (rating) => {
      const ratedIssueCheckboxes = _.map(rating.issues, (issue) => {
        return (
          <Checkbox
            label={issue.decision_text}
            name={issue.rba_issue_id}
            key={issue.rba_issue_id}
            onChange={this.onCheckIssue(issue.rba_issue_id)}
          />
        )
      });

      return (<div key={rating.profile_date}>
        <p>
          Decision date: { rating.promulgation_date }
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
