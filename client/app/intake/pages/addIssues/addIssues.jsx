/* eslint-disable max-lines */
/* eslint-disable react/prop-types */

import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import moment from 'moment';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import AddDecisionDateModal from 'app/intake/components/AddDecisionDateModal/AddDecisionDateModal';
import RemoveIssueModal from '../../components/RemoveIssueModal/RemoveIssueModal';
import CorrectionTypeModal from '../../components/CorrectionTypeModal';
import AddIssueManager from '../../components/AddIssueManager';

import Button from '../../../components/Button';
import InlineForm from '../../../components/InlineForm';
import DateSelector from '../../../components/DateSelector';
import ErrorAlert from '../../components/ErrorAlert';
import { REQUEST_STATE, PAGE_PATHS, VBMS_BENEFIT_TYPES, FORM_TYPES } from '../../constants';
import EP_CLAIM_TYPES from '../../../../constants/EP_CLAIM_TYPES';
import {
  formatAddedIssues,
  formatRequestIssues,
  getAddIssuesFields,
  formatIssuesBySection,
  formatLegacyAddedIssues
} from '../../util/issues';
import Table from '../../../components/Table';
import issueSectionRow from './issueSectionRow/issueSectionRow';
import { IssueModificationRow as issueModificationRow } from 'app/intake/components/IssueModificationRow';

import {
  toggleAddDecisionDateModal,
  toggleAddingIssue,
  toggleAddIssuesModal,
  toggleUntimelyExemptionModal,
  toggleNonratingRequestIssueModal,
  addIssue,
  removeIssue,
  withdrawIssue,
  setIssueWithdrawalDate,
  setMstPactDetails,
  correctIssue,
  undoCorrection,
  toggleUnidentifiedIssuesModal,
  toggleIssueRemoveModal,
  toggleLegacyOptInModal,
  toggleCorrectionTypeModal,
  toggleEditIntakeIssueModal
} from '../../actions/addIssues';
import {
  toggleRequestIssueModificationModal,
  toggleRequestIssueRemovalModal,
  toggleRequestIssueWithdrawalModal,
  toggleRequestIssueAdditionModal,
  toggleCancelPendingRequestIssueModal,
  toggleConfirmPendingRequestIssueModal,
  moveToPendingReviewSection,
  addToPendingReviewSection,
  updatePendingReview,
  cancelOrRemovePendingReview,
  setAllApprovedIssueModificationsWithdrawalDates
} from '../../actions/issueModificationRequest';
import { editEpClaimLabel } from '../../../intakeEdit/actions/edit';
import COPY from '../../../../COPY';
import { EditClaimLabelModal } from '../../../intakeEdit/components/EditClaimLabelModal';
import { ConfirmClaimLabelModal } from '../../../intakeEdit/components/ConfirmClaimLabelModal';
import { EditIntakeIssueModal } from '../../../intakeEdit/components/EditIntakeIssueModal';
import { RequestIssueModificationModal } from 'app/intakeEdit/components/RequestIssueModificationModal';
import { RequestIssueRemovalModal } from 'app/intakeEdit/components/RequestIssueRemovalModal';
import { RequestIssueWithdrawalModal } from 'app/intakeEdit/components/RequestIssueWithdrawalModal';
import { RequestIssueAdditionModal } from 'app/intakeEdit/components/RequestIssueAdditionModal';
import { CancelPendingRequestIssueModal } from 'app/intake/components/CancelPendingRequestIssueModal';
import { ConfirmPendingRequestIssueModal } from '../../components/ConfirmPendingRequestIssueModal';
import { getOpenPendingIssueModificationRequests } from '../../selectors';
import Alert from '../../../components/Alert';
import { css } from 'glamor';

class AddIssuesPage extends React.Component {
  constructor(props) {
    super(props);

    let originalIssueLength = 0;

    if (this.props.intakeForms && this.props.formType) {
      originalIssueLength = (this.props.intakeForms[this.props.formType].addedIssues || []).length;
    }

    this.state = {
      originalIssueLength,
      issueAddDecisionDateIndex: 0,
      issueRemoveIndex: 0,
      issueIndex: 0,
      addingIssue: false,
      loading: false,
      pendingIssueModification: {}
    };
  }

