import React from 'react';
import { connect } from 'react-redux';
import Table from '../components/Table';
import Link from '../components/Link';
import _ from 'lodash';

import { getClaimTypeDetailInfo } from '../reader/utils';
import { fetchAppealUsingVeteranId } from './actions';

import SearchBar from '../components/SearchBar';

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

  searchOnChange = (text) => {
    console.log(text);
    this.props.fetchAppealUsingVeteranId(text);
  }

  render() {
    if (!this.props.assignments) {
      return null;
    }

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Welcome to Reader!</h1>
          <SearchBar
            id="search-small"
            size="small"
            onChange={this.searchOnChange}
            loading={false}
          />
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

const mapDispatchToProps = (dispatch) => ({
  fetchAppealUsingVeteranId(veteranId) {
    dispatch(fetchAppealUsingVeteranId(veteranId));
  }
});

const mapStateToProps = (state) => ({
  ..._.pick(state, 'assignments'),
  ..._.pick(state, 'appeals')
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseSelect);
