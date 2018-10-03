import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import AddIssuesModal from '../components/AddIssuesModal';
import Button from '../../components/Button';
import { FORM_TYPES } from '../../intakeCommon/constants';
import { formatDate } from '../../util/DateUtil';
import { formatAddedIssues, getAddIssuesFields } from '../util';

import Table from '../../components/Table';
import { toggleAddIssuesModal } from '../actions/common';
import { removeIssue } from '../actions/ama';

class AddIssues extends React.PureComponent {

  onRemoveIssue = (issue) => {
    this.props.removeIssue(issue);
  }

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

      return <table className="usa-table-borderless issues">
        <tbody>
          { issues.map((issue, index) => {
            return <tr className="issue" key={issue.referenceId}>
              <td>{index + 1}. {issue.text} {issue.notes}</td>
              <td className="cf-text-r">
                <Button
                  onClick={() => this.onRemoveIssue(issue)}
                  classNames={['cf-btn-link', 'remove-issue']}
                >
                  <i className="fa fa-trash-o" aria-hidden="true"></i>Remove
                </Button>
              </td>
            </tr>;
          })}
        </tbody>
        <tfoot>
          <tr>
            <td colSpan="2">
              <Button
                name="add-issue"
                legacyStyling={false}
                classNames={['usa-button-secondary']}
                onClick={this.props.toggleAddIssuesModal}
              >
                + Add issue
              </Button>
            </td>
          </tr>
        </tfoot>
      </table>;
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
        ratings={intakeData.ratings}
        closeHandler={this.props.toggleAddIssuesModal} />
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
    removeIssue
  }, dispatch)
)(AddIssues);
