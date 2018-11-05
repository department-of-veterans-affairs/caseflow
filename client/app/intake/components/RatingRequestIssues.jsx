import React from 'react';
import Checkbox from '../../components/Checkbox';
import { formatDateStr } from '../../util/DateUtil';
import _ from 'lodash';

export default class RatingRequestIssuesUnconnected extends React.PureComponent {
  onCheckIssue = (profileDate, issueId) => (checked) => this.props.setIssueSelected(profileDate, issueId, checked)

  render() {

    const { ratings } = this.props;

    const veteranHasNoRatings = _.isEmpty(ratings);

    const noRatingRequestIssuesMessage = 'This Veteran has no rated, disability issues within the one-year timeframe ' +
    'for requesting a review. If the Veteran listed non-rated issues, add them below. Otherwise, cancel the ' +
    'intake and follow your standard operating procedures for notifying the Veteran.';

    const ratingRequestIssuesSections = _.map(ratings, (rating) => {
      const ratingRequestIssueCheckboxes = _.map(rating.issues, (issue) => {
        return (
          <Checkbox
            label={issue.decision_text}
            name={issue.reference_id}
            key={issue.reference_id}
            value={issue.isSelected || false}
            onChange={this.onCheckIssue(rating.profile_date, issue.reference_id)}
            unpadded
          />
        );
      });

      return (<div className="cf-intake-ratings" key={rating.profile_date}>
        <h3>
          Decision date: { formatDateStr(rating.profile_date) }
        </h3>

        { ratingRequestIssueCheckboxes }
      </div>
      );
    });

    return <div>
      <h2>Select from previous decision issues</h2>
      { veteranHasNoRatings ? noRatingRequestIssuesMessage : ratingRequestIssuesSections }
    </div>;
  }
}
