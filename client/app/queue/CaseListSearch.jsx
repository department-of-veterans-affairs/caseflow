import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import PropTypes from 'prop-types';

import {
  clearCaseListSearch,
  fetchAppealsUsingVeteranId,
  setCaseListSearch
} from './CaseList/CaseListActions';

// TODO: Get rid of the reader/CaseSelect actions when everybody is using appeals search.
import { caseSelectAppeal, caseSelectModalSelectVacolsId } from '../reader/CaseSelect/CaseSelectActions';
import IssueList from '../reader/IssueList';

import Alert from '../components/Alert';
import Modal from '../components/Modal';
import RadioField from '../components/RadioField';
import SearchBar from '../components/SearchBar';

class CaseSelectSearch extends React.PureComponent {
  handleModalClose = () => {
    // clearing the state of the modal in redux
    this.props.clearCaseListSearch();
  }

  searchOnChange = (text) => {
    if (_.size(text)) {
      this.props.fetchAppealsUsingVeteranId(text);
    }
  }

  //
  // TODO: Remove everything below here once everybody is using the new appeal search.
  // 

  // TODO: Do we want to take any actions for the new appeals search on component update?
  componentDidUpdate = () => {
    if (!this.props.caseList.shouldUseAppealSearch) {
      this.handleNonQueueSearchUpdate()
    }
  };

  handleNonQueueSearchUpdate = () => {
    if (!this.props.alwaysShowCaseSelectionModal) {
      // if only one appeal is received for the veteran id
      // select that appeal's case.
      if (_.size(this.props.caseList.receivedAppeals) === 1) {
        this.props.caseSelectAppeal(this.props.caseList.receivedAppeals[0]);
      }
    }

    // when an appeal is selected using claim search,
    // this method redirects to the claim folder page
    // and also does a bit of store clean up.
    if (this.props.caseSelect.selectedAppeal.vacols_id) {
      this.props.navigateToPath(`/${this.props.caseSelect.selectedAppeal.vacols_id}/documents`);
      this.props.clearCaseListSearch();
    }
  }

  handleSelectAppeal = () => {
    // get the appeal selected from the modal
    const appeal = _.find(this.props.caseList.receivedAppeals,
      { vacols_id: this.props.caseSelect.selectedAppealVacolsId });

    // set the selected appeal
    this.props.caseSelectAppeal(appeal);
  }

  handleChangeAppealSelection = (vacolsId) =>
    this.props.caseSelectModalSelectVacolsId(vacolsId);

  // TODO: Work on refactoring this after we get the old way up and running.
  render() {
    const { caseList, caseSelect } = this.props;

    const createAppealOptions = (appeals) =>
      appeals.map((appeal) => ({
        displayText: <div className="folder-option">
          <strong>Veteran</strong> {appeal.veteran_full_name} <br />
          <strong>Veteran ID</strong> {appeal.vbms_id} <br />
          <strong>Issues</strong><br />
          <ol className="issues">
            <IssueList appeal={appeal} />
          </ol>
        </div>,
        value: appeal.vacols_id
      }));

    const modalShowThreshold = this.props.alwaysShowCaseSelectionModal ? 0 : 1;

    return <div className="section-search" {...this.props.styling}>
      {caseList.search.showErrorMessage &&
        <Alert title="Veteran ID not found" type="error">
          Please enter a valid Veteran ID and try again.
        </Alert>
      }
      {caseList.search.noAppealsFoundSearchQueryValue &&
        <Alert title="No appeals found" type="info">
          {`Veteran ID ${caseList.search.noAppealsFoundSearchQueryValue} does not have any appeals.`}
        </Alert>
      }
      <SearchBar
        id="searchBar"
        size={this.props.searchSize}
        onChange={this.props.setCaseListSearch}
        value={caseList.caseListCriteria.searchQuery}
        onClearSearch={this.props.clearCaseListSearch}
        onSubmit={this.searchOnChange}
        loading={caseList.isRequestingAppealsUsingVeteranId}
        submitUsingEnterKey
      />
      { !this.props.caseList.shouldUseAppealSearch && Boolean(_.size(caseList.receivedAppeals) > modalShowThreshold) && <Modal
        buttons = {[
          { classNames: ['cf-modal-link', 'cf-btn-link'],
            name: 'Cancel',
            onClick: this.handleModalClose
          },
          { classNames: ['usa-button', 'usa-button-primary'],
            name: 'Okay',
            onClick: this.handleSelectAppeal,
            disabled: _.isEmpty(caseSelect.selectedAppealVacolsId)
          }
        ]}
        closeHandler={this.handleModalClose}
        title = "Select claims folder">
        <RadioField
          name="claims-folder-select"
          options={createAppealOptions(caseList.receivedAppeals)}
          value={caseSelect.selectedAppealVacolsId}
          onChange={this.handleChangeAppealSelection}
          hideLabel
        />
        <p>
          Not seeing what you expected? <a
            name="feedbackUrl"
            href={this.props.feedbackUrl}>
            Please send us feedback.
          </a>
        </p>
      </Modal>
      }
    </div>;
  }
}

CaseSelectSearch.propTypes = {
  searchSize: PropTypes.string,
  styling: PropTypes.object,
  navigateToPath: PropTypes.func.isRequired,
  alwaysShowCaseSelectionModal: PropTypes.bool
};

CaseSelectSearch.defaultProps = {
  searchSize: 'small',
  alwaysShowCaseSelectionModal: false
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  caseSelectAppeal,
  caseSelectModalSelectVacolsId,
  clearCaseListSearch,
  fetchAppealsUsingVeteranId,
  setCaseListSearch,
}, dispatch);

const mapStateToProps = (state) => ({
  caseList: state.caseList,
  caseSelect: state.caseSelect,
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseSelectSearch);
