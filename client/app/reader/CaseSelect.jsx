import React from 'react';
import { connect } from 'react-redux';
import Table from '../components/Table';
import Link from '../components/Link';
import _ from 'lodash';

import { getClaimTypeDetailInfo } from '../reader/utils';

import CaseSelectSearch from './CaseSelectSearch';

class CaseSelect extends React.PureComponent {

  renderIssuesColumnData = (appeal) => {
    const issues = appeal.issues || [];

    return (
      <ol className="issue-list">
        {issues.map((issue) => {
          const descriptionLabel = issue.levels ? `${issue.type.label}:` : issue.type.label;

          return <li key={issue.vacols_sequence_id}>
            {descriptionLabel}
            {this.renderIssueLevels(issue)}
          </li>;
        })}
      </ol>
    );
  }

  renderIssueLevels = (issue) => {
    const levels = issue.levels || [];

    return levels.map((level) => <p className="issue-level" key={level}>{level}</p>);
  }

  getVeteranNameAndClaimType = (appeal) => {
    return <span>{appeal.veteran_full_name} <br /> {getClaimTypeDetailInfo(appeal)}</span>;
  }

  getAssignmentColumn = () => [
    {
      header: 'Veteran',
      valueFunction: this.getVeteranNameAndClaimType
    },
    {
      header: 'Veteran ID',
      valueName: 'vbms_id'
    },
    {
      header: 'Issues',
      valueFunction: this.renderIssuesColumnData
    },
    {
      header: 'View claims folder',
      valueFunction: (row) => {
        let buttonText = 'New';
        let buttonType = 'primary';

        if (row.viewed) {
          buttonText = 'Continue';
          buttonType = 'secondary';
        }

        return <Link
            name="view doc"
            button={buttonType}
            to={`/${row.vacols_id}/documents`}>
              {buttonText}
            </Link>;
      }
    }
  ];

  getKeyForRow = (index, row) => row.vacols_id;

  render() {
    if (!this.props.assignments) {
      return null;
    }

    return <div className="usa-grid section--case-select">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <h1 className="welcome-header">Welcome to Reader!</h1>
          <CaseSelectSearch history={this.props.history} feedbackUrl={this.props.feedbackUrl}/>
          <p className="cf-lead-paragraph">
            Learn more about Reader on our <a href="/reader/help">FAQ page</a>.
          </p>
          <h2>Cases checked in</h2>
          <Table
            className="assignment-list"
            columns={this.getAssignmentColumn}
            rowObjects={this.props.assignments}
            summary="Cases checked in"
            getKeyForRow={this.getKeyForRow}
          />
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => _.pick(state.readerReducer, 'assignments');

export default connect(
  mapStateToProps
)(CaseSelect);
