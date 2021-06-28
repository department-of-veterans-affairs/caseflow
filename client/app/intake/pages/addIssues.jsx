/* eslint-disable max-lines */
/* eslint-disable react/prop-types */

import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import moment from 'moment';
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
import EP_CLAIM_TYPES from '../../../constants/EP_CLAIM_TYPES';
import { formatAddedIssues, getAddIssuesFields, formatIssuesBySection } from '../util/issues';
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
import { editEpClaimLabel } from '../../intakeEdit/actions/edit';
import COPY from '../../../COPY';
import { EditClaimLabelModal } from '../../intakeEdit/components/EditClaimLabelModal';
import { ConfirmClaimLabelModal } from '../../intakeEdit/components/ConfirmClaimLabelModal';

class AddIssuesPage extends React.Component {
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
      addingIssue: false,
      loading: false
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

  editingClaimReview() {
    const { formType, editPage } = this.props;

    return (formType === 'higher_level_review' || formType === 'supplemental_claim') && editPage;
  }

  willRedirect(intakeData, hasClearedEp) {
    const { formType, processedAt, featureToggles } = this.props;
    const { correctClaimReviews } = featureToggles;

    return (
      !formType || (this.editingClaimReview() && !processedAt) || intakeData.isOutcoded ||
      (hasClearedEp && !correctClaimReviews)
    );
  }

