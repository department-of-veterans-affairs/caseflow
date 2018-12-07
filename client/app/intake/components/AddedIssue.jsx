import _ from 'lodash';
import React from 'react';

import INELIGIBLE_REQUEST_ISSUES from '../../../constants/INELIGIBLE_REQUEST_ISSUES.json';

import { legacyIssue } from '../util/issues';

class AddedIssue extends React.PureComponent {
  needsEligibilityCheck() {
    let { issue, requestIssues } = this.props;

    if (!requestIssues) {
      return false;
    }
    if (issue.ineligibleReason) {
      return true;
    }

    let existingRequestIssue = _.filter(requestIssues, { reference_id: issue.referenceId })[0];

    // leaving this here to make it easier to debug in future.
    // console.log('existingRequestIssue', existingRequestIssue);

    if (existingRequestIssue && !existingRequestIssue.ineligible_reason) {
      return false;
    }

    return true;
  }

  getEligibility() {
    let { issue, formType, legacyOptInApproved } = this.props;

    // console.log('getEligibility', formType, issue, legacyOptInApproved);

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
    } else if (issue.timely === false &&
               formType !== 'supplemental_claim' &&
               issue.untimelyExemption !== 'true' &&
               !issue.vacolsId
    ) {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.untimely;
    } else if (issue.sourceHigherLevelReview && formType === 'higher_level_review') {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.previous_higher_level_review;
    } else if (issue.beforeAma && !issue.vacolsId) {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.before_ama;
    } else if (issue.vacolsId) {
      if (!legacyOptInApproved) {
        errorMsg = INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn;
      } else if (!issue.eligibleForSocOptIn) {
        errorMsg = INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible;
      }
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

    // console.log('needsEligibilityCheck', issue, this.needsEligibilityCheck());

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
      { issue.vacolsId && !eligibleState.errorMsg &&
        <div className="issue-vacols">
          <span className="msg">{ INELIGIBLE_REQUEST_ISSUES.adding_this_issue_vacols_optin }:</span>
          <span className="desc">{ legacyIssue(issue, this.props.legacyAppeals).description }</span>
        </div>
      }
    </div>;
  }

}

export default AddedIssue;
