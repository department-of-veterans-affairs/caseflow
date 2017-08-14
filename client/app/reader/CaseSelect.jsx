import React from 'react';
import { connect } from 'react-redux';
import Table from '../components/Table';
import Link from '../components/Link';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';

import { getClaimTypeDetailInfo, generateIssueList } from '../reader/utils';
import { fetchAppealUsingVeteranId, clearLoadedAppeal, 
  clearReceivedAppeals, onReceiveAppealDetails, setCaseSelectSearch,
  clearCaseSelectSearch
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

  componentDidMount = () => this.props.clearLoadedAppeal();

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
    const appeal = _.find(this.props.receivedAppeals,
      { vacols_id: this.state.selectedAppealVacolsId });

    this.props.onReceiveAppealDetails(appeal);
  }

  handleChangeAppealSelection = (vacolsId) => {
    this.setState({ selectedAppealVacolsId: vacolsId });
  }

  render() {

    const { caseSelect } = this.props;

    if (this.props.loadedAppeal.vacols_id) {
      return <Redirect
        to={`/${this.props.loadedAppeal.vacols_id}/documents`}/>;
    }

    if (!this.props.assignments) {
      return null;
    }

    const createAppealOptions = (appeals) => {
      return appeals.map((appeal) => {
        return {
          displayText: <div>
            <strong>Veteran</strong> {appeal.veteran_full_name} <br />
            <strong>Veteran ID</strong> {appeal.vbms_id} <br />
            <strong>Issues</strong><br />
              <ol>
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
          <h1 id="welcome-header">Welcome to Reader!</h1>
            <div className="section-search">
              {caseSelect.search.showErrorMessage &&
                <Alert title="Veteran ID not found" type="error">
                  Please enter the correct Veteran ID and try again.
                </Alert>
              }
              <SearchBar
                id="search-small"
                size="small"
                onChange={this.props.setCaseSelectSearch}
                value={this.props.caseSelectCriteria.searchQuery}
                onClearSearch={this.props.clearCaseSelectSearch}
                onSubmit={this.searchOnChange}
              />
            </div>
          { _.size(this.props.receivedAppeals) ? <Modal
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
              options={createAppealOptions(this.props.receivedAppeals)}
              value={this.state.selectedAppealVacolsId}
              onChange={this.handleChangeAppealSelection}
              hideLabel={true}
            />
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
    clearLoadedAppeal,
    clearReceivedAppeals,
    onReceiveAppealDetails,
    setCaseSelectSearch,
    clearCaseSelectSearch
  }, dispatch)
});

const mapStateToProps = (state) => ({
  ..._.pick(state, 'assignments'),
  ..._.pick(state, 'loadedAppeal'),
  ..._.pick(state.ui, 'receivedAppeals'),
  ..._.pick(state.ui, 'caseSelect'),
  ..._.pick(state.ui, 'caseSelectCriteria')
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseSelect);
