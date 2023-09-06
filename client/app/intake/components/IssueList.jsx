import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { FORM_TYPES } from '../constants';
import AddedIssue from './AddedIssue';
import Alert from 'app/components/Alert';
import Button from '../../components/Button';
import Dropdown from '../../components/Dropdown';
import EditContentionTitle from '../components/EditContentionTitle';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import _ from 'lodash';

const alertStyling = css({
  marginTop: 0,
  marginBottom: '20px'
});

const messageStyling = css({
  color: COLORS.GREY,
  fontSize: '17px !important',
});

const nonEditableIssueStyling = css({
  color: COLORS.GREY,
  fontStyle: 'Italic'
});

export default class IssuesList extends React.Component {
  generateIssueActionOptions = (issue, userCanWithdrawIssues, userCanEditIntakeIssues, isDtaError, docketType) => {
    let options = [];

    if (issue.correctionType && issue.endProductCleared) {
      options.push({ displayText: 'Undo correction',
        value: 'undo_correction' });
    } else if (issue.correctionType && !issue.examRequested && docketType !== 'Legacy') {
      options.push(
        { displayText: 'Remove issue',
          value: 'remove' }
      );
      if (userCanEditIntakeIssues) {
        options.push(
          { displayText: 'Edit issue',
            value: 'edit' }
        );
      }
    } else if (issue.endProductCleared) {
      options.push({ displayText: 'Correct issue',
        value: 'correct' });
    } else if (!issue.examRequested && !issue.withdrawalDate && !issue.withdrawalPending && !isDtaError) {
      if (userCanWithdrawIssues) {
        options.push(
          { displayText: 'Withdraw issue',
            value: 'withdraw' }
        );
      }
      if (docketType !== 'Legacy') {
        options.push(
          { displayText: 'Remove issue',
            value: 'remove' }
        );
      }
      if (userCanEditIntakeIssues) {
        options.push(
          { displayText: 'Edit issue',
            value: 'edit' }
        );
      }
    }

    if (!issue.date || issue.editedDecisionDate) {
      options.push(
        {
          displayText: issue.editedDecisionDate ? 'Edit decision date' : 'Add decision date',
          value: 'add_decision_date'
        }
      );
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
      userCanWithdrawIssues,
      userCanEditIntakeIssues,
      editPage,
      featureToggles
    } = this.props;

    return <div className="issues">
      <div>
        { withdrawReview && <p className="cf-red-text">{COPY.INTAKE_WITHDRAWN_BANNER}</p> }
        { issues.map((issue) => {
          // Issues from rating issues or decision issues have editable contention text. New non-rating issues do not.
          const editableIssueType = Boolean(issue.decisionIssueId || issue.ratingIssueReferenceId ||
            issue.ratingDecisionReferenceId);
          const editableIssueProperties = Boolean(!issue.ineligibleReason && !issue.endProductCleared &&
            !issue.isUnidentified);
          const editableContentionText = Boolean(formType !== FORM_TYPES.APPEAL.key && editableIssueType &&
            editableIssueProperties);

          const issueActionOptions = this.generateIssueActionOptions(
            issue, userCanWithdrawIssues, userCanEditIntakeIssues, intakeData.isDtaError, intakeData.docketType
          );

          const showNoDecisionDateBanner = !issue.date;

          return <div className="issue-container" key={`issue-container-${issue.index}`}>
            <div
              className="issue"
              data-key={`issue-${issue.index}`}
              key={`issue-${issue.index}`}
              id={`issue-${issue.id}`}>

              <AddedIssue
                issue={issue}
                issueIdx={issue.index}
                requestIssues={intakeData.requestIssues}
                legacyOptInApproved={intakeData.legacyOptInApproved}
                legacyAppeals={intakeData.legacyAppeals}
                featureToggles={featureToggles}
                formType={formType} />

              { !issue.editable && <div className="issue-action">
                <span {...nonEditableIssueStyling}>{COPY.INTAKE_RATING_MAY_BE_PROCESS}</span>
              </div> }

              <div className="issue-action">
                {editPage && !_.isEmpty(issueActionOptions) && <Dropdown
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
            {showNoDecisionDateBanner ?
              <Alert
                message={COPY.VHA_NO_DECISION_DATE_BANNER}
                messageStyling={messageStyling}
                styling={alertStyling}
                type="warning"
              /> : null}
            {editableContentionText && <EditContentionTitle
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
  userCanWithdrawIssues: PropTypes.bool,
  userCanEditIntakeIssues: PropTypes.bool,
  editPage: PropTypes.bool,
  featureToggles: PropTypes.object
};
