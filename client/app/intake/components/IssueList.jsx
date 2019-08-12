import _ from 'lodash';
import React from 'react';
import COPY from '../../../COPY.json';
import { FORM_TYPES } from '../constants';
import AddedIssue from './AddedIssue';
import Button from '../../components/Button';
import Dropdown from '../../components/Dropdown';
import EditContentionTitle from '../components/EditContentionTitle';
import PropTypes from 'prop-types';

export default class IssuesList extends React.Component {
  render = () => {
    const {
      issues,
      intakeData,
      formType,
      onClickIssueAction,
      withdrawReview,
      featureToggles,
      editPage
    } = this.props;

    const {
      editContentionText
    } = featureToggles;

    return <div className="issues">
      <div>
        { withdrawReview && <p className="cf-red-text">{COPY.INTAKE_WITHDRAWN_BANNER}</p> }
        { issues.map((issue) => {
          const editableContentionText = Boolean(formType !== FORM_TYPES.APPEAL.key &&
            !issue.category && !issue.ineligibleReason && !issue.endProductCleared && !issue.isUnidentified
          );
          let issueActionOptions = [];

          if (issue.correctionType && issue.endProductCleared) {
            issueActionOptions.push({ displayText: 'Undo correction',
              value: 'undo_correction' });
          } else if (issue.correctionType) {
            issueActionOptions.push(
              { displayText: 'Remove issue',
                value: 'remove' }
            );
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
                { editPage && <Dropdown
                  name={`issue-action-${issue.index}`}
                  label="Actions"
                  hideLabel
                  options={issueActionOptions}
                  defaultText="Select action"
                  onChange={(option) => onClickIssueAction(issue.index, option)}
                />
                }
                {!editPage && <Button
                  onClick={() => onClickIssueAction(issue.index)}
                  classNames={['cf-btn-link', 'remove-issue']}
                >
                  <i className="fa fa-trash-o" aria-hidden="true"></i><br />Remove
                </Button>}

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

IssuesList.propTypes = {
  featureToggles: PropTypes.object,
  editPage: PropTypes.bool,
  formType: PropTypes.string,
  issues: PropTypes.array,
  onClickIssueAction: PropTypes.func,
  intakeData: PropTypes.object,
  withdrawReview: PropTypes.bool
};
