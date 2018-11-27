import _ from 'lodash';
import React from 'react';

import INELIGIBLE_REQUEST_ISSUES from '../../../constants/INELIGIBLE_REQUEST_ISSUES.json';

class AddedIssue extends React.PureComponent {
  needsEligibilityCheck() {
    let { issue, requestIssues } = this.props;

    if (!requestIssues) {
      return false;
    }
    if (issue.ineligibleReason) {
      return true;
    }

    let existingRequestIssue = _.some(requestIssues, { reference_id: issue.referenceId });

    if (existingRequestIssue) {
      return false;
    }

    return true;
  }

  getEligibility() {
    let { issue, formType } = this.props;

    let errorMsg = '';
    const cssKlassesWithError = ['issue-desc', 'not-eligible'];

    if (issue.isUnidentified) {
      return { errorMsg,
        cssKlasses: cssKlassesWithError.concat(['issue-unidentified']) };
    }

    if (issue.titleOfActiveReview) {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.duplicate_of_issue_in_active_review.replace(
        '{review_title}', issue.titleOfActiveReview
      );
    } else if (issue.ineligibleReason) {
      errorMsg = INELIGIBLE_REQUEST_ISSUES[issue.ineligibleReason];
    } else if (issue.timely === false && formType !== 'supplemental_claim' && issue.untimelyExemption !== 'true') {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.untimely;
    } else if (issue.sourceHigherLevelReview && formType === 'higher_level_review') {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.previous_higher_level_review;
    } else if (issue.beforeAma) {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.before_ama;
    }

    if (errorMsg !== '') {
      return { errorMsg,
        cssKlasses: cssKlassesWithError };
    }
  }

  render() {
    let { issue, issueIdx } = this.props;
    let eligibleState = {
      errorMsg: '',
      cssKlasses: ['issue-desc']
    };

    if (this.needsEligibilityCheck()) {
      let eligibilityCheck = this.getEligibility();

      if (eligibilityCheck) {
        eligibleState = eligibilityCheck;
      }
    }

    return <div className={eligibleState.cssKlasses.join(' ')}>
      <span className="issue-num">{issueIdx + 1}.&nbsp;</span>
      { issue.text } {eligibleState.errorMsg}
      { issue.date && <span className="issue-date">Decision date: { issue.date }</span> }
      { issue.notes && <span className="issue-notes">Notes:&nbsp;{ issue.notes }</span> }
      { issue.untimelyExemptionNotes &&
        <span className="issue-notes">Untimely Exemption Notes:&nbsp;{issue.untimelyExemptionNotes}</span>
      }
    </div>;
  }

}

export default AddedIssue;
