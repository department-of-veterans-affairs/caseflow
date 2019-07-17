import React from 'react';
import COPY from '../../../../COPY.json';
import { FORM_TYPES } from '../../constants';
import AddedIssue from '../AddedIssue';
import Button from '../../../components/Button';
import Dropdown from '../../../components/Dropdown';
import EditContentionTitle from '../../components/EditContentionTitle';

export const RequestedIssues = ({issues, intakeData, formType, onClickIssueAction, featureToggles}) => {
  const issueActionOptions = [
    { displayText: 'Withdraw issue', value: 'withdraw' },
    { displayText: 'Remove issue', value: 'remove' }
  ];

  const {
    withdrawDecisionReviews,
    editContentionText
  } = featureToggles

  return <div className="issues">
    <div>
      { issues.map((issue) => {
        const editableContentionText = Boolean(
          formType !== FORM_TYPES.APPEAL.key && !issue.category && !issue.ineligibleReason);

        return <div className="issue-container" key={`issue-container-${issue.index}`}>
          <div
            className="issue"
            data-key={`issue-${issue.index}`}
            key={`issue-${issue.index}`}
            id={`issue-${issue.referenceId}`}>
            <AddedIssue
              issue={issue}
              issueIdx={issue.index}
              requestIssues={intakeData.requestIssues}
              legacyOptInApproved={intakeData.legacyOptInApproved}
              legacyAppeals={intakeData.legacyAppeals}
              formType={formType} />
            <div className="issue-action">
              { withdrawDecisionReviews && <Dropdown
                name={`issue-action-${issue.index}`}
                label="Actions"
                hideLabel
                options={issueActionOptions}
                defaultText="Select action"
                onChange={(option) => onClickIssueAction(issue.index, option)}
              />
              }
              { !withdrawDecisionReviews && <Button
                onClick={() => onClickIssueAction(issue.index)}
                classNames={['cf-btn-link', 'remove-issue']}
              >
                <i className="fa fa-trash-o" aria-hidden="true"></i><br />Remove
              </Button>
              }
            </div>
          </div>
          {editContentionText && editableContentionText && <EditContentionTitle
            issue= {issue}
            issueIdx={issue.index} />}
        </div>;
      })}
    </div>
  </div>;
};

export const WithdrawnIssues = ({withdrawReview, issues, intakeData, formType}) => {
  return <div className="issues">
    { withdrawReview && <p className="cf-red-text">{COPY.INTAKE_WITHDRAWN_BANNER}</p> }
    { issues.map((issue) => {
      return <div
        className="issue"
        data-key={`issue-${issue.index}`}
        key={`issue-${issue.index}`}
        id={`issue-${issue.referenceId}`}>
        <AddedIssue
          issue={issue}
          issueIdx={issue.index}
          requestIssues={intakeData.requestIssues}
          legacyOptInApproved={intakeData.legacyOptInApproved}
          legacyAppeals={intakeData.legacyAppeals}
          formType={formType} />
      </div>;
    })}
  </div>;
}

export const ClearedIssues = ({issues, intakeData, formType, onClickIssueAction}) => {
  return <div className="issues">
    { issues.map((issue) => {
      return <div
        className="issue"
        data-key={`issue-${issue.index}`}
        key={`issue-${issue.index}`}
        id={`issue-${issue.referenceId}`}>
        <AddedIssue
          issue={issue}
          issueIdx={issue.index}
          requestIssues={intakeData.requestIssues}
          legacyOptInApproved={intakeData.legacyOptInApproved}
          legacyAppeals={intakeData.legacyAppeals}
          formType={formType} />
        <Button
          onClick={() => onClickIssueAction(issue.index, 'correct')}
          classNames={['cf-btn-link']}
        >
          Correct issue
        </Button>
      </div>;
    })}
  </div>;
};

export const CorrectionIssues = ({issues, intakeData, formType, onClickIssueAction}) => {
  return <div className="issues">
    { issues.map((issue) => {
      return <div
        className="issue"
        data-key={`issue-${issue.index}`}
        key={`issue-${issue.index}`}
        id={`issue-${issue.referenceId}`}>
        <AddedIssue
          issue={issue}
          issueIdx={issue.index}
          requestIssues={intakeData.requestIssues}
          legacyOptInApproved={intakeData.legacyOptInApproved}
          legacyAppeals={intakeData.legacyAppeals}
          formType={formType} />
      </div>;
    })}
  </div>;
};
