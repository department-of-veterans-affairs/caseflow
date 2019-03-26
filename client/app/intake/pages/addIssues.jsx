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
import AddedIssue from '../components/AddedIssue';
import ErrorAlert from '../components/ErrorAlert';
import { REQUEST_STATE, PAGE_PATHS, VBMS_BENEFIT_TYPES } from '../constants';
import { formatAddedIssues, getAddIssuesFields } from '../util/issues';
import Table from '../../components/Table';
import {
  toggleAddIssuesModal,
  toggleUntimelyExemptionModal,
  toggleNonratingRequestIssueModal,
  removeIssue,
  toggleUnidentifiedIssuesModal,
  toggleIssueRemoveModal,
  toggleLegacyOptInModal
} from '../actions/addIssues';

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

  haveIssuesChanged = (currentIssues) => {
    if (currentIssues.length !== this.state.originalIssueLength) {
      return true;
    }

    // if any issues do not have ids, it means the issue was just added
    if (currentIssues.filter((currentIssue) => !currentIssue.id).length > 0) {
      return true;
    }

    return false;
  }

  onRemoveClick = (index, option = 'remove') => {
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
    }
  }

  onClickAddIssue = (ratingIssueCount) => {
    if (!ratingIssueCount) {
      return this.props.toggleNonratingRequestIssueModal;
    }

    return this.props.toggleAddIssuesModal;
  }

  render() {
    const {
      intakeForms,
      formType,
      veteran,
      featureToggles
    } = this.props;

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    const { useAmaActivationDate, withdrawDecisionReviews } = featureToggles;
    const intakeData = intakeForms[formType];
    const requestState = intakeData.requestStatus.completeIntake || intakeData.requestStatus.requestIssuesUpdate;
    const requestErrorCode = intakeData.completeIntakeErrorCode || intakeData.requestIssuesUpdateErrorCode;
    const showInvalidVeteranError = !intakeData.veteranValid && (_.some(
      intakeData.addedIssues, (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId)
    );

    if (intakeData.isDtaError) {
      return <Redirect to={PAGE_PATHS.DTA_CLAIM} />;
    }

    if (intakeData.hasClearedEP) {
      return <Redirect to={PAGE_PATHS.CLEARED_EPS} />;
    }

    if (intakeData.isOutcoded) {
      return <Redirect to={PAGE_PATHS.OUTCODED} />;
    }

    const issuesComponent = () => {
      let issues = formatAddedIssues(intakeData, useAmaActivationDate);

      const issueActionOptions = [
        { displayText: 'Withdraw issue',
          value: 'withdraw' },
        { displayText: 'Remove issue',
          value: 'remove' }
      ];

      return <div className="issues">
        <div>
          { issues.map((issue, index) => {
            return <div
              className="issue"
              data-key={`issue-${index}`}
              key={`issue-${index}`}
              id={`issue-${issue.referenceId}`}>
              <AddedIssue
                issue={issue}
                issueIdx={index}
                requestIssues={intakeData.requestIssues}
                legacyOptInApproved={intakeData.legacyOptInApproved}
                legacyAppeals={intakeData.legacyAppeals}
                formType={formType} />
              <div className="issue-action">
                { withdrawDecisionReviews && <Dropdown
                  name={`issue-action-${index}`}
                  label="Actions"
                  hideLabel
                  options={issueActionOptions}
                  defaultText="Select action"
                  onChange={(option) => this.onRemoveClick(index, option)}
                />
                }
                { !withdrawDecisionReviews && <Button
                  onClick={() => this.onRemoveClick(index)}
                  classNames={['cf-btn-link', 'remove-issue']}
                >
                  <i className="fa fa-trash-o" aria-hidden="true"></i><br />Remove
                </Button>
                }
              </div>
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

    const columns = [
      { valueName: 'field' },
      { valueName: 'content' }
    ];

    let fieldsForFormType = getAddIssuesFields(formType, veteran, intakeData);
    let issueChangeClassname = () => {
      // no-op unless the issue banner needs to be displayed
    };

    if (this.props.editPage && this.haveIssuesChanged(intakeData.addedIssues)) {
      // flash a save message if user is on the edit page & issues have changed
      const issuesChangedBanner = <p>When you finish making changes, click "Save" to continue.</p>;

      fieldsForFormType = fieldsForFormType.concat(
        { field: '',
          content: issuesChangedBanner });
      issueChangeClassname = (rowObj) => rowObj.field === '' ? 'intake-issue-flash' : '';
    }

    let rowObjects = fieldsForFormType.concat(
      { field: 'Requested issues',
        content: issuesComponent() });

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
      <h1 className="cf-txt-c">Add / Remove Issues</h1>

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
    removeIssue
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
    removeIssue
  }, dispatch)
)(AddIssuesPage);
