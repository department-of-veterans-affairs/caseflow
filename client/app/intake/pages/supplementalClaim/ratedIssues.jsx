import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setIssueSelected } from '../../actions/supplementalClaim';
import Checkbox from '../../../components/Checkbox';
import { formatDateStr } from '../../../util/DateUtil';
import _ from 'lodash';

class RatedIssues extends React.PureComponent {
  onCheckIssue = (profileDate, issueId) => (checked) => this.props.setIssueSelected(profileDate, issueId, checked)

  render() {

    const { supplementalClaim } = this.props;

    const ratedIssuesSections = _.map(supplementalClaim.ratings, (rating) => {
      const ratedIssueCheckboxes = _.map(rating.issues, (issue) => {
        return (
          <Checkbox
            label={issue.decision_text}
            name={issue.rba_issue_id}
            key={issue.rba_issue_id}
            value={issue.isSelected}
            onChange={this.onCheckIssue(rating.profile_date, issue.rba_issue_id)}
            unpadded
          />
        );
      });

      return (<div className="cf-intake-ratings" key={rating.profile_date}>
        <h3>
          Decision date: { formatDateStr(rating.promulgation_date) }
        </h3>

        { ratedIssueCheckboxes }
      </div>
      );
    });

    return <div>
      { ratedIssuesSections }
    </div>;
  }
}

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
