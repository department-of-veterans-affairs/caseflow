import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY.json';
import { FORM_TYPES } from '../constants';
import AddedIssue from './AddedIssue';
import Button from '../../components/Button';
import Dropdown from '../../components/Dropdown';
import EditContentionTitle from '../components/EditContentionTitle';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import _ from 'lodash';

const nonEditableIssueStyling = css({
  color: COLORS.GREY,
  fontStyle: 'Italic'
});

export default class IssuesList extends React.Component {
  generateIssueActionOptions = (issue, userCanWithdrawIssues) => {
    let options = [];

    if (!issue.withdrawalDate && !issue.withdrawalPending) {
      if (userCanWithdrawIssues) {
        options.push(
          { displayText: 'Withdraw issue',
            value: 'withdraw' }
        );
      }
      options.push(
        { displayText: 'Remove issue',
          value: 'remove' }
      );
    }
    if (issue.correctionType && issue.endProductCleared) {
      options.push({ displayText: 'Undo correction',
        value: 'undo_correction' });
    }
    if (issue.correctionType) {
      options.push(
        { displayText: 'Remove issue',
          value: 'remove' }
      );
    }
    if (issue.endProductCleared) {
      options.push({ displayText: 'Correct issue',
        value: 'correct' });
    }

    return options;
  }

  render = () => {
    const {
      issues,
      intakeData,
      formType,
      onClickIssueAction,
      withdrawReview,
      featureToggles,
      userCanWithdrawIssues,
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
          let issueActionOptions = this.generateIssueActionOptions(issue, userCanWithdrawIssues);

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

              { !issue.editable && <div className="issue-action">
                <span {...nonEditableIssueStyling}>{COPY.INTAKE_RATING_MAY_BE_PROCESS}</span>
              </div> }

              <div className="issue-action">
                {editPage && issue.editable && !_.isEmpty(issueActionOptions) && <Dropdown
                  name={`issue-action-${issue.index}`}
                  label="Actions"
                  hideLabel
                  options={issueActionOptions}
                  defaultText="Select action"
                  onChange={(option) => onClickIssueAction(issue.index, option)}
                /> }
                {!editPage && <Button
                  onClick={() => onClickIssueAction(issue.index)}
                  classNames={['cf-btn-link', 'remove-issue']}
                >
                  <i className="fa fa-trash-o" aria-hidden="true"></i><br />Remove
                </Button>}

              </div>
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
  issues: PropTypes.array,
  intakeData: PropTypes.object,
  formType: PropTypes.string,
  onClickIssueAction: PropTypes.func,
  withdrawReview: PropTypes.bool,
  featureToggles: PropTypes.object,
  userCanWithdrawIssues: PropTypes.bool,
  editPage: PropTypes.bool
};
