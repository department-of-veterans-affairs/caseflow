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
import { WithdrawnIssues, ClearedIssues, CorrectionIssues, RequestedIssues } from '../components/addIssues/IssueLists'

import {
  toggleAddIssuesModal,
  toggleUntimelyExemptionModal,
  toggleNonratingRequestIssueModal,
  removeIssue,
  withdrawIssue,
  setIssueWithdrawalDate,
  correctIssue,
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
    switch (option) {
    case 'remove':
      if (this.props.toggleIssueRemoveModal) {
        // on the edit page, so show the remove modal
        this.setState({
          issueRemoveIndex: index
        });
        this.props.toggleIssueRemoveModal();
      } else {
        this.props.removeIssue(index);
      }
      break;
    case 'withdraw':
      this.props.withdrawIssue(index);
      break;
    case 'correct':
      this.props.correctIssue(index);
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

    if (!formType) { return <Redirect to={PAGE_PATHS.BEGIN} />; }
    if (intakeData.isDtaError) { return <Redirect to={PAGE_PATHS.DTA_CLAIM} />; }
    if (!_.isEmpty(intakeData.clearedEps) && !correctClaimReviews) { return <Redirect to={PAGE_PATHS.CLEARED_EPS} />; }
    if (intakeData.isOutcoded) { return <Redirect to={PAGE_PATHS.OUTCODED} />; }

    const { useAmaActivationDate, withdrawDecisionReviews, editContentionText, correctClaimReviews } = featureToggles;
    const intakeData = intakeForms[formType];
    const requestState = intakeData.requestStatus.completeIntake || intakeData.requestStatus.requestIssuesUpdate;
    const requestErrorCode = intakeData.completeIntakeErrorCode || intakeData.requestIssuesUpdateErrorCode;
    const showInvalidVeteranError = !intakeData.veteranValid && (_.some(
      intakeData.addedIssues, (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId)
    );

    const issues = formatAddedIssues(intakeData, useAmaActivationDate);
    const requestedIssues = issues.filter(
      (i) => !i.withdrawalPending && !i.withdrawalDate && !i.correctedRequestIssueId && !i.endProductCleared
    );

    const previouslywithdrawnIssues = issues.filter((issue) => issue.withdrawalDate);
    const issuesPendingWithdrawal = issues.filter((issue) => issue.withdrawalPending);
    const allWithdrawnIssues = previouslywithdrawnIssues.concat(issuesPendingWithdrawal);
    const withdrawDatePlaceholder = formatDateStr(new Date());
    const withdrawReview = !_.isEmpty(issues) && _.every(
      issues, (issue) => issue.withdrawalPending || issue.withdrawalDate
    );

    const clearedIssues = issues.filter(
      (issue) => issue.endProductCleared && !issue.correctedByIssue && !issue.withdrawalDate
    );
    const correctionIssues = issues.filter((issue) => issue.correctionClaimLabel);

    const haveIssuesChanged = () => {
      if (issues.length !== this.state.originalIssueLength) { return true; }

      // If the entire review is withdrawn, then issues will have changed, but that
      // will be communicated differently so haveIssuesChanged will not be set to true
      if (!_.isEmpty(issuesPendingWithdrawal) && !withdrawReview) { return true; }

      // if any issues do not have ids, it means the issue was just added
      if ((issues.filter((issue) => !issue.id || issue.editedDescription).length > 0)) { return true; }

      return false;
    };

    const addIssueButton = () => {
      return <div className="cf-actions">
        <Button
          name="add-issue"
          legacyStyling={false}
          classNames={['usa-button-secondary']}
          onClick={this.onClickAddIssue(_.size(intakeData.contestableIssues))}
        >
          + Add issue
        </Button>
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

    let rowObjects = fieldsForFormType

    if (!_.isEmpty(requestedIssues)) {
      rowObjects = fieldsForFormType.concat(
        { field: 'Requested issues',
          content: <RequestedIssues
            onClickIssueAction={this.onClickIssueAction}
            issues={requestedIssues}
            intakeData={intakeData}
            formType={formType}
            featureToggles={featureToggles} /> });
    }

    if (!_.isEmpty(allWithdrawnIssues)) {
      rowObjects = rowObjects.concat(
        { field: 'Withdrawn issues',
          content: <WithdrawnIssues
            withdrawReview={withdrawReview}
            issues={allWithdrawnIssues}
            intakeData={intakeData}
            formType={formType} /> });
    }

    if (!_.isEmpty(clearedIssues)) {
      rowObjects = rowObjects.concat(
        { field: 'Cleared issues',
          content: <ClearedIssues
            onClickIssueAction={this.onClickIssueAction}
            issues={clearedIssues}
            intakeData={intakeData}
            formType={formType} /> });
    }

    if (!_.isEmpty(correctionIssues)) {
      rowObjects = rowObjects.concat(
        {
          field: '930 Correction issues',
          content: <CorrectionIssues
            onClickIssueAction={this.onClickIssueAction}
            issues={correctionIssues}
            intakeData={intakeData}
            formType={formType} /> });
    }

    rowObjects = rowObjects.concat(
      { field: ' ',
        content: addIssueButton() });

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

      { !_.isEmpty(issuesPendingWithdrawal) &&
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
    setIssueWithdrawalDate,
    correctIssue
  }, dispatch)
)(AddIssuesPage);
