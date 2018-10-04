import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import AddIssuesModal from '../components/AddIssuesModal';
import NonRatedIssueModal from '../components/NonRatedIssueModal';
import Button from '../../components/Button';
import { FORM_TYPES } from '../../intakeCommon/constants';
import { formatDate } from '../../util/DateUtil';
import { formatAddedIssues, getAddIssuesFields } from '../util';

import Table from '../../components/Table';
import { toggleAddIssuesModal } from '../actions/common';
import { toggleNonRatedIssueModal } from '../actions/common';
import { removeIssue } from '../actions/ama';

class AddIssues extends React.PureComponent {
  render() {
    const {
      intakeForms,
      formType,
      veteran
    } = this.props;

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const intakeData = intakeForms[selectedForm.key];
    const veteranInfo = `${veteran.name} (${veteran.fileNumber})`;

    const issuesComponent = () => {
      let issues = formatAddedIssues(intakeData);

      return <div className="issues">
        <div>
          { issues.map((issue, index) => {
            return <div className="issue" key={issue.referenceId}>
              <div className="issue-desc">
                <span className="issue-num">{index + 1}.</span>
                {issue.text}
                <span className="issue-notes">{issue.notes}</span>
              </div>
              <div className="issue-action">
                <Button
                  onClick={() => this.props.removeIssue(issue)}
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
        closeHandler={this.props.toggleAddIssuesModal} />
      }
      { intakeData.nonRatedIssueModalVisible && <NonRatedIssueModal
        closeHandler={this.props.toggleNonRatedIssueModal} />
      }
      <h1 className="cf-txt-c">Add Issues</h1>

      <Table
        columns={columns}
        rowObjects={rowObjects}
        slowReRendersAreOk />
    </div>;
  }
}

export default connect(
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
    toggleNonRatedIssueModal
    removeIssue
  }, dispatch)
)(AddIssues);
