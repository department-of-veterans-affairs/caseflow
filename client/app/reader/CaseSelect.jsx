import React from 'react';
import { connect } from 'react-redux';
import Table from '../components/Table';
import Link from '../components/Link';
import _ from 'lodash';
import { bindActionCreators } from 'redux';

import { getClaimTypeDetailInfo, generateIssueList } from '../reader/utils';
import { fetchAppealUsingVeteranId,
  clearReceivedAppeals, onReceiveAppealDetails, setCaseSelectSearch,
  clearCaseSelectSearch, caseSelectAppeal, clearSelectedAppeal
} from './actions';

import SearchBar from '../components/SearchBar';
import Modal from '../components/Modal';
import RadioField from '../components/RadioField';
import Alert from '../components/Alert';

class CaseSelect extends React.PureComponent {

  constructor() {
    super();
    this.state = {
      selectedAppealVacolsId: null
    };
  }

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
    if (_.size(text)) {
      this.props.fetchAppealUsingVeteranId(text);
    }
  }

  handleModalClose = () => {
    // clearing the state of the modal
    this.setState({ selectedAppealVacolsId: null });
    this.props.clearCaseSelectSearch();
    this.props.clearReceivedAppeals();
  }

  handleSelectAppeal = () => {
    const appeal = _.find(this.props.caseSelect.receivedAppeals,
      { vacols_id: this.state.selectedAppealVacolsId });

    this.props.caseSelectAppeal(appeal);
  }

  handleChangeAppealSelection = (vacolsId) => {
    this.setState({ selectedAppealVacolsId: vacolsId });
  }

  render() {

    const { caseSelect } = this.props;

    if (caseSelect.selectedAppeal.vacols_id) {
      this.props.history.push(`/${caseSelect.selectedAppeal.vacols_id}/documents`);
      this.props.clearCaseSelectSearch();
      this.props.clearReceivedAppeals();
      this.props.clearSelectedAppeal();
    }

    if (!this.props.assignments) {
      return null;
    }

    const createAppealOptions = (appeals) => {
      return appeals.map((appeal) => {
        return {
          displayText: <div className="folder-option">
            <strong>Veteran</strong> {appeal.veteran_full_name} <br />
            <strong>Veteran ID</strong> {appeal.vbms_id} <br />
            <strong>Issues</strong><br />
              <ol className="issues">
                {generateIssueList(appeal)}
              </ol>
          </div>,
          value: appeal.vacols_id
        };
      });
    };

    return <div className="usa-grid section--case-select">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <h1 className="welcome-header">Welcome to Reader!</h1>
            <div className="section-search">
              {caseSelect.search.showErrorMessage &&
                <Alert title="Veteran ID not found" type="error">
                  Please enter the correct Veteran ID and try again.
                </Alert>
              }
              <SearchBar
                id="searchBar"
                size="small"
                onChange={this.props.setCaseSelectSearch}
                value={this.props.caseSelectCriteria.searchQuery}
                onClearSearch={this.props.clearCaseSelectSearch}
                onSubmit={this.searchOnChange}
                allowInputSubmission={true}
              />
            </div>
          { _.size(caseSelect.receivedAppeals) ? <Modal
            buttons = {[
              { classNames: ['cf-modal-link', 'cf-btn-link'],
                name: 'Cancel',
                onClick: this.handleModalClose
              },
              { classNames: ['usa-button', 'usa-button-primary'],
                name: 'Okay',
                onClick: this.handleSelectAppeal,
                disabled: _.isEmpty(this.state.selectedAppealVacolsId)
              }
            ]}
            closeHandler={this.handleModalClose}
            title = "Select claims folder">
            <RadioField
              name="claims-folder-select"
              options={createAppealOptions(caseSelect.receivedAppeals)}
              value={this.state.selectedAppealVacolsId}
              onChange={this.handleChangeAppealSelection}
              hideLabel={true}
            />
            <p>
              Not seeing what you expected? <a
                name="feedbackUrl"
                ariaLabel="open document in new tab"
                href={this.props.feedbackUrl}>
                Please send us feedback.
              </a>
            </p>
          </Modal> : ''
          }
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
  ...bindActionCreators({
    fetchAppealUsingVeteranId,
    clearReceivedAppeals,
    onReceiveAppealDetails,
    setCaseSelectSearch,
    clearCaseSelectSearch,
    caseSelectAppeal,
    clearSelectedAppeal
  }, dispatch)
});

const mapStateToProps = (state) => ({
  ..._.pick(state, 'assignments'),
  ..._.pick(state.ui, 'caseSelect'),
  ..._.pick(state.ui, 'caseSelectCriteria')
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseSelect);
