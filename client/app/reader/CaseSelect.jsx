import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Table from '../components/Table';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { getClaimTypeDetailInfo } from '../reader/utils';
import { clearSearch, clearAllFilters } from './DocumentList/DocumentListActions';

import CaseSelectSearch from './CaseSelectSearch';
import IssueList from './IssueList';

class CaseSelect extends React.PureComponent {

  renderIssuesColumnData = (appeal) =>
    <IssueList
      appeal={appeal}
      formatLevelsInNewLine
      tightLevelStyling
      className="issue-list"
    />;

  getVeteranNameAndClaimType = (appeal) =>
    <span>{appeal.veteran_full_name} <br /> {getClaimTypeDetailInfo(appeal)}</span>;

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

  componentDidMount = () => {
    this.props.clearSearch();
    this.props.clearAllFilters();
  }

  render() {
    if (!this.props.assignments) {
      return null;
    }

    return <AppSegment filledBackground>
      <div className="section--case-select">
        <h1 className="welcome-header">Welcome to Reader!</h1>
        <CaseSelectSearch navigateToPath={this.props.history.push} feedbackUrl={this.props.feedbackUrl} />
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
    </AppSegment>;
  }
}

const mapStateToProps = (state) => _.pick(state.caseSelect, 'assignments');

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearSearch,
    clearAllFilters
  }, dispatch)
);

export default connect(
  mapStateToProps, mapDispatchToProps
)(CaseSelect);
