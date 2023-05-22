import React from 'react';
import PropTypes from 'prop-types';

import { filter, find } from 'lodash';

import INELIGIBLE_REQUEST_ISSUES from '../../../constants/INELIGIBLE_REQUEST_ISSUES';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import COPY from '../../../COPY';

import { legacyIssue } from '../util/issues';
import { formatDateStr } from '../../util/DateUtil';
import { CORRECTION_TYPE_OPTIONS } from '../constants';

class AddedIssue extends React.PureComponent {
  needsEligibilityCheck() {
    const { issue, requestIssues } = this.props;

    if (!requestIssues) {
      return true;
    }
    if (issue.ineligibleReason) {
      return true;
    }

    const existingRequestIssue = issue.id && filter(requestIssues, { id: parseInt(issue.id, 10) })[0];

    if (existingRequestIssue && !existingRequestIssue.ineligible_reason) {
      return false;
    }

    return true;
  }

  getEligibility() {
    let errorMsg = '';
    const { issue, formType, legacyOptInApproved } = this.props;
    const cssKlassesWithError = ['issue-desc', 'not-eligible'];
    const legacyIssueEligibleWithExemption = issue.eligibleForSocOptInWithExemption && issue.untimelyExemptionCovid;

    if (
      issue.titleOfActiveReview ||
      (issue.decisionReviewTitle && issue.ineligibleReason === 'duplicate_of_nonrating_issue_in_active_review')
    ) {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.duplicate_of_rating_issue_in_active_review.replace(
        '{review_title}',
        issue.titleOfActiveReview || issue.decisionReviewTitle
      );
    } else if (issue.ineligibleReason) {
      errorMsg = INELIGIBLE_REQUEST_ISSUES[issue.ineligibleReason];
    } else if (
      issue.timely === false &&
      formType !== 'supplemental_claim' &&
      issue.untimelyExemption !== 'true' &&
      !issue.vacolsId
    ) {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.untimely;
    } else if (formType === 'higher_level_review' && issue.sourceReviewType === 'HigherLevelReview') {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.higher_level_review_to_higher_level_review;
    } else if (formType === 'higher_level_review' && issue.sourceReviewType === 'Appeal') {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.appeal_to_higher_level_review;
    } else if (formType === 'appeal' && issue.sourceReviewType === 'Appeal') {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.appeal_to_appeal;
    } else if (issue.vacolsId) {
      if (!legacyOptInApproved) {
        errorMsg = INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn;
      } else if (!issue.eligibleForSocOptIn && !legacyIssueEligibleWithExemption) {
        errorMsg = INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible;
      }
    } else if (issue.beforeAma && formType !== 'supplemental_claim') {
      errorMsg = INELIGIBLE_REQUEST_ISSUES.before_ama;
    }

    if (errorMsg !== '') {
      return { errorMsg, cssKlasses: cssKlassesWithError };
    }
  }

  getCorrectionType = (issue) => {
    const correction = find(CORRECTION_TYPE_OPTIONS, (opt) => opt.value === issue.correctionType);

    return correction ? `This issue will be added to a 930 ${correction.displayText} EP for correction` : '';
  };

  render() {
    const { issue, issueIdx, legacyAppeals } = this.props;

    let eligibleState = {
      errorMsg: '',
      cssKlasses: ['issue-desc']
    };

    const vacolsIssue = legacyIssue(issue, legacyAppeals);

    if (this.needsEligibilityCheck()) {
      let eligibilityCheck = this.getEligibility();

      if (eligibilityCheck) {
        eligibleState = eligibilityCheck;
      }
    }

    if (issue.isUnidentified) {
      eligibleState.cssKlasses.push('issue-unidentified');
    }

    if (issue.withdrawalPending || issue.withdrawalDate) {
      eligibleState.cssKlasses.push('withdrawn-issue');
    }

    return (
      <div className={eligibleState.cssKlasses.join(' ')}>
        <span className="issue-num">{issueIdx + 1}.&nbsp;</span>
        {issue.editedDescription ? issue.editedDescription : issue.text} {eligibleState.errorMsg}
        {issue.editedDescription && (
          <div>
            <em>(Originally: {issue.text})</em>
          </div>
        )}
        {issue.benefitType && <span className="issue-date">Benefit type: {BENEFIT_TYPES[issue.benefitType]}</span>}
        {issue.date && <span className="issue-date">Decision date: {formatDateStr(issue.date)}</span>}
        {issue.notes && <span className="issue-notes">Notes:&nbsp;{issue.notes}</span>}
        {issue.untimelyExemptionNotes && (
          <span className="issue-notes">Untimely Exemption Notes:&nbsp;{issue.untimelyExemptionNotes}</span>
        )}
        {vacolsIssue && !eligibleState.errorMsg && (
          <div className="issue-vacols">
            <span className="msg">
              {issue.id ? COPY.VACOLS_OPTIN_ISSUE_CLOSED_EDIT : COPY.VACOLS_OPTIN_ISSUE_NEW}:
            </span>
            <span className="desc">{vacolsIssue.description}</span>
          </div>
        )}
        {issue.withdrawalPending && <p>Withdrawal pending</p>}
        {issue.withdrawalDate && <p>Withdrawn on {formatDateStr(issue.withdrawalDate)}</p>}
        {issue.endProductCleared && <p>Status: Cleared, waiting for decision</p>}
        {issue.correctionType && <p className="correction-pending">{this.getCorrectionType(issue)}</p>}
        {issue.examRequested && <p className="added-issue-note">{COPY.INTAKE_CONTENTION_HAS_EXAM_REQUESTED}</p>}
      </div>
    );
  }
}

AddedIssue.propTypes = {
  formType: PropTypes.string.isRequired,
  issue: PropTypes.shape({
    beforeAma: PropTypes.bool,
    benefitType: PropTypes.string,
    correctionType: PropTypes.string,
    date: PropTypes.string,
    decisionReviewTitle: PropTypes.string,
    editedDescription: PropTypes.string,
    eligibleForSocOptIn: PropTypes.bool,
    eligibleForSocOptInWithExemption: PropTypes.bool,
    examRequested: PropTypes.bool,
    untimelyExemptionCovid: PropTypes.bool,
    endProductCleared: PropTypes.bool,
    ineligibleReason: PropTypes.string,
    isUnidentified: PropTypes.bool,
    notes: PropTypes.string,
    ratingDecisionReferenceId: PropTypes.string,
    ratingIssueReferenceId: PropTypes.string,
    id: PropTypes.string,
    sourceReviewType: PropTypes.string,
    text: PropTypes.string,
    timely: PropTypes.bool,
    titleOfActiveReview: PropTypes.string,
    untimelyExemption: PropTypes.string,
    untimelyExemptionNotes: PropTypes.string,
    vacolsId: PropTypes.string,
    withdrawalPending: PropTypes.string,
    withdrawalDate: PropTypes.string
  }).isRequired,
  issueIdx: PropTypes.number.isRequired,
  legacyAppeals: PropTypes.array,
  legacyOptInApproved: PropTypes.bool.isRequired,
  requestIssues: PropTypes.array
};

export default AddedIssue;
