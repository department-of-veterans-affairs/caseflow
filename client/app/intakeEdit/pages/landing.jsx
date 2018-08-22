import React, { Component } from 'react';
import { connect } from 'react-redux';
import Table from '../../components/Table';
import { FORM_TYPES } from '../../intake/constants'
import { formatDate } from '../../util/DateUtil';
import _ from 'lodash';

class Landing extends Component {
  render() {
    const {
      veteran,
      intake,
      formType
    } = this.props;

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const veteranInfo = `${veteran.name.first_name} ${veteran.name.last_name} (${veteran.fileNumber})`;

    const issueContent = (issues) =>  {
      return <SelectedIssues issues={issues} />
    }

    const editIssuesLink = (formType, claimId) => {
      const url = `/${formType}s/${claimId}/edit/select-issues`
      return <a href={url}>Edit issues <i className="fa fa-pencil" aria-hidden="true"></i></a>
    }

    const columns = [
      { valueName: 'field' },
      { valueName: 'content' },
      { valueName: 'link' }
    ];

    let rowObjects = [
      {field: 'Form being processed', content: selectedForm.name},
      {field: 'Veteran', content: veteranInfo},
      {field: 'Receipt date of this form', content: formatDate(intake.receiptDate)}
    ];

    if (formType == 'higher_level_review') {
      const higherLevelReviewRows = [
        {field: 'Informal conference request', content: intake.informalConference ? "Yes" : "No"},
        {field: 'Same office request', content: intake.sameOffice ? "Yes" : "No"}
      ]
      rowObjects = rowObjects.concat(higherLevelReviewRows)
    }

    const issuesRow = [{field: 'Issues', content: issueContent(intake.issues), link: editIssuesLink(formType, intake.claimId)}]

    rowObjects = rowObjects.concat(issuesRow)

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
};

class SelectedIssues extends React.PureComponent {
  render () {
    const issueListItems = _.map(this.props.issues, (issue, index) => {
      return (
        <li key={index}>{issue.description}</li>
      )
    })

    return (
      <ol>
      { issueListItems }
      </ol>
    )
  }
}

export default connect(
  ({ veteran, intake, formType }) => ({
    veteran: veteran,
    intake: intake,
    formType: formType
  })
)(Landing);
