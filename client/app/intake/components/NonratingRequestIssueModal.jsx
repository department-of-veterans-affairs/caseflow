import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import {
  addNonratingRequestIssue,
  toggleUnidentifiedIssuesModal,
  toggleUntimelyExemptionModal,
  toggleLegacyOptInModal
} from '../actions/addIssues';
import Modal from '../../components/Modal';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import DateSelector from '../../components/DateSelector';
import { NONRATING_REQUEST_ISSUE_CATEGORIES } from '../constants';

class NonratingRequestIssueModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      category: '',
      description: '',
      decisionDate: ''
    };
  }

  categoryOnChange = (value) => {
    this.setState({
      category: value
    });
  }

  descriptionOnChange = (value) => {
    this.setState({
      description: value
    });
  }

  decisionDateOnChange = (value) => {
    this.setState({
      decisionDate: value
    });
  }

  hasLegacyIssues = () => {
    return this.props.intakeData.legacyIssues.length > 0;
  }

  getNextButtonText = () => {
    if (this.hasLegacyIssues()) {
      return 'Next';
    }

    return 'Add this issue';
  }

  requiresUntimelyExemption = () => {
    if (this.props.formType === 'supplemental_claim') {
      return false;
    }

    const ONE_YEAR_PLUS_MS = 1000 * 60 * 60 * 24 * 372;

    // we must do our own date math for nonrating request issues.
    // we assume the timezone of the browser for all these.
    let decisionDate = new Date(this.state.decisionDate);
    let receiptDate = new Date(this.props.intakeData.receiptDate);
    let isTimely = (receiptDate - decisionDate) <= ONE_YEAR_PLUS_MS;

    return !isTimely;
  }

  onAddIssue = () => {
    const currentIssue = {
      category: this.state.category.value,
      description: this.state.description,
      decisionDate: this.state.decisionDate,
      isRating: false
    };

    if (this.hasLegacyIssues()) {
      this.props.toggleLegacyOptInModal({
        currentIssue,
        notes: null });
    } else if (this.requiresUntimelyExemption()) {
      this.props.toggleUntimelyExemptionModal({
        currentIssue,
        notes: null
      });
    } else {
      this.props.addNonratingRequestIssue({
        category: this.state.category.value,
        description: this.state.description,
        decisionDate: this.state.decisionDate,
        timely: true
      });
      this.props.closeHandler();
    }
  }

  render() {
    let {
      intakeData,
      closeHandler
    } = this.props;

    const { category, description, decisionDate } = this.state;
    const issueNumber = (intakeData.addedIssues || []).length + 1;
    const requiredFieldsMissing = !description || !category || !decisionDate;

    return <div className="intake-add-issues">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel adding this issue',
            onClick: closeHandler
          },
          { classNames: ['usa-button', 'add-issue'],
            name: this.getNextButtonText(),
            onClick: this.onAddIssue,
            disabled: requiredFieldsMissing
          },
          { classNames: ['usa-button', 'usa-button-secondary', 'no-matching-issues'],
            name: 'None of these match, see more options',
            onClick: this.props.toggleUnidentifiedIssuesModal
          }
        ]}
        visible
        closeHandler={closeHandler}
        title={`Add issue ${issueNumber}`}
      >
        <div>
          <h2>
            Does issue {issueNumber} match any of these issue categories?
          </h2>
          <div className="add-nonrating-request-issue">
            <SearchableDropdown
              name="issue-category"
              label="Issue category"
              strongLabel
              placeholder="Select or enter..."
              options={NONRATING_REQUEST_ISSUE_CATEGORIES}
              value={category}
              onChange={this.categoryOnChange} />

            <div className="decision-date">
              <DateSelector
                name="decision-date"
                label="Decision date"
                strongLabel
                value={decisionDate}
                onChange={this.decisionDateOnChange} />
            </div>

            <TextField
              name="Issue description"
              strongLabel
              value={description}
              onChange={this.descriptionOnChange} />
          </div>
        </div>
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    addNonratingRequestIssue,
    toggleUnidentifiedIssuesModal,
    toggleUntimelyExemptionModal,
    toggleLegacyOptInModal
  }, dispatch)
)(NonratingRequestIssueModal);