  onClickAddIssue = () => {
    this.setState({ addingIssue: true });
  };

  onClickRequestAdditionalIssue = () => {
    this.setState({
      pendingIssueModification: {}
    });
    this.props.toggleRequestIssueAdditionModal();
  }

  onClickIssueRequestModificationAction = (issueModificationRequest, requestType) => {
    const identifier = issueModificationRequest.identifier;

    switch (requestType) {
    case 'reviewIssueModificationRequest':
      this.setState({
        pendingIssueModification: issueModificationRequest
      });
      this.props.toggleRequestIssueModificationModal(identifier);
      break;
    case 'reviewIssueAdditionRequest':
      this.setState({
        pendingIssueModification: issueModificationRequest
      });
      this.props.toggleRequestIssueAdditionModal(identifier);
      break;
    case 'reviewIssueWithdrawalRequest':
      this.setState({
        pendingIssueModification: issueModificationRequest
      });
      this.props.toggleRequestIssueWithdrawalModal(identifier);
      break;
    case 'reviewIssueRemovalRequest':
      this.setState({
        pendingIssueModification: issueModificationRequest,
      });
      this.props.toggleRequestIssueRemovalModal(identifier);
      break;
    case 'cancelReviewIssueRequest':
      this.setState({
        pendingIssueModification: issueModificationRequest,
      });
      this.props.toggleCancelPendingRequestIssueModal();
      break;
    default:
      // Do nothing if the dropdown option was not set or implemented.
      break;
    }
  };

  onClickIssueAction = (index, option = 'remove') => {
    switch (option) {
    case 'add_decision_date':
      this.props.toggleAddDecisionDateModal();
      this.setState({ issueAddDecisionDateIndex: index });
      break;
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
    case 'edit':
      this.setState({
        issueIndex: index
      });
      this.props.toggleEditIntakeIssueModal({ index });
      break;
    case 'requestModification':
      this.setState({
        issueIndex: index,
        pendingIssueModification: {}
      });
      this.props.toggleRequestIssueModificationModal(index);
      break;
    case 'requestRemoval':
      this.setState({
        issueIndex: index,
        pendingIssueModification: {}
      });
      this.props.toggleRequestIssueRemovalModal(index);
      break;
    case 'requestWithdrawal':
      this.setState({
        issueIndex: index,
        pendingIssueModification: {}
      });
      this.props.toggleRequestIssueWithdrawalModal(index);
      break;
    default:
      this.props.undoCorrection(index);
    }
  };

  onClickSplitAppeal = () => {
    return <Redirect to={PAGE_PATHS.CREATE_SPLIT} />;
  };

  withdrawalDateOnChange = (value) => {
    this.props.setIssueWithdrawalDate(value);
    this.props.setAllApprovedIssueModificationsWithdrawalDates(value);
  };

  editingClaimReview() {
    const { formType, editPage } = this.props;

    return (formType === 'higher_level_review' || formType === 'supplemental_claim') && editPage;
  }

  // eslint-disable-next-line class-methods-use-this
  requestIssuesWithoutDecisionDates(intakeData) {
    if (intakeData.docketType === 'Legacy') {
      return false;
    }
    const requestIssues = formatRequestIssues(intakeData.requestIssues, intakeData.contestableIssues);

    return !requestIssues.every((issue) => issue.ratingIssueReferenceId ||
      issue.isUnidentified || issue.decisionDate);
  }

