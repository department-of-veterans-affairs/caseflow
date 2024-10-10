import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { FORM_TYPES } from '../constants';
import AddedIssue from './AddedIssue';
import Alert from 'app/components/Alert';
import Button from '../../components/Button';
import SearchableDropdown from 'app/components/SearchableDropdown';
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
  /* eslint-disable max-params */
  generateIssueActionOptions = (
    issue,
    userCanWithdrawIssues,
    userCanEditIntakeIssues,
    isDtaError,
    docketType,
    formType
  ) => {
    let options = [];

    if (issue.correctionType && issue.endProductCleared) {
      options.push({ label: 'Undo correction',
        value: 'undo_correction' });
    } else if (issue.correctionType && !issue.examRequested && docketType !== 'Legacy') {
      options.push(
        { label: 'Remove issue',
          value: 'remove' }
      );
      if (userCanEditIntakeIssues && (formType === FORM_TYPES.APPEAL.key)) {
        options.push(
          { label: 'Edit issue',
            value: 'edit' }
        );
      }
    } else if (issue.endProductCleared) {
      options.push({ label: 'Correct issue',
        value: 'correct' });
    } else if (!issue.examRequested && !issue.withdrawalDate && !issue.withdrawalPending && !isDtaError) {
      if (userCanWithdrawIssues && issue.id) {
        options.push(
          { label: 'Withdraw issue',
            value: 'withdraw' }
        );
      }
      if (docketType !== 'Legacy') {
        options.push(
          { label: 'Remove issue',
            value: 'remove' }
        );
      }
      if (userCanEditIntakeIssues && (formType === FORM_TYPES.APPEAL.key)) {
        options.push(
          { label: 'Edit issue',
            value: 'edit' }
        );
      }
    }
    if (this.props.showRequestIssueUpdateOptions && this.props.intakeData.benefitType === 'vha') {
      options = [];
      options.push(
        { label: 'Request modification',
          value: 'requestModification' }
      );

      options.push(
        { label: 'Request removal',
          value: 'requestRemoval' }
      );

      options.push(
        { label: 'Request withdrawal',
          value: 'requestWithdrawal' }
      );
    }
    /* eslint-enable max-params */

    const isIssueWithdrawn = issue.withdrawalDate || issue.withdrawalPending;

    // Do not show the Add Decision Date action if the issue is pending or is fully withdrawn
    if ((!issue.date || issue.editedDecisionDate) && !isIssueWithdrawn && !issue.isUnidentified) {
      options.push(
        {
          label: issue.editedDecisionDate ? 'Edit decision date' : 'Add decision date',
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
      featureToggles,
      disableIssueActions,
      disableEditingForCompAndPen
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
            issue,
            userCanWithdrawIssues,
            userCanEditIntakeIssues,
            intakeData.isDtaError,
            intakeData.docketType,
            formType
          );

          const isIssueWithdrawn = issue.withdrawalDate || issue.withdrawalPending;
          const showNoDecisionDateBanner = !issue.date && !isIssueWithdrawn &&
            !issue.isUnidentified && !intakeData.isLegacy;

          const showNewIssueBasedOnRequestIssueBanner = issue.addedFromApprovedRequest;

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
                legacyOptInApproved={intakeData.legacyOptInApproved ?? false}
                legacyAppeals={intakeData.legacyAppeals}
                featureToggles={featureToggles}
                formType={formType} />

              { !issue.editable && <div className="issue-action">
                <span {...nonEditableIssueStyling}>{COPY.INTAKE_RATING_MAY_BE_PROCESS}</span>
              </div> }

              <div className="issue-action">
                {editPage && !_.isEmpty(issueActionOptions) && <SearchableDropdown
                  name={`issue-action-${issue.index}`}
                  key={issue.id}
                  label="Actions"
                  hideLabel
                  options={issueActionOptions}
                  placeholder="Select action"
                  onChange={(option) => onClickIssueAction(issue.index, option.value)}
                  searchable={false}
                  doubleArrow
                  readOnly={disableIssueActions || disableEditingForCompAndPen}
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
            {showNewIssueBasedOnRequestIssueBanner ?
              <Alert
                message={COPY.VHA_BANNER_FOR_NEWLY_APPROVED_REQUESTED_ISSUE}
                messageStyling={messageStyling}
                styling={alertStyling}
                type="info"
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
  userCanRequestIssueUpdates: PropTypes.bool,
  showRequestIssueUpdateOptions: PropTypes.bool,
  editPage: PropTypes.bool,
  featureToggles: PropTypes.object,
  disableIssueActions: PropTypes.bool,
  disableEditingForCompAndPen: PropTypes.bool
};