  redirect(intakeData, hasClearedEp) {
    const { formType, processedAt } = this.props;

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    } else if (this.editingClaimReview() && !processedAt) {
      return <Redirect to={PAGE_PATHS.NOT_EDITABLE} />;
    } else if (hasClearedEp) {
      return <Redirect to={PAGE_PATHS.CLEARED_EPS} />;
    } else if (intakeData.isOutcoded) {
      return <Redirect to={PAGE_PATHS.OUTCODED} />;
    }
  }

  establishmentCreditsTimestamp() {
    const tstamp = moment(this.props.processedAt).format('ddd MMM DD YYYY [at] HH:mm');

    if (this.props.asyncJobUrl) {
      return <a href={this.props.asyncJobUrl}>{tstamp}</a>;
    }

    return tstamp;
  }

  establishmentCredits() {
    return <div className="cf-intake-establish-credits">
      Established {this.establishmentCreditsTimestamp()}
      { this.props.intakeUser &&
        <span> by <a href={`/intake/manager?user_css_id=${this.props.intakeUser}`}>{this.props.intakeUser}</a></span>
      }
    </div>;
  }

  // Methods for handling editing of claim label
  openEditClaimLabelModal = (endProductCode) => {
    this.setState({
      showEditClaimLabelModal: true,
      selectedEpCode: endProductCode
    });
  }
  closeEditClaimLabelModal = () => {
    this.setState({
      showEditClaimLabelModal: false,
      showConfirmClaimLabelModal: false,
      previousEpCode: null,
      selectedEpCode: null
    });
  }

  handleEditClaimLabel = (data) => {
    this.setState({
      showEditClaimLabelModal: false,
      showConfirmClaimLabelModal: true,
      previousEpCode: data.oldCode,
      selectedEpCode: data.newCode
    });
  }

  submitClaimLabelEdit = () => {
    this.props.editEpClaimLabel(
      this.props.intakeForms[this.props.formType].claimId,
      this.props.formType,
      this.state.previousEpCode,
      this.state.selectedEpCode
    );
    this.setState({
      showConfirmClaimLabelModal: true,
      previousEpCode: this.state.previousEpCode,
      selectedEpCode: this.state.selectedEpCode,
      loading: true
    });
  }

  render() {
    const { intakeForms,
      formType,
      veteran,
      featureToggles,
      editPage,
      addingIssue,
      userCanWithdrawIssues
    } = this.props;
    const intakeData = intakeForms[formType];
    const { useAmaActivationDate, nonVeteranClaimants } = featureToggles;
    const hasClearedEp = intakeData && (intakeData.hasClearedRatingEp || intakeData.hasClearedNonratingEp);

    if (this.willRedirect(intakeData, hasClearedEp)) {
      return this.redirect(intakeData, hasClearedEp);

    }
    const requestStatus = intakeData.requestStatus;
    const requestState =
      requestStatus.completeIntake || requestStatus.requestIssuesUpdate || requestStatus.editClaimLabelUpdate;
    const endProductWithError = intakeData.editEpUpdateError;

    const requestErrorCode =
      intakeData.requestStatus.completeIntakeErrorCode || intakeData.requestIssuesUpdateErrorCode;
    const requestErrorUUID = requestStatus.completeIntakeErrorUUID;
    const showInvalidVeteranError =
      !intakeData.veteranValid &&
      _.some(
        intakeData.addedIssues,
        (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId
      );

    const issues = formatAddedIssues(intakeData.addedIssues, useAmaActivationDate);
    const issuesPendingWithdrawal = issues.filter((issue) => issue.withdrawalPending);
    const issuesBySection = formatIssuesBySection(issues);

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

    const issuesChanged = !_.isEqual(
      intakeData.addedIssues, intakeData.originalIssues
    );

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

      if (intakeData.withdrawalDate) {
        if (withdrawalDate < receiptDate) {
          msg = `We cannot process your request. Please select a date after the ${formName}'s receipt date.`;
        } else if (withdrawalDate > currentDate) {
          msg = "We cannot process your request. Please select a date prior to today's date.";
        }

        return msg;
      }
    };

    const columns = [{ valueName: 'field' }, { valueName: 'content' }];

    let fieldsForFormType = getAddIssuesFields(formType, veteran, intakeData);

    if (formType === 'appeal' && nonVeteranClaimants) {
      fieldsForFormType = fieldsForFormType.concat({
        field: 'Claimant\'s POA',
        content: intakeData.powerOfAttorneyName || COPY.ADD_CLAIMANT_CONFIRM_MODAL_NO_POA
      });
    }

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

    const issueSectionRow = (sectionIssues, fieldTitle) => {
      return {
        field: fieldTitle,
        content: (
          <div>
            {endProductWithError && (
              <ErrorAlert errorCode="unable_to_edit_ep" />
            )}
            { !fieldTitle.includes('issues') && <span><strong>Requested issues</strong></span> }
            <IssueList
              onClickIssueAction={this.onClickIssueAction}
              withdrawReview={withdrawReview}
              issues={sectionIssues}
              intakeData={intakeData}
              formType={formType}
              featureToggles={featureToggles}
              userCanWithdrawIssues={userCanWithdrawIssues}
              editPage={editPage}
            />
          </div>
        )
      };
    };

    const endProductLabelRow = (endProductCode, editDisabled) => {
      return {
        field: 'EP Claim Label',
        content: (
          <div className="claim-label-row" key={`claim-label-${endProductCode}`}>
            <div className="claim-label">
              <strong>{ EP_CLAIM_TYPES[endProductCode].official_label }</strong>
            </div>
            <div className="edit-claim-label">
              <Button
                classNames={['usa-button-secondary']}
                onClick={() => this.openEditClaimLabelModal(endProductCode)}
                disabled={editDisabled}
              >
              Edit claim label
              </Button>
            </div>
          </div>
        )
      };
    };

    Object.keys(issuesBySection).sort().
      map((key) => {
        const sectionIssues = issuesBySection[key];
        const endProductCleared = sectionIssues[0]?.endProductCleared;

        if (key === 'requestedIssues') {
          rowObjects = rowObjects.concat(issueSectionRow(sectionIssues, 'Requested issues'));
        } else if (key === 'withdrawnIssues') {
          rowObjects = rowObjects.concat(issueSectionRow(sectionIssues, 'Withdrawn issues'));
        } else {
          rowObjects = rowObjects.concat(endProductLabelRow(key, endProductCleared || issuesChanged));
          rowObjects = rowObjects.concat(issueSectionRow(sectionIssues, ' ', key));
        }

        return rowObjects;
      });

    const hideAddIssueButton = intakeData.isDtaError && _.isEmpty(intakeData.contestableIssues);

    if (!hideAddIssueButton) {
      rowObjects = rowObjects.concat({
        field: ' ',
        content: addIssueButton()
      });
    }

    return (
      <div className="cf-intake-edit">
        {this.state.addingIssue && (
          <AddIssueManager
            intakeData={intakeData}
            formType={formType}
            featureToggles={featureToggles}
            editPage={editPage}
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
        {this.state.showEditClaimLabelModal && (
          <EditClaimLabelModal
            selectedEpCode={this.state.selectedEpCode}
            onCancel={this.closeEditClaimLabelModal}
            onSubmit={this.handleEditClaimLabel}
          />
        )}
        {this.state.showConfirmClaimLabelModal && (
          <ConfirmClaimLabelModal
            previousEpCode={this.state.previousEpCode}
            newEpCode={this.state.selectedEpCode}
            onCancel={this.closeEditClaimLabelModal}
            onSubmit={this.submitClaimLabelEdit}
            loading={this.state.loading}
          />
        )}
        <h1 className="cf-txt-c">{messageHeader}</h1>

        {requestState === REQUEST_STATE.FAILED && (
          <ErrorAlert errorCode={requestErrorCode} errorUUID={requestErrorUUID} />
        )}

        {showInvalidVeteranError && (
          <ErrorAlert errorCode="veteran_not_valid" errorData={intakeData.veteranInvalidFields} />
        )}

        {editPage && this.establishmentCredits()}

        <Table columns={columns} rowObjects={rowObjects} rowClassNames={issueChangeClassname} slowReRendersAreOk />

        {!_.isEmpty(issuesPendingWithdrawal) && (
          <div className="cf-gray-box cf-decision-date">
            <InlineForm>
              <DateSelector
                label={COPY.INTAKE_EDIT_WITHDRAW_DATE}
                name="withdraw-date"
                value={intakeData.withdrawalDate}
                onChange={this.withdrawalDateOnChange}
                dateErrorMessage={withdrawError()}
                type="date"
              />
            </InlineForm>
          </div>
        )}
      </div>
    );
  }
}

AddIssuesPage.propTypes = {
  activeIssue: PropTypes.number,
  addingIssue: PropTypes.bool,
  correctIssue: PropTypes.func,
  editPage: PropTypes.bool,
  featureToggles: PropTypes.object,
  formType: PropTypes.oneOf(_.map(FORM_TYPES, 'key')),
  intakeForms: PropTypes.object,
  removeIssue: PropTypes.func,
  setIssueWithdrawalDate: PropTypes.func,
  toggleAddingIssue: PropTypes.func,
  toggleAddIssuesModal: PropTypes.func,
  toggleCorrectionTypeModal: PropTypes.func,
  toggleIssueRemoveModal: PropTypes.func,
  toggleLegacyOptInModal: PropTypes.func,
  toggleNonratingRequestIssueModal: PropTypes.func,
  toggleUnidentifiedIssuesModal: PropTypes.func,
  toggleUntimelyExemptionModal: PropTypes.func,
  undoCorrection: PropTypes.func,
  veteran: PropTypes.object,
  withdrawIssue: PropTypes.func,
  userCanWithdrawIssues: PropTypes.bool
};

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
    processedAt: state.processedAt,
    intakeUser: state.intakeUser,
    asyncJobUrl: state.asyncJobUrl,
    formType: state.formType,
    veteran: state.veteran,
    featureToggles: state.featureToggles,
    editPage: true,
    activeIssue: state.activeIssue,
    addingIssue: state.addingIssue,
    userCanWithdrawIssues: state.userCanWithdrawIssues
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
        undoCorrection,
        toggleUnidentifiedIssuesModal,
        editEpClaimLabel,
      },
      dispatch
    )
)(AddIssuesPage);
