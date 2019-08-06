import React from 'react';

import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';

import RemoveIssueModal from '../components/RemoveIssueModal';
import CorrectionTypeModal from '../components/CorrectionTypeModal';
import AddIssueManager from '../components/AddIssueManager';

import Button from '../../components/Button';
import InlineForm from '../../components/InlineForm';
import DateSelector from '../../components/DateSelector';
import ErrorAlert from '../components/ErrorAlert';
import { REQUEST_STATE, PAGE_PATHS, VBMS_BENEFIT_TYPES, FORM_TYPES } from '../constants';
import { formatAddedIssues, getAddIssuesFields, validateDate } from '../util/issues';
import { formatDateStr } from '../../util/DateUtil';
import Table from '../../components/Table';
import IssueList from '../components/IssueList';

import {
  toggleAddingIssue,
  toggleAddIssuesModal,
  toggleUntimelyExemptionModal,
  toggleNonratingRequestIssueModal,
  removeIssue,
  withdrawIssue,
  setIssueWithdrawalDate,
  correctIssue,
  undoCorrection,
  toggleUnidentifiedIssuesModal,
  toggleIssueRemoveModal,
  toggleLegacyOptInModal,
  toggleCorrectionTypeModal
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
      issueRemoveIndex: 0,
      issueIndex: 0,
      addingIssue: false
    };
  }

  onClickAddIssue = () => {
    this.setState({ addingIssue: true });
  };

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
      this.props.toggleCorrectionTypeModal({ index });
      break;
    case 'undo_correction':
      this.props.undoCorrection(index);
      break;
    default:
      this.props.undoCorrection(index);
    }
  };

  withdrawalDateOnChange = (value) => {
    this.props.setIssueWithdrawalDate(value);
  };

  willRedirect() {
    const { intakeForms, formType, featureToggles } = this.props;
    const intakeData = intakeForms[formType];
    const { correctClaimReviews } = featureToggles;

    return (
      !formType ||
      intakeData.isDtaError ||
      ((intakeData.hasClearedRatingEp || intakeData.hasClearedNonratingEp) && !correctClaimReviews) ||
      intakeData.isOutcoded
    );
  }

  redirect() {
    const { intakeForms, formType, featureToggles } = this.props;
    const intakeData = intakeForms[formType];
    const { correctClaimReviews } = featureToggles;

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    } else if (intakeData.isDtaError) {
      return <Redirect to={PAGE_PATHS.DTA_CLAIM} />;
    } else if ((intakeData.hasClearedRatingEp || intakeData.hasClearedNonratingEp) && !correctClaimReviews) {
      return <Redirect to={PAGE_PATHS.CLEARED_EPS} />;
    } else if (intakeData.isOutcoded) {
      return <Redirect to={PAGE_PATHS.OUTCODED} />;
    }
  }

  render() {
    const { intakeForms, formType, veteran, featureToggles, editPage, addingIssue } = this.props;

    const intakeData = intakeForms[formType];
    const { useAmaActivationDate } = featureToggles;

    if (this.willRedirect()) {
      return this.redirect();
    }

    const requestState = intakeData.requestStatus.completeIntake || intakeData.requestStatus.requestIssuesUpdate;
    const requestErrorCode = intakeData.completeIntakeErrorCode || intakeData.requestIssuesUpdateErrorCode;
    const showInvalidVeteranError =
      !intakeData.veteranValid &&
      _.some(
        intakeData.addedIssues,
        (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId
      );

    const issues = formatAddedIssues(intakeData, useAmaActivationDate);
    const requestedIssues = issues.filter((issue) => !issue.withdrawalPending && !issue.withdrawalDate);
    const previouslywithdrawnIssues = issues.filter((issue) => issue.withdrawalDate);
    const issuesPendingWithdrawal = issues.filter((issue) => issue.withdrawalPending);
    const withdrawnIssues = previouslywithdrawnIssues.concat(issuesPendingWithdrawal);
    const withdrawDatePlaceholder = formatDateStr(new Date());
    const withdrawReview =
      !_.isEmpty(issues) && _.every(issues, (issue) => issue.withdrawalPending || issue.withdrawalDate);

    const haveIssuesChanged = () => {
      const issueCountChanged = issues.length !== this.state.originalIssueLength;

      // If the entire review is withdrawn, then issues will have changed, but that
      // will be communicated differently so haveIssuesChanged will not be set to true
      const partialWithdrawal = !_.isEmpty(issuesPendingWithdrawal) && !withdrawReview;

      // if an new issue was added or an issue was edited
      const newOrChangedIssue =
        issues.filter((issue) => !issue.id || issue.editedDescription || issue.correctionType).length > 0;

      if (issueCountChanged || partialWithdrawal || newOrChangedIssue) {
        return true;
      }

      return false;
    };

    const addIssueButton = () => {
      return (
        <div className="cf-actions">
          <Button
            name="add-issue"
            legacyStyling={false}
            classNames={['usa-button-secondary']}
            onClick={() => this.onClickAddIssue()}
          >
            + Add issue
          </Button>
        </div>
      );
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
          msg = "We cannot process your request. Please select a date prior to today's date.";
        }
      } else if (intakeData.withdrawalDate && intakeData.withdrawalDate.length >= 10) {
        msg = 'We cannot process your request. Please enter a valid date.';
      }

      return msg;
    };

    const columns = [{ valueName: 'field' }, { valueName: 'content' }];

    let fieldsForFormType = getAddIssuesFields(formType, veteran, intakeData);
    let issueChangeClassname = () => {
      // no-op unless the issue banner needs to be displayed
    };

    if (editPage && haveIssuesChanged()) {
      // flash a save message if user is on the edit page & issues have changed
      const issuesChangedBanner = <p>When you finish making changes, click "Save" to continue.</p>;

      fieldsForFormType = fieldsForFormType.concat({
        field: '',
        content: issuesChangedBanner
      });
      issueChangeClassname = (rowObj) => (rowObj.field === '' ? 'intake-issue-flash' : '');
    }

    let rowObjects = fieldsForFormType;

    if (!_.isEmpty(requestedIssues)) {
      rowObjects = fieldsForFormType.concat({
        field: 'Requested issues',
        content: (
          <IssueList
            onClickIssueAction={this.onClickIssueAction}
            issues={requestedIssues}
            intakeData={intakeData}
            formType={formType}
            featureToggles={featureToggles}
          />
        )
      });
    }

    if (!_.isEmpty(withdrawnIssues)) {
      rowObjects = rowObjects.concat({
        field: 'Withdrawn issues',
        content: (
          <IssueList
            withdrawReview={withdrawReview}
            issues={withdrawnIssues}
            intakeData={intakeData}
            formType={formType}
            featureToggles={featureToggles}
          />
        )
      });
    }

    rowObjects = rowObjects.concat({
      field: ' ',
      content: addIssueButton()
    });

    return (
      <div className="cf-intake-edit">
        {this.state.addingIssue && (
          <AddIssueManager
            intakeData={intakeData}
            formType={formType}
            onComplete={() => {
              this.setState({ addingIssue: false });
            }}
          />
        )}

        {intakeData.removeIssueModalVisible && (
          <RemoveIssueModal
            removeIndex={this.state.issueRemoveIndex}
            intakeData={intakeData}
            closeHandler={this.props.toggleIssueRemoveModal}
          />
        )}
        {intakeData.correctIssueModalVisible && (
          <CorrectionTypeModal
            issueIndex={this.props.activeIssue}
            intakeData={intakeData}
            cancelText={addingIssue ? 'Cancel adding this issue' : 'Cancel'}
            onCancel={() => {
              this.props.toggleCorrectionTypeModal();
            }}
            submitText={addingIssue ? 'Continue' : 'Save'}
            onSubmit={({ correctionType }) => {
              this.props.correctIssue({
                index: this.props.activeIssue,
                correctionType
              });
              this.props.toggleCorrectionTypeModal();
            }}
          />
        )}
        <h1 className="cf-txt-c">{messageHeader}</h1>

        {requestState === REQUEST_STATE.FAILED && <ErrorAlert errorCode={requestErrorCode} />}

        {showInvalidVeteranError && (
          <ErrorAlert errorCode="veteran_not_valid" errorData={intakeData.veteranInvalidFields} />
        )}

        <Table columns={columns} rowObjects={rowObjects} rowClassNames={issueChangeClassname} slowReRendersAreOk />

        {!_.isEmpty(issuesPendingWithdrawal) && (
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
        )}
      </div>
    );
  }
}

export const IntakeAddIssuesPage = connect(
  ({ intake, higherLevelReview, supplementalClaim, appeal, featureToggles, activeIssue, addingIssue }) => ({
    intakeForms: {
      higher_level_review: higherLevelReview,
      supplemental_claim: supplementalClaim,
      appeal
    },
    formType: intake.formType,
    veteran: intake.veteran,
    featureToggles,
    activeIssue,
    addingIssue
  }),
  (dispatch) =>
    bindActionCreators(
      {
        toggleAddIssuesModal,
        toggleUntimelyExemptionModal,
        toggleNonratingRequestIssueModal,
        toggleUnidentifiedIssuesModal,
        toggleLegacyOptInModal,
        removeIssue,
        withdrawIssue,
        setIssueWithdrawalDate
      },
      dispatch
    )
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
    editPage: true,
    activeIssue: state.activeIssue,
    addingIssue: state.addingIssue
  }),
  (dispatch) =>
    bindActionCreators(
      {
        toggleAddingIssue,
        toggleIssueRemoveModal,
        toggleCorrectionTypeModal,
        removeIssue,
        withdrawIssue,
        setIssueWithdrawalDate,
        correctIssue,
        undoCorrection
      },
      dispatch
    )
)(AddIssuesPage);
