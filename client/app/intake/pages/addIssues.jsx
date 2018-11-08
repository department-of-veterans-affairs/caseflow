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
import Button from '../../components/Button';
import ErrorAlert from '../components/ErrorAlert';
import { REQUEST_STATE, FORM_TYPES, PAGE_PATHS } from '../constants';
import INELIGIBLE_REQUEST_ISSUES from '../../../constants/INELIGIBLE_REQUEST_ISSUES.json';
import { formatDate } from '../../util/DateUtil';
import { formatAddedIssues, getAddIssuesFields } from '../util/issues';
import Table from '../../components/Table';
import {
  toggleAddIssuesModal,
  toggleUntimelyExemptionModal,
  toggleNonratingRequestIssueModal,
  removeIssue,
  toggleUnidentifiedIssuesModal,
  toggleIssueRemoveModal
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

  checkIfEligible = (issue, formType) => {
    if (issue.isUnidentified) {
      return false;
    } else if (issue.titleOfActiveReview) {
      return INELIGIBLE_REQUEST_ISSUES.duplicate_of_issue_in_active_review.replace(
        '{review_title}', issue.titleOfActiveReview
      );
    } else if (issue.ineligibleReason) {
      return INELIGIBLE_REQUEST_ISSUES[issue.ineligibleReason];
    } else if (issue.timely === false && formType !== 'supplemental_claim' && issue.untimelyExemption !== 'true') {
      return INELIGIBLE_REQUEST_ISSUES.untimely;
    } else if (issue.sourceHigherLevelReview && formType === 'higher_level_review') {
      return INELIGIBLE_REQUEST_ISSUES.previous_higher_level_review;
    }

    return true;
  }

  render() {
    const {
      intakeForms,
      formType,
      veteran
    } = this.props;

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const veteranInfo = `${veteran.name} (${veteran.fileNumber})`;
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
      let issues = formatAddedIssues(intakeData);

      return <div className="issues">
        <div>
          { issues.map((issue, index) => {
            let issueKlasses = ['issue-desc'];
            let isEligible = this.checkIfEligible(issue, formType);
            let addendum = '';

            if (isEligible !== true) {
              if (isEligible !== false) {
                addendum = isEligible;
              }
              issueKlasses.push('not-eligible');
            }

            return <div className="issue" key={`issue-${index}`}>
              <div className={issueKlasses.join(' ')}>
                <span className="issue-num">{index + 1}.&nbsp;</span>
                { issue.text } {addendum}
                { issue.date && <span className="issue-date">Decision date: { issue.date }</span> }
                { issue.notes && <span className="issue-notes">Notes:&nbsp;{ issue.notes }</span> }
                { issue.untimelyExemptionNotes &&
                  <span className="issue-notes">Untimely Exemption Notes:&nbsp;{issue.untimelyExemptionNotes}</span>
                }
              </div>
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
            onClick={this.props.toggleAddIssuesModal}
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

    let sharedFields = [
      { field: 'Form',
        content: selectedForm.name },
      { field: 'Veteran',
        content: veteranInfo },
      { field: 'Receipt date of this form',
        content: formatDate(intakeData.receiptDate) }
    ];

    let additionalFields = getAddIssuesFields(selectedForm.key, veteran, intakeData);
    let rowObjects = sharedFields.concat(additionalFields).concat(
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
        closeHandler={this.props.toggleNonratingRequestIssueModal} />
      }
      { intakeData.unidentifiedIssuesModalVisible && <UnidentifiedIssuesModal
        intakeData={intakeData}
        closeHandler={this.props.toggleUnidentifiedIssuesModal} />
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
  ({ intake, higherLevelReview, supplementalClaim, appeal }) => ({
    intakeForms: {
      higher_level_review: higherLevelReview,
      supplemental_claim: supplementalClaim,
      appeal
    },
    formType: intake.formType,
    veteran: intake.veteran
  }),
  (dispatch) => bindActionCreators({
    toggleAddIssuesModal,
    toggleUntimelyExemptionModal,
    toggleNonratingRequestIssueModal,
    toggleUnidentifiedIssuesModal,
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
    veteran: state.veteran
  }),
  (dispatch) => bindActionCreators({
    toggleAddIssuesModal,
    toggleUntimelyExemptionModal,
    toggleIssueRemoveModal,
    toggleNonratingRequestIssueModal,
    toggleUnidentifiedIssuesModal,
    removeIssue
  }, dispatch)
)(AddIssuesPage);
