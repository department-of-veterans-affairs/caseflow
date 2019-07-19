import _ from 'lodash';
import React from 'react';
import COPY from '../../../COPY.json';
import { FORM_TYPES } from '../constants';
import AddedIssue from './AddedIssue';
import Button from '../../components/Button';
import Dropdown from '../../components/Dropdown';
import EditContentionTitle from '../components/EditContentionTitle';

export default class IssuesList extends React.Component {
  render = () => {
    const {
      issues,
      intakeData,
      formType,
      onClickIssueAction,
      withdrawReview,
      featureToggles
    } = this.props;

    const {
      withdrawDecisionReviews,
      editContentionText
    } = featureToggles;

    return <div className="issues">
      <div>
        { withdrawReview && <p className="cf-red-text">{COPY.INTAKE_WITHDRAWN_BANNER}</p> }
        { issues.map((issue) => {
          const editableContentionText = Boolean(
            formType !== FORM_TYPES.APPEAL.key &&
              !issue.category && !issue.ineligibleReason && !issue.isUnidentified && !issue.endProductCleared
          );
          let issueActionOptions = [];

          if (issue.correctionType) {
            issueActionOptions.push({ displayText: 'Undo correction',
              value: 'undo_correction' });
          } else if (issue.endProductCleared) {
            issueActionOptions.push({ displayText: 'Correct issue',
              value: 'correct' });
          } else if (!issue.withdrawalDate && !issue.withdrawalPending) {
            issueActionOptions.push(
              { displayText: 'Withdraw issue',
                value: 'withdraw' },
              { displayText: 'Remove issue',
                value: 'remove' }
            );
          }

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

              { !_.isEmpty(issueActionOptions) && <div className="issue-action">
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
              </div> }
            </div>
            {editContentionText && editableContentionText && <EditContentionTitle
              issue= {issue}
              issueIdx={issue.index} />}
          </div>;
        })}
      </div>
    </div>;
  }
}
