import React, { Component } from 'react';
import { connect } from 'react-redux';
import Table from '../../components/Table';
import { FORM_TYPES } from '../../intakeCommon/constants';
import { formatDate } from '../../util/DateUtil';
import _ from 'lodash';

class Landing extends Component {
  render() {
    const {
      review,
      formType
    } = this.props;

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const veteranInfo = `${review.veteranName} (${review.veteranFileNumber})`;

    const issueContent = (issues) => {
      return <SelectedIssues issues={issues} />;
    };

    const editIssuesLink = () => {
      const url = `/${formType}s/${review.claimId}/edit/select_issues`;

      return (
        <a className="cf-edit-issues-link" href={url}>
          Edit issues <i className="fa fa-pencil" aria-hidden="true"></i>
        </a>
      );
    };

    const columns = [
      { valueName: 'field' },
      { valueName: 'content' },
      { valueName: 'link' }
    ];

    let rowObjects = [
      { field: 'Form being processed',
        content: selectedForm.name },
      { field: 'Veteran',
        content: veteranInfo },
      { field: 'Receipt date of this form',
        content: formatDate(review.receiptDate) }
    ];

    if (formType === 'higher_level_review') {
      const higherLevelReviewRows = [
        { field: 'Informal conference request',
          content: review.informalConference ? 'Yes' : 'No' },
        { field: 'Same office request',
          content: review.sameOffice ? 'Yes' : 'No' }
      ];

      rowObjects = rowObjects.concat(higherLevelReviewRows);
    }

    const issuesRow = [{ field: 'Issues',
      content: issueContent(review.issues),
      link: editIssuesLink() }];

    rowObjects = rowObjects.concat(issuesRow);

    return <div className="cf-intake-edit">
      <h1 className="cf-txt-c">Edit Claim Issues</h1>
      <p className="cf-txt-c">Use Caseflow to add or remove issues (contentions) for this EP.</p>
      <p className="cf-txt-c">You can edit additional details about the claim directly in VBMS.</p>

      <Table
        columns={columns}
        rowObjects={rowObjects}
        slowReRendersAreOk />
    </div>;
  }
}

class SelectedIssues extends React.PureComponent {
  render () {
    const issueListItems = _.map(this.props.issues, (issue, index) => {
      return (
        <li key={index}>{issue.description}</li>
      );
    });

    return (
      <ol>
        { issueListItems }
      </ol>
    );
  }
}

export default connect(
  ({ review, formType }) => ({
    review,
    formType
  })
)(Landing);
