import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import React from 'react';

import AddIssuesModal from '../components/AddIssuesModal';
import NonratingRequestIssueModal from '../components/NonratingRequestIssueModal';
import RemoveIssueModal from '../components/RemoveIssueModal';
import UnidentifiedIssuesModal from '../components/UnidentifiedIssuesModal';
import UntimelyExemptionModal from '../components/UntimelyExemptionModal';
import LegacyOptInModal from '../components/LegacyOptInModal';
import Button from '../../components/Button';
import Dropdown from '../../components/Dropdown';
import InlineForm from '../../components/InlineForm';
import DateSelector from '../../components/DateSelector';
import AddedIssue from '../components/AddedIssue';
import ErrorAlert from '../components/ErrorAlert';
import { REQUEST_STATE, PAGE_PATHS, VBMS_BENEFIT_TYPES, FORM_TYPES } from '../constants';
import { formatAddedIssues, getAddIssuesFields, validateDate } from '../util/issues';
import { formatDateStr } from '../../util/DateUtil';
import Table from '../../components/Table';
import EditContentionTitle from '../components/EditContentionTitle';

import {
  toggleAddIssuesModal,
  toggleUntimelyExemptionModal,
  toggleNonratingRequestIssueModal,
  removeIssue,
  withdrawIssue,
  setIssueWithdrawalDate,
  toggleUnidentifiedIssuesModal,
  toggleIssueRemoveModal,
  toggleLegacyOptInModal
} from '../actions/addIssues';
import COPY from '../../../COPY.json';

export class AddIssuesPage extends React.Component {
  constructor(props) {
    super(props);

    let originalIssueLength = 0;

    if (this.props.intakeForms && this.props.formType) {
      originalIssueLength = (this.props.intakeForms[this.props.formType].addedIssues || []).length;
    }

    this.state = {
      originalIssueLength,
      issueRemoveIndex: 0
    };
  }

  onClickAddIssue = (ratingIssueCount) => {
    if (!ratingIssueCount) {
      return this.props.toggleNonratingRequestIssueModal;
    }

    return this.props.toggleAddIssuesModal;
  }

  onClickIssueAction = (index, option = 'remove') => {
    if (option === 'remove') {
      if (this.props.toggleIssueRemoveModal) {
        // on the edit page, so show the remove modal
        this.setState({
          issueRemoveIndex: index
        });
        this.props.toggleIssueRemoveModal();
      } else {
        this.props.removeIssue(index);
      }
    } else if (option === 'withdraw') {
      this.props.withdrawIssue(index);
    }
  }

  withdrawalDateOnChange = (value) => {
    this.props.setIssueWithdrawalDate(value);
  }

