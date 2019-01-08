import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import {
  addNonratingRequestIssue,
  toggleUnidentifiedIssuesModal,
  toggleUntimelyExemptionModal,
  toggleLegacyOptInModal
} from '../actions/addIssues';
import BenefitType from '../components/BenefitType';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import DateSelector from '../../components/DateSelector';
import ISSUE_CATEGORIES from '../../../constants/ISSUE_CATEGORIES.json';

const NO_MATCH_TEXT = 'None of these match';

const nonratingRequestIssueCategories = (benefitType = 'compensation') => {
  return ISSUE_CATEGORIES[benefitType].map((category) => {
    return {
      value: category,
      label: category
    };
  });
};

class NonratingRequestIssueModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      benefitType: props.intakeData.benefitType,
      category: '',
      description: '',
      decisionDate: '',
      selectedNonratingIssueId: '',
      ineligibleDueToId: null,
      ineligibleReason: null,
      reviewRequestTitle: null
    };
  }

  benefitTypeOnChange = (value) => {
    this.setState({
      benefitType: value
    });
  }

  categoryOnChange = (value) => {
    this.setState({
      category: value,
      description: '',
      decisionDate: '',
      selectedNonratingIssueId: '',
      ineligibleDueToId: null,
      ineligibleReason: null,
      reviewRequestTitle: null
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

  selectedNonratingIssueIdOnChange = (value) => {
    if (value === NO_MATCH_TEXT) {
      this.setState({
        selectedNonratingIssueId: value,
        description: '',
        decisionDate: '',
        ineligibleReason: null
      });
    } else {
      const activeNonratingRequestIssue = this.props.intakeData.activeNonratingRequestIssues.
        find((issue) => issue.id === String(value));

      this.setState({
        selectedNonratingIssueId: activeNonratingRequestIssue.id,
        description: activeNonratingRequestIssue.description,
        decisionDate: activeNonratingRequestIssue.decisionDate,
        ineligibleDueToId: activeNonratingRequestIssue.id,
        reviewRequestTitle: activeNonratingRequestIssue.reviewRequestTitle,
        ineligibleReason: 'duplicate_of_nonrating_issue_in_active_review'
      });
    }
  }

  hasLegacyAppeals = () => {
    return this.props.intakeData.legacyAppeals.length > 0;
  }

  getNextButtonText = () => {
    if (this.hasLegacyAppeals()) {
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

    console.log('decisionDate:', decisionDate);
    console.log('receiptDate:', receiptDate);
    console.log('isTimely:', isTimely);

    return !isTimely;
  }

  onAddIssue = () => {
    const currentIssue = {
      benefitType: this.state.benefitType,
      category: this.state.category.value,
      description: this.state.description,
      decisionDate: this.state.decisionDate,
      ineligibleDueToId: this.state.ineligibleDueToId,
      ineligibleReason: this.state.ineligibleReason,
      reviewRequestTitle: this.state.reviewRequestTitle,
      isRating: false
    };

    if (this.hasLegacyAppeals()) {
      this.props.toggleLegacyOptInModal({
        currentIssue,
        notes: null });
    } else if (this.requiresUntimelyExemption()) {
      console.log('this.requiresUntimelyExemption is true');
      currentIssue.timely = false;
      this.props.toggleUntimelyExemptionModal({
        currentIssue,
        notes: null
      });
    } else {
      console.log('addNonRatingRequestIssue raw');
      this.props.addNonratingRequestIssue({
        benefitType: this.state.benefitType,
        category: this.state.category.value,
        description: this.state.description,
        decisionDate: this.state.decisionDate,
        ineligibleDueToId: this.state.ineligibleDueToId,
        ineligibleReason: this.state.ineligibleReason,
        reviewRequestTitle: this.state.reviewRequestTitle,
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

    const { benefitType, category, description, decisionDate, selectedNonratingIssueId } = this.state;
    const issueNumber = (intakeData.addedIssues || []).length + 1;
    const requiredFieldsMissing = !benefitType || !description || !category || !decisionDate;

    let nonratingRequestIssueOptions = intakeData.activeNonratingRequestIssues.filter((issue) => {
      return category && issue.category === category.value;
    }).map((issue) => {
      return {
        displayText: `${issue.category}: ${issue.description}, decided ${issue.decisionDate}`,
        value: issue.id,
        disabled: false
      };
    });

    nonratingRequestIssueOptions.push({
      displayText: NO_MATCH_TEXT,
      value: NO_MATCH_TEXT,
      disabled: false
    });

    let nonratingRequestIssueSelection = null;

    if (nonratingRequestIssueOptions.length >= 2) {
      nonratingRequestIssueSelection = <RadioField
        vertical
        label={<h3>Does issue {issueNumber} match any of the issues actively being reviewed?</h3>}
        name="rating-radio"
        options={nonratingRequestIssueOptions}
        key={category}
        value={selectedNonratingIssueId}
        onChange={this.selectedNonratingIssueIdOnChange}
      />;
    }

    let additionalDetails = null;

    if (selectedNonratingIssueId === NO_MATCH_TEXT || !nonratingRequestIssueSelection) {
      additionalDetails = <React.Fragment>
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
      </React.Fragment>;
    }

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
            <BenefitType
              disabled={ intakeData.formType !== 'appeal' }
              value={benefitType}
              onChange={this.benefitTypeOnChange}
              // errorMessage={benefitTypeError}
            />
            <SearchableDropdown
              name="issue-category"
              label="Issue category"
              strongLabel
              placeholder="Select or enter..."
              options={nonratingRequestIssueCategories(benefitType)}
              value={category}
              onChange={this.categoryOnChange} />
          </div>
          <div className="add-nonrating-request-issue-description">
            { nonratingRequestIssueSelection }
            { additionalDetails }
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
