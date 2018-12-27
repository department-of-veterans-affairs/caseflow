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
import AddedIssue from '../components/AddedIssue';
import ErrorAlert from '../components/ErrorAlert';
import { REQUEST_STATE, FORM_TYPES, PAGE_PATHS } from '../constants';
import { formatDate } from '../../util/DateUtil';
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

    this.state = {
      issueRemoveIndex: 0
    };
  }

  onRemoveClick = (index) => {
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

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const { useAmaActivationDate } = featureToggles;
    const intakeData = intakeForms[selectedForm.key];
    const requestState = intakeData.requestStatus.completeIntake || intakeData.requestStatus.requestIssuesUpdate;
    const requestErrorCode = intakeData.completeIntakeErrorCode || intakeData.requestIssuesUpdateErrorCode;

    if (intakeData.isDtaError) {
      return <Redirect to={PAGE_PATHS.DTA_CLAIM} />;
    }

    if (intakeData.hasClearedEP) {
      return <Redirect to={PAGE_PATHS.CLEARED_EPS} />;
    }

    const issuesComponent = () => {
      let issues = formatAddedIssues(intakeData, useAmaActivationDate);

      return <div className="issues">
        <div>
          { issues.map((issue, index) => {
            return <div className="issue" key={`issue-${index}`}>
              <AddedIssue
                issue={issue}
                issueIdx={index}
                requestIssues={intakeData.requestIssues}
                legacyOptInApproved={intakeData.legacyOptInApproved}
                legacyAppeals={intakeData.legacyAppeals}
                formType={formType} />
              <div className="issue-action">
                <Button
                  onClick={() => this.onRemoveClick(index)}
                  classNames={['cf-btn-link', 'remove-issue']}
                >
                  <i className="fa fa-trash-o" aria-hidden="true"></i>Remove
                </Button>
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

    let fieldsForFormType = getAddIssuesFields(selectedForm.key, veteran, intakeData);
    let rowObjects = fieldsForFormType.concat(
      { field: 'Requested issues',
        content: issuesComponent() }
    );

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

      <Table
        columns={columns}
        rowObjects={rowObjects}
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
    featureToggles: state.featureToggles
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
