import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { fetchAppealUsingVeteranId,
  onReceiveAppealDetails, setCaseSelectSearch,
  clearCaseSelectSearch, caseSelectAppeal,
  caseSelectModalSelectVacolsId
} from './actions';

import SearchBar from '../components/SearchBar';
import Modal from '../components/Modal';
import RadioField from '../components/RadioField';
import IssuesList from './IssueList';
import Alert from '../components/Alert';

class CaseSelectSearch extends React.PureComponent {

  componentDidUpdate = () => {

    // when an appeal is selected using claim search,
    // this method redirects to the claim folder page
    // and also does a bit of store clean up.
    if (this.props.caseSelect.selectedAppeal.vacols_id) {
      this.props.history.push(`/${this.props.caseSelect.selectedAppeal.vacols_id}/documents`);
      this.props.clearCaseSelectSearch();
    }
  };

  handleModalClose = () => {
    // clearing the state of the modal in redux
    this.props.clearCaseSelectSearch();
  }

  handleSelectAppeal = () => {
    // get the appeal selected from the modal
    const appeal = _.find(this.props.caseSelect.receivedAppeals,
      { vacols_id: this.props.caseSelect.selectedAppealVacolsId });

    // set the selected appeal
    this.props.caseSelectAppeal(appeal);
  }

  handleChangeAppealSelection = (vacolsId) =>
    this.props.caseSelectModalSelectVacolsId(vacolsId);

  searchOnChange = (text) => {
    if (_.size(text)) {
      this.props.fetchAppealUsingVeteranId(text);
    }
  }

  render() {
    const { caseSelect } = this.props;

    const createAppealOptions = (appeals) =>
      appeals.map((appeal) => ({
        displayText: <div className="folder-option">
          <strong>Veteran</strong> {appeal.veteran_full_name} <br />
          <strong>Veteran ID</strong> {appeal.vbms_id} <br />
          <strong>Issues</strong><br />
            <ol className="issues">
              <IssuesList appeal={appeal} />
            </ol>
        </div>,
        value: appeal.vacols_id
      }));

    return <div className="section-search">
      {caseSelect.search.showErrorMessage &&
        <Alert title="Veteran ID not found" type="error">
          Please enter the correct Veteran ID and try again.
        </Alert>
      }
      {caseSelect.search.showNoAppealsInfo &&
        <Alert title="No appeals found" type="info">
          {`Veteran ID ${this.props.caseSelectCriteria.searchQuery} does not have any appeals.`}
        </Alert>
      }
      <SearchBar
        id="searchBar"
        size="small"
        onChange={this.props.setCaseSelectSearch}
        value={this.props.caseSelectCriteria.searchQuery}
        onClearSearch={this.props.clearCaseSelectSearch}
        onSubmit={this.searchOnChange}
        submitUsingEnterKey
      />
      { Boolean(_.size(caseSelect.receivedAppeals)) && <Modal
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
          options={createAppealOptions(caseSelect.receivedAppeals)}
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


const mapDispatchToProps = (dispatch) => bindActionCreators({
  fetchAppealUsingVeteranId,
  onReceiveAppealDetails,
  setCaseSelectSearch,
  clearCaseSelectSearch,
  caseSelectAppeal,
  caseSelectModalSelectVacolsId
}, dispatch);

const mapStateToProps = (state) => ({
  caseSelect: state.ui.caseSelect,
  caseSelectCriteria: state.ui.caseSelectCriteria
});


export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseSelectSearch);
