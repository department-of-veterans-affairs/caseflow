import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import { generateIssueList } from '../reader/utils';
import { fetchAppealUsingVeteranId,
  clearReceivedAppeals, onReceiveAppealDetails, setCaseSelectSearch,
  clearCaseSelectSearch, caseSelectAppeal, clearSelectedAppeal
} from './actions';

import SearchBar from '../components/SearchBar';
import Modal from '../components/Modal';
import RadioField from '../components/RadioField';
import Alert from '../components/Alert';

class CaseSelectSearch extends React.PureComponent {

  constructor() {
    super();
    this.state = {
      selectedAppealVacolsId: null
    };
  }

  componentDidUpdate = () => {
    if (this.props.caseSelect.selectedAppeal.vacols_id) {
      this.props.history.push(`/${this.props.caseSelect.selectedAppeal.vacols_id}/documents`);
      this.props.clearCaseSelectSearch();
      this.props.clearReceivedAppeals();
      this.props.clearSelectedAppeal();
    }
  };

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


  searchOnChange = (text) => {
    if (_.size(text)) {
      this.props.fetchAppealUsingVeteranId(text);
    }
  }

  render() {

    const { caseSelect } = this.props;

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

    return <div className="section-search">
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
)(CaseSelectSearch);
