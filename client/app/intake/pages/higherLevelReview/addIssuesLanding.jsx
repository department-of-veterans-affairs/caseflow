import React, { Component } from 'react';
import { connect } from 'react-redux';
import Table from '../../../components/Table';
import Button from '../../../components/Button';
import { FORM_TYPES } from '../../../intakeCommon/constants';
import { formatDate } from '../../../util/DateUtil';
import _ from 'lodash';

class AddIssuesLanding extends Component {
  render() {
    const {
      higherLevelReview,
      formType,
      veteran
    } = this.props;

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const veteranInfo = `${veteran.name} (${veteran.fileNumber})`;

    const issueButton = () => {
      return
      <Button
        name="add-issue"
        legacyStyling={false}
        classNames={['usa-button-secondary']}>
        + Add issue
      </Button>;
    };

    const columns = [
      { valueName: 'field' },
      { valueName: 'content' }
    ];

    let rowObjects = [
      { field: 'Form being processed',
        content: selectedForm.name },
      { field: 'Veteran',
        content: veteranInfo },
      { field: 'Receipt date of this form',
        content: formatDate(higherLevelReview.receiptDate) },
      { field: 'Benefit type',
        content: higherLevelReview.benefitType },
      { field: 'Informal conference request',
        content: higherLevelReview.informalConference ? 'Yes' : 'No' },
      { field: 'Same office request',
        content: higherLevelReview.sameOffice ? 'Yes' : 'No' },
      { field: 'Claimant',
        content: higherLevelReview.claimant }, // Needs work, and clarification on Mock up
      { field: 'Requested issues',
        content: issueButton() }
    ];

    return <div className="cf-intake-edit"> // Generalize the style name?
      <h1 className="cf-txt-c">Add Issues</h1>

      <Table
        columns={columns}
        rowObjects={rowObjects}
        slowReRendersAreOk />
    </div>;
  }
}

export default connect(
  ({ state }) => ({
    higherLevelReview: state.higherLevelReview,
    formType: state.intake.formType,
    veteran: state.intake.veteran
  })
)(AddIssuesLanding);