  willRedirect(intakeData, hasClearedEp) {
    const { formType, processedAt, featureToggles } = this.props;
    const { correctClaimReviews } = featureToggles;

    return (
      !formType || (this.editingClaimReview() && !processedAt) ||
      intakeData.isOutcoded || (hasClearedEp && !correctClaimReviews)
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
      {this.props.intakeUser &&
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
      userCanWithdrawIssues,
      userCanEditIntakeIssues,
      userIsVhaAdmin,
      userCanSplitAppeal,
      userCanRequestIssueUpdates,
      isLegacy,
      pendingIssueModificationRequests,
      intakeFromVbms
    } = this.props;

    const intakeData = intakeForms[formType];
    const appealInfo = intakeForms.appeal;
    const { useAmaActivationDate, hlrScUnrecognizedClaimants, disableAmaEventing } = featureToggles;
    const hasClearedEp = intakeData && (intakeData.hasClearedRatingEp || intakeData.hasClearedNonratingEp);

    if (this.willRedirect(intakeData, hasClearedEp)) {
      return this.redirect(intakeData, hasClearedEp);
    }

    if (intakeData && intakeData.benefitType !== 'vha' && this.requestIssuesWithoutDecisionDates(intakeData)) {
      return <Redirect to={PAGE_PATHS.REQUEST_ISSUE_MISSING_DECISION_DATE} />;
    }

    const requestStatus = intakeData.requestStatus;
    const requestState =
      requestStatus.completeIntake || requestStatus.requestIssuesUpdate || requestStatus.editClaimLabelUpdate;

    const requestErrorCode =
      intakeData.requestStatus.completeIntakeErrorCode || intakeData.requestIssuesUpdateErrorCode;
    const requestErrorUUID = requestStatus.completeIntakeErrorUUID;
    const showInvalidVeteranError =
      !intakeData.veteranValid &&
      _.some(
        intakeData.addedIssues,
        (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId
      );

    const issues = intakeData.docketType === 'Legacy' ?
      formatLegacyAddedIssues(intakeData.requestIssues, intakeData.addedIssues) :
      formatAddedIssues(intakeData.addedIssues, useAmaActivationDate);

    // Filter the issues to remove those that have a pending modification request
    const issuesWithoutPendingModificationRequests = _.isEmpty(pendingIssueModificationRequests) ?
      issues : issues.filter((issue) => {
        return !pendingIssueModificationRequests.some((request) => {
          return request?.requestIssue && request?.requestIssue?.id === issue.id;
        });
      });

    const issuesPendingWithdrawal = issues.filter((issue) => issue.withdrawalPending);

    const issuesBySection = formatIssuesBySection(issuesWithoutPendingModificationRequests);

    const withdrawReview =
      !_.isEmpty(issues) && _.every(issues, (issue) => issue.withdrawalPending || issue.withdrawalDate);

    const haveIssuesChanged = () => {
      const issueCountChanged = issues.length !== this.state.originalIssueLength;

      // If the entire review is withdrawn, then issues will have changed, but that
      // will be communicated differently so haveIssuesChanged will not be set to true
      const partialWithdrawal = !_.isEmpty(issuesPendingWithdrawal) && !withdrawReview;

      // if an new issue was added or an issue was edited
      const newOrChangedIssue =
        issues.filter((issue) => !issue.id || issue.editedDescription ||
          issue.editedDecisionDate || issue.correctionType).length > 0;

      if (issueCountChanged || partialWithdrawal || newOrChangedIssue) {
        return true;
      }

      return false;
    };

    const areAllIssuesReadyToBeEstablished = () => {
      const withdrawnIssue = (issue) => (issue.withdrawalDate || issue.withdrawalPending);
      const establishedIssue = (issue) => (withdrawnIssue(issue) || issue.decisionDate);

      return _.every(intakeData.addedIssues, establishedIssue);
    };

    const issuesChanged = !_.isEqual(
      intakeData.addedIssues, intakeData.originalIssues
    );

    const splitButtonVisible = () => {

      return ((
        appealInfo?.issueCount > 1 || appealInfo.requestIssues?.length > 1) &&
        userCanSplitAppeal && this.props.featureToggles.split_appeal_workflow);

    };

    const originalIssuesHaveNoDecisionDate = () => {
      return intakeData.originalIssues.some((issue) => issue.decisionDate === null);
    };

    const showRequestIssueUpdateOptions = editPage &&
      userCanRequestIssueUpdates &&
      !originalIssuesHaveNoDecisionDate() &&
      intakeData.benefitType === 'vha';

    const disableIssueActions = editPage &&
      intakeData.userIsVhaAdmin &&
      !_.isEmpty(intakeData.originalPendingIssueModificationRequests);

    const renderButtons = () => {
      if (showRequestIssueUpdateOptions) {
        return (
          <div className="cf-actions">
            <Button
              name="request-additional-issue"
              label="request-additional-issue"
              legacyStyling={false}
              classNames={['usa-button-secondary']}
              onClick={() => this.onClickRequestAdditionalIssue()}
            >
              + Request additional issue
            </Button>
          </div>
        );
      }

      return (
        <div className="cf-actions">
          {splitButtonVisible() ? (
            [<Button
              name="add-issue"
              label="add-issue"
              legacyStyling={false}
              classNames={['usa-button-secondary']}
              onClick={() => this.onClickAddIssue()}
              disabled={this.props.disableEditingForCompAndPen}
            >
              + Add issue
            </Button>,
            (' '),
            <Link to="/create_split" disabled={issuesChanged}>
              <Button
                name="split-appeal"
                label="split-appeal"
                legacyStyling={false}
                classNames={['usa-button-secondary']}
                disabled={issuesChanged}
              >
                Split appeal
              </Button>
            </Link>]
          ) : (
            <Button
              name="add-issue"
              legacyStyling={false}
              dangerStyling
              onClick={() => this.onClickAddIssue()}
              disabled={disableIssueActions || this.props.disableEditingForCompAndPen}
            >
              + Add issue
            </Button>)}
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

    // Factory function for generating cell span functions based on an array of possible field values
    const createTableCellSpanFunc = (fieldValues, matchSpan, noMatchSpan) => {
      return (rowObj) => fieldValues.includes(rowObj.field) ? matchSpan : noMatchSpan;
    };

    // Add keys to this field to make the content span an entire row
    const fieldKeysThatSpanTheRow = ['undecided pending addition requests'];

    // Create two spaning functions to pass to the Table component. If it matches the field key,
    // then the content should span the full row.
    const hideFieldColumn = createTableCellSpanFunc(fieldKeysThatSpanTheRow, 0, 1);
    const growContentColumn = createTableCellSpanFunc(fieldKeysThatSpanTheRow, 2, 1);

    const columns = [{ valueName: 'field', span: hideFieldColumn }, { valueName: 'content', span: growContentColumn }];

    let fieldsForFormType = getAddIssuesFields(formType, veteran, intakeData);

    const shouldAddPoAField = Boolean(
      formType === 'appeal' ||
      (
        hlrScUnrecognizedClaimants &&
        (
          formType === 'higher_level_review' ||
          formType === 'supplemental_claim'
        )
      )
    );

    // at first when we select child / spouse as a claimant, intake.claimant = 'claimant_not_listed'
    // but when the AddIssues Page reload intake.claimant becomes equal to empty string,
    // due to which we have to include '' in the condition below.
    const whichVHAPOATextToDisplay = () => {
      if (intakeData?.unlistedClaimant?.poaForm === 'false') {
        return COPY.VHA_NO_POA;
      }

      return (intakeData?.poa?.listedAttorney?.value === 'not_listed' &&
        intakeData.claimantRelationship !== 'Attorney') ?
        COPY.VHA_NO_RECOGNIZED_POA : COPY.VHA_NO_POA;
    };

    if (shouldAddPoAField) {
      const noPoaText =
        intakeData.benefitType === 'vha' ? whichVHAPOATextToDisplay() : COPY.ADD_CLAIMANT_CONFIRM_MODAL_NO_POA;

      fieldsForFormType = fieldsForFormType.concat({
        field: 'Claimant\'s POA',
        content: intakeData.powerOfAttorneyName || noPoaText
      });
    }

    let additionalRowClasses = () => {
      // no-op unless the issue banner needs to be displayed
    };

    if (editPage && haveIssuesChanged()) {
      // flash a save message if user is on the edit page & issues have changed
      const isEstablishedAndVha = intakeData.benefitType === 'vha' &&
        areAllIssuesReadyToBeEstablished() &&
        _.isEmpty(pendingIssueModificationRequests);

      const establishText = isEstablishedAndVha ? 'Establish' : 'Save';
      const issuesChangedBanner = <p>{`When you finish making changes, click "${establishText}" to continue.`}</p>;

      fieldsForFormType = fieldsForFormType.concat({
        field: '',
        content: issuesChangedBanner
      });
      additionalRowClasses = (rowObj) => (rowObj.field === '' ? 'intake-issue-flash' : '');
    }

    if (editPage) {
      // This checks for open addition requests to prevent claim deletion while they still exist
      const hasPendingAdditionRequests = pendingIssueModificationRequests.some((issueModificationRequest) => {
        return issueModificationRequest.requestType === 'addition';
      }) && (_.isEmpty(intakeData.addedIssues) || _.every(
        intakeData.addedIssues, (issue) => issue.withdrawalPending || issue.withdrawalDate
      ));

      if (hasPendingAdditionRequests) {
        // If there are remaining addition issue modification requests, and all the other request issues
        // have been removed or withdrawn, then show a banner that tells the user that they can't save the
        // claim until those pending issue modification requests have been decided to prevent premature claim deletion
        const messageStyling = css({
          fontSize: '17px !important',
          fontWeight: 'normal'
        });

        const deletionBanner = <Alert
          type="warning"
          message="All pending issue addition requests must be reviewed before the claim can be saved."
          messageStyling={messageStyling} />;

        fieldsForFormType = fieldsForFormType.concat({
          field: 'undecided pending addition requests',
          content: deletionBanner
        });
      }

    }

    const endProductLabelRow = (endProductCode, editDisabled) => {
      return {
        field: 'EP Claim Label',
        content: (
          <div className="claim-label-row" key={`claim-label-${endProductCode}`}>
            <div className="claim-label">
              <strong>{EP_CLAIM_TYPES[endProductCode].official_label}</strong>
            </div>
            <div className="edit-claim-label">
              <Button
                classNames={['usa-button-secondary']}
                onClick={() => this.openEditClaimLabelModal(endProductCode)}
                disabled={editDisabled || this.props.disableEditingForCompAndPen}
              >
                Edit claim label
              </Button>
            </div>
          </div>
        )
      };
    };

    const intakeSystemLabelRow = () => {
      return {
        field: 'Intake System',
        content: intakeFromVbms ? 'VBMS' : 'Caseflow'
      };
    };

    let rowObjects = fieldsForFormType;

    if (!disableAmaEventing) {
      rowObjects = rowObjects.concat(intakeSystemLabelRow());
    }

    Object.keys(issuesBySection).sort().
      map((key) => {
        const sectionIssues = issuesBySection[key];
        const endProductCleared = sectionIssues[0]?.endProductCleared;
        const issueSectionRowProps = {
          editPage,
          featureToggles,
          formType,
          intakeData,
          onClickIssueAction: this.onClickIssueAction,
          sectionIssues,
          userCanWithdrawIssues,
          userCanEditIntakeIssues,
          userIsVhaAdmin,
          userCanRequestIssueUpdates,
          withdrawReview,
          showRequestIssueUpdateOptions
        };

        if (key === 'requestedIssues') {
          rowObjects = rowObjects.concat(
            issueSectionRow({
              ...issueSectionRowProps,
              fieldTitle: 'Requested issues',
              disableEditingForCompAndPen: this.props.disableEditingForCompAndPen,
              disableIssueActions
            }),
          );
        } else if (key === 'withdrawnIssues') {
          rowObjects = rowObjects.concat(
            issueSectionRow({
              ...issueSectionRowProps,
              fieldTitle: 'Withdrawn issues',
              disableEditingForCompAndPen: this.props.disableEditingForCompAndPen
            }),
          );
        } else {
          rowObjects = rowObjects.concat(endProductLabelRow(key, endProductCleared || issuesChanged));
          rowObjects = rowObjects.concat(
            issueSectionRow({
              ...issueSectionRowProps,
              fieldTitle: ' ',
              disableEditingForCompAndPen: this.props.disableEditingForCompAndPen
            }),
          );
        }

        return rowObjects;
      });

    // Pending modifications table section
    if (!_.isEmpty(pendingIssueModificationRequests)) {
      rowObjects = rowObjects.concat(issueModificationRow({
        issueModificationRequests: pendingIssueModificationRequests,
        fieldTitle: 'Pending admin review',
        onClickIssueRequestModificationAction: this.onClickIssueRequestModificationAction
      }));
    }

    additionalRowClasses = (rowObj) => (rowObj.field === '' ? 'intake-issue-flash' : '');

    const hideAddIssueButton = (intakeData.isDtaError && _.isEmpty(intakeData.contestableIssues)) ||
      intakeData.docketType === 'Legacy';

    if (!hideAddIssueButton) {
      rowObjects = rowObjects.concat({
        field: ' ',
        content: renderButtons()
      });
    }

    return (
      <div className="cf-intake-edit">
        {this.state.addingIssue && (
          <AddIssueManager
            intakeData={intakeData}
            formType={formType}
            userCanEditIntakeIssues={this.props.userCanEditIntakeIssues}
            userIsVhaAdmin={this.props.userIsVhaAdmin}
            featureToggles={featureToggles}
            editPage={editPage}
            onComplete={() => {
              this.setState({ addingIssue: false });
            }}
          />
        )}

        {intakeData.addDecisionDateModalVisible && (
          <AddDecisionDateModal
            closeHandler={this.props.toggleAddDecisionDateModal}
            currentIssue={intakeData.addedIssues[this.state.issueAddDecisionDateIndex]}
            index={this.state.issueAddDecisionDateIndex}
          />
        )}
        {intakeData.removeIssueModalVisible && (
          <RemoveIssueModal
            removeIndex={this.state.issueRemoveIndex}
            intakeData={intakeData}
            closeHandler={this.props.toggleIssueRemoveModal}
            pendingIssueModificationRequest={this.state.pendingIssueModification}
            userIsVhaAdmin={this.props.userIsVhaAdmin}
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
        {intakeData.editIntakeIssueModalVisible && (
          <EditIntakeIssueModal
            issueIndex={this.state.issueIndex}
            currentIssue={this.props.intakeForms[this.props.formType].addedIssues[this.state.issueIndex]}
            legacyIssues={issues}
            appealIsLegacy={isLegacy}
            mstIdentification={this.props.featureToggles.mstIdentification}
            pactIdentification={this.props.featureToggles.pactIdentification}
            justificationReason={this.props.featureToggles.justificationReason}
            onCancel={() => {
              this.props.toggleEditIntakeIssueModal();
            }}
            onSubmit={(issueProps) => {
              this.props.setMstPactDetails({
                issueProps,
              });
              this.props.toggleEditIntakeIssueModal();
            }}
          />
        )}

        {intakeData.requestIssueModificationModalVisible && (
          <RequestIssueModificationModal
            currentIssue={this.props.intakeForms[this.props.formType].addedIssues[this.state.issueIndex]}
            issueIndex={this.state.issueIndex}
            onCancel={() => this.props.toggleRequestIssueModificationModal()}
            moveToPendingReviewSection={this.props.moveToPendingReviewSection}
            pendingIssueModificationRequest={this.state.pendingIssueModification}
            toggleConfirmPendingRequestIssueModal={this.props.toggleConfirmPendingRequestIssueModal}
            updatePendingReview={this.props.updatePendingReview}
          />
        )}

        {intakeData.requestIssueRemovalModalVisible && (
          <RequestIssueRemovalModal
            currentIssue={this.props.intakeForms[this.props.formType].addedIssues[this.state.issueIndex]}
            issueIndex={this.state.issueIndex}
            onCancel={() => this.props.toggleRequestIssueRemovalModal()}
            moveToPendingReviewSection={this.props.moveToPendingReviewSection}
            pendingIssueModificationRequest={this.state.pendingIssueModification}
            updatePendingReview={this.props.updatePendingReview}
          />
        )}

        {intakeData.requestIssueWithdrawalModalVisible && (
          <RequestIssueWithdrawalModal
            currentIssue={this.props.intakeForms[this.props.formType].addedIssues[this.state.issueIndex]}
            issueIndex={this.state.issueIndex}
            onCancel={() => this.props.toggleRequestIssueWithdrawalModal()}
            moveToPendingReviewSection={this.props.moveToPendingReviewSection}
            pendingIssueModificationRequest={this.state.pendingIssueModification}
            updatePendingReview={this.props.updatePendingReview}
          />
        )}

        {intakeData.requestIssueAdditionModalVisible && (
          <RequestIssueAdditionModal
            onCancel={() => this.props.toggleRequestIssueAdditionModal()}
            addToPendingReviewSection={this.props.addToPendingReviewSection}
            pendingIssueModificationRequest={this.state.pendingIssueModification}
            updatePendingReview={this.props.updatePendingReview}
          />
        )}

        {intakeData.cancelPendingRequestIssueModalVisible && (
          <CancelPendingRequestIssueModal
            pendingIssueModificationRequest={this.state.pendingIssueModification}
            onCancel={() => this.props.toggleCancelPendingRequestIssueModal()}
            removeFromPendingReviewSection={this.props.cancelOrRemovePendingReview}
            toggleCancelPendingRequestIssueModal={this.props.toggleCancelPendingRequestIssueModal}
          />
        )}

        {intakeData.confirmPendingRequestIssueModalVisible && (
          <ConfirmPendingRequestIssueModal
            pendingIssueModificationRequest={this.state.pendingIssueModification}
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

        <Table columns={columns} rowObjects={rowObjects} rowClassNames={additionalRowClasses} slowReRendersAreOk />

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
  setMstPactDetails: PropTypes.func,
  toggleAddDecisionDateModal: PropTypes.func,
  toggleAddingIssue: PropTypes.func,
  toggleAddIssuesModal: PropTypes.func,
  toggleCorrectionTypeModal: PropTypes.func,
  toggleIssueRemoveModal: PropTypes.func,
  toggleLegacyOptInModal: PropTypes.func,
  toggleNonratingRequestIssueModal: PropTypes.func,
  toggleUnidentifiedIssuesModal: PropTypes.func,
  toggleUntimelyExemptionModal: PropTypes.func,
  toggleEditIntakeIssueModal: PropTypes.func,
  undoCorrection: PropTypes.func,
  veteran: PropTypes.object,
  withdrawIssue: PropTypes.func,
  userCanWithdrawIssues: PropTypes.bool,
  userCanEditIntakeIssues: PropTypes.bool,
  userCanSplitAppeal: PropTypes.bool,
  isLegacy: PropTypes.bool,
  disableEditingForCompAndPen: PropTypes.bool
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
        setIssueWithdrawalDate,
        setMstPactDetails
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
    pendingIssueModificationRequests: getOpenPendingIssueModificationRequests(state),
    addingIssue: state.addingIssue,
    userCanWithdrawIssues: state.userCanWithdrawIssues,
    userCanEditIntakeIssues: state.userCanEditIntakeIssues,
    userIsVhaAdmin: state.userIsVhaAdmin,
    userCanSplitAppeal: state.userCanSplitAppeal,
    userCanRequestIssueUpdates: state.userCanRequestIssueUpdates,
    isLegacy: state.isLegacy,
    intakeFromVbms: state.intakeFromVbms
  }),
  (dispatch) =>
    bindActionCreators(
      {
        toggleAddDecisionDateModal,
        toggleAddingIssue,
        toggleIssueRemoveModal,
        toggleCorrectionTypeModal,
        toggleEditIntakeIssueModal,
        toggleRequestIssueModificationModal,
        toggleRequestIssueRemovalModal,
        toggleRequestIssueWithdrawalModal,
        toggleRequestIssueAdditionModal,
        toggleCancelPendingRequestIssueModal,
        toggleConfirmPendingRequestIssueModal,
        removeIssue,
        withdrawIssue,
        moveToPendingReviewSection,
        addToPendingReviewSection,
        cancelOrRemovePendingReview,
        updatePendingReview,
        setAllApprovedIssueModificationsWithdrawalDates,
        setIssueWithdrawalDate,
        setMstPactDetails,
        correctIssue,
        undoCorrection,
        toggleUnidentifiedIssuesModal,
        editEpClaimLabel,
        addIssue
      },
      dispatch
    )
)(AddIssuesPage);