  render() {
    const {
      intakeForms,
      formType,
      veteran,
      featureToggles,
      editPage
    } = this.props;

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    const { useAmaActivationDate, withdrawDecisionReviews, editContentionText, correctClaimReviews } = featureToggles;
    const intakeData = intakeForms[formType];
    const requestState = intakeData.requestStatus.completeIntake || intakeData.requestStatus.requestIssuesUpdate;
    const requestErrorCode = intakeData.completeIntakeErrorCode || intakeData.requestIssuesUpdateErrorCode;
    const showInvalidVeteranError = !intakeData.veteranValid && (_.some(
      intakeData.addedIssues, (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId)
    );

    const issues = formatAddedIssues(intakeData, useAmaActivationDate);
    const requestIssues = issues.filter((issue) => !issue.withdrawalPending && !issue.withdrawalDate);
    const previouslywithdrawnIssues = issues.filter((issue) => issue.withdrawalDate);
    const issuesPendingWithdrawal = issues.filter((issue) => issue.withdrawalPending);
    const allWithdrawnIssues = previouslywithdrawnIssues.concat(issuesPendingWithdrawal);
    const hasWithdrawnIssues = !_.isEmpty(allWithdrawnIssues);
    const withdrawDatePlaceholder = formatDateStr(new Date());
    const withdrawReview = !_.isEmpty(issues) && _.every(
      issues, (issue) => issue.withdrawalPending || issue.withdrawalDate
    );

    const haveIssuesChanged = () => {
      if (issues.length !== this.state.originalIssueLength) {
        return true;
      }

      // If the entire review is withdrawn, then issues will have changed, but that
      // will be communicated differently so haveIssuesChanged will not be set to true
      if (!_.isEmpty(issuesPendingWithdrawal) && !withdrawReview) {
        return true;
      }

      // if any issues do not have ids, it means the issue was just added
      if ((issues.filter((issue) => !issue.id || issue.editedDescription).length > 0)) {
        return true;
      }

      return false;
    };

    if (intakeData.isDtaError) {
      return <Redirect to={PAGE_PATHS.DTA_CLAIM} />;
    }

    if (intakeData.hasClearedEP && !correctClaimReviews) {
      return <Redirect to={PAGE_PATHS.CLEARED_EPS} />;
    }

    if (intakeData.isOutcoded) {
      return <Redirect to={PAGE_PATHS.OUTCODED} />;
    }

    const requestIssuesComponent = () => {
      const issueActionOptions = [
        { displayText: 'Withdraw issue',
          value: 'withdraw' },
        { displayText: 'Remove issue',
          value: 'remove' }
      ];

      return <div className="issues">
        <div>
          { requestIssues.map((issue) => {
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
                    onChange={(option) => this.onClickIssueAction(issue.index, option)}
                  />
                  }
                  { !withdrawDecisionReviews && <Button
                    onClick={() => this.onClickIssueAction(issue.index)}
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
        <div className="cf-actions">
          <Button
            name="add-issue"
            legacyStyling={false}
            classNames={['usa-button-secondary']}
            onClick={this.onClickAddIssue(_.size(intakeData.contestableIssues))}
          >
            + Add issue
          </Button>
        </div>
      </div>;
    };

    const withdrawnIssuesComponent = () => {
      return <div className="issues">
        { withdrawReview && <p className="cf-red-text">{COPY.INTAKE_WITHDRAWN_BANNER}</p> }
        { allWithdrawnIssues.map((issue) => {
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

    const messageHeader = editPage ? 'Edit Issues' : 'Add / Remove Issues';

    const withdrawError = () => {
      const withdrawalDate = new Date(intakeData.withdrawalDate);
      const currentDate = new Date();
      const receiptDate = new Date(intakeData.receiptDate);
      const formName = _.find(FORM_TYPES, { key: formType }).shortName;
      let msg;

      if (validateDate(intakeData.withdrawalDate)) {
        if (withdrawalDate < receiptDate) {
          msg = `We cannot process your request. Please select a date after the ${formName}'s receipt date.`;
        } else if (withdrawalDate > currentDate) {
          msg = 'We cannot process your request. Please select a date prior to today\'s date.';
        }
      } else if (intakeData.withdrawalDate && intakeData.withdrawalDate.length >= 10) {
        msg = 'We cannot process your request. Please enter a valid date.';
      }

      return msg;
    };

    const columns = [
      { valueName: 'field' },
      { valueName: 'content' }
    ];

    let fieldsForFormType = getAddIssuesFields(formType, veteran, intakeData);
    let issueChangeClassname = () => {
      // no-op unless the issue banner needs to be displayed
    };

    if (editPage && haveIssuesChanged()) {
      // flash a save message if user is on the edit page & issues have changed
      const issuesChangedBanner = <p>When you finish making changes, click "Save" to continue.</p>;

      fieldsForFormType = fieldsForFormType.concat(
        { field: '',
          content: issuesChangedBanner });
      issueChangeClassname = (rowObj) => rowObj.field === '' ? 'intake-issue-flash' : '';
    }

    let rowObjects = fieldsForFormType.concat(
      { field: 'Requested issues',
        content: requestIssuesComponent() });

    if (hasWithdrawnIssues) {
      rowObjects = rowObjects.concat(
        {
          field: 'Withdrawn issues',
          content: withdrawnIssuesComponent()
        }
      );
    }

    return <div className="cf-intake-edit">
      { intakeData.addIssuesModalVisible && <AddIssuesModal
        intakeData={intakeData}
        formType={formType}
        closeHandler={this.props.toggleAddIssuesModal} />
      }
      { intakeData.untimelyExemptionModalVisible && <UntimelyExemptionModal
        intakeData={intakeData}
        closeHandler={this.props.toggleUntimelyExemptionModal} />
      }
      { intakeData.nonRatingRequestIssueModalVisible && <NonratingRequestIssueModal
        intakeData={intakeData}
        formType={formType}
        closeHandler={this.props.toggleNonratingRequestIssueModal} />
      }
      { intakeData.unidentifiedIssuesModalVisible && <UnidentifiedIssuesModal
        intakeData={intakeData}
        closeHandler={this.props.toggleUnidentifiedIssuesModal} />
      }
      { intakeData.legacyOptInModalVisible && <LegacyOptInModal
        intakeData={intakeData}
        closeHandler={this.props.toggleLegacyOptInModal} />
      }
      { intakeData.removeIssueModalVisible && <RemoveIssueModal
        removeIndex={this.state.issueRemoveIndex}
        intakeData={intakeData}
        closeHandler={this.props.toggleIssueRemoveModal} />
      }
      <h1 className="cf-txt-c">{messageHeader}</h1>

      { requestState === REQUEST_STATE.FAILED &&
        <ErrorAlert errorCode={requestErrorCode} />
      }

      { showInvalidVeteranError &&
        <ErrorAlert errorCode="veteran_not_valid" errorData={intakeData.veteranInvalidFields} /> }

      <Table
        columns={columns}
        rowObjects={rowObjects}
        rowClassNames={issueChangeClassname}
        slowReRendersAreOk />

      { hasWithdrawnIssues &&
        <div className="cf-gray-box cf-decision-date">
          <InlineForm>
            <DateSelector
              label={COPY.INTAKE_EDIT_WITHDRAW_DATE}
              name="withdraw-date"
              value={intakeData.withdrawalDate}
              onChange={this.withdrawalDateOnChange}
              placeholder={withdrawDatePlaceholder}
              dateErrorMessage={withdrawError()}
            />
          </InlineForm>
        </div>
      }
    </div>;
  }
}

export const IntakeAddIssuesPage = connect(
  ({ intake, higherLevelReview, supplementalClaim, appeal, featureToggles }) => ({
    intakeForms: {
      higher_level_review: higherLevelReview,
      supplemental_claim: supplementalClaim,
      appeal
    },
    formType: intake.formType,
    veteran: intake.veteran,
    featureToggles
  }),
  (dispatch) => bindActionCreators({
    toggleAddIssuesModal,
    toggleUntimelyExemptionModal,
    toggleNonratingRequestIssueModal,
    toggleUnidentifiedIssuesModal,
    toggleLegacyOptInModal,
    removeIssue,
    withdrawIssue,
    setIssueWithdrawalDate
  }, dispatch)
)(AddIssuesPage);

export const EditAddIssuesPage = connect(
  (state) => ({
    intakeForms: {
      higher_level_review: state,
      supplemental_claim: state,
      appeal: state
    },
    formType: state.formType,
    veteran: state.veteran,
    featureToggles: state.featureToggles,
    editPage: true
  }),
  (dispatch) => bindActionCreators({
    toggleAddIssuesModal,
    toggleUntimelyExemptionModal,
    toggleIssueRemoveModal,
    toggleNonratingRequestIssueModal,
    toggleUnidentifiedIssuesModal,
    toggleLegacyOptInModal,
    removeIssue,
    withdrawIssue,
    setIssueWithdrawalDate
  }, dispatch)
)(AddIssuesPage);
