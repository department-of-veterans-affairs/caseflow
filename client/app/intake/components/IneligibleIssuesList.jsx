import React, { Fragment } from 'react';
import INELIGIBLE_REQUEST_ISSUES from '../../../constants/INELIGIBLE_REQUEST_ISSUES.json';

const ineligibilityCopy = (issue) => {
  if (issue.titleOfActiveReview) {
    return INELIGIBLE_REQUEST_ISSUES.duplicate_of_rating_issue_in_active_review.replace(
      '{review_title}', issue.titleOfActiveReview
    );
  } else if (issue.ineligibleReason) {
    return INELIGIBLE_REQUEST_ISSUES[issue.ineligibleReason];
  }
};

export default class IneligibleIssuesList extends React.PureComponent {
  render = () =>
    <Fragment>
      <ul className="cf-issue-checklist cf-left-padding">
        <li>
          <strong>Ineligible</strong>
          {this.props.issues.map((ri, i) =>
            <p key={`ineligible-issue-${i}`} className="cf-red-text">
              {ri.contentionText} {ineligibilityCopy(ri)}
            </p>)}
        </li>
      </ul>
    </Fragment>;
}
