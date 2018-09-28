import _ from 'lodash';
import React from 'react';
import { connect } from 'react-redux';

import Button from '../../components/Button';
import { FORM_TYPES } from '../../intakeCommon/constants';
import { formatDate } from '../../util/DateUtil';
import { getAddIssuesFields } from '../util';
import Table from '../../components/Table';

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

    // this is a dummy button to be implemented in a later ticket
    const issueButton = () => {
      return <Button
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
        content: issueButton() }
    );

    return <div className="cf-intake-edit">
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
  })
)(AddIssues);
