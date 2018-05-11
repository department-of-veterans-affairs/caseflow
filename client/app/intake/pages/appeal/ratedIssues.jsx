import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setIssueSelected } from '../../actions/common';
import Checkbox from '../../../components/Checkbox';
import { formatDateStr } from '../../../util/DateUtil';
import _ from 'lodash';

class RatedIssues extends React.PureComponent {
  onCheckIssue = (profileDate, issueId) => (checked) => this.props.setIssueSelected(profileDate, issueId, checked)

  render() {

    const { appeal } = this.props;

    const ratedIssuesSections = _.map(appeal.ratings, (rating) => {
      const ratedIssueCheckboxes = _.map(rating.issues, (issue) => {
        return (
          <Checkbox
            label={issue.decision_text}
            name={issue.reference_id}
            key={issue.reference_id}
            value={issue.isSelected}
            onChange={this.onCheckIssue(rating.profile_date, issue.reference_id)}
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
  ({ appeal, intake }) => ({
    intakeId: intake.id,
    appeal
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected
  }, dispatch)
)(RatedIssues);

export default RatedIssuesConnected;
