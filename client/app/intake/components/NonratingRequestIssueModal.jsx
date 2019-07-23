import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';

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
import { validateDate, validateDateNotInFuture } from '../util/issues';
import { isCorrection } from '../util';

const NO_MATCH_TEXT = 'None of these match';

const noteDiv = css({
  fontSize: '1.5rem',
  color: COLORS.GREY
});

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
      decisionReviewTitle: null,
      dateError: ''
    };
  }

  benefitTypeOnChange = (benType) => {
    this.setState({
      benefitType: benType.value,
      category: ''
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
      decisionReviewTitle: null
    });
  }

  descriptionOnChange = (value) => {
    this.setState({
      description: value
    });
  }

  decisionDateOnChange = (value) => {
    this.setState({
      decisionDate: value,
      dateError: this.errorOnDecisionDate(value)
    });
  }

  errorOnDecisionDate = (value) => {
    if (value.length === 10) {
      let error = validateDate(value) ? null : 'Please enter a valid decision date.';

      if (!error) {
        error = validateDateNotInFuture(value) ? null : 'Decision date cannot be in the future.';
      }

      return error;
    }
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
        decisionReviewTitle: activeNonratingRequestIssue.decisionReviewTitle,
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

  isTimely = () => {
    if (this.props.formType === 'supplemental_claim') {
      return true;
    }

    const ONE_YEAR_PLUS_MS = 1000 * 60 * 60 * 24 * 372;

    // we must do our own date math for nonrating request issues.
    // we assume the timezone of the browser for all these.
    let decisionDate = new Date(this.state.decisionDate);
    let receiptDate = new Date(this.props.intakeData.receiptDate);
    let lessThanOneYear = (receiptDate - decisionDate) <= ONE_YEAR_PLUS_MS;

    return lessThanOneYear;
  }

  onAddIssue = () => {
    const currentIssue = {
      benefitType: this.state.benefitType,
      category: this.state.category.value,
      description: this.state.description,
      decisionDate: this.state.decisionDate,
      ineligibleDueToId: this.state.ineligibleDueToId,
      ineligibleReason: this.state.ineligibleReason,
      decisionReviewTitle: this.state.decisionReviewTitle,
      isRating: false,
      timely: this.isTimely(),
      correctionType: isCorrection(false, this.props.intakeData) ? 'control' : null
    };

    if (this.hasLegacyAppeals()) {
      this.props.toggleLegacyOptInModal({
        currentIssue,
        notes: null });
    } else if (currentIssue.timely === false) {
      this.props.toggleUntimelyExemptionModal({
        currentIssue,
        notes: null
      });
    } else {
      this.props.addNonratingRequestIssue(currentIssue);
      this.props.closeHandler();
    }
  }

  render() {
    let {
      formType,
      intakeData,
      closeHandler
    } = this.props;

    const { benefitType, category, description, decisionDate, selectedNonratingIssueId } = this.state;
    const issueNumber = (intakeData.addedIssues || []).length + 1;
    let requiredFieldsMissing = !description || !category || !decisionDate;

    if (formType === 'appeal' && !benefitType) {
      requiredFieldsMissing = true;
    }

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
            errorMessage={this.state.dateError}
            onChange={this.decisionDateOnChange} />
        </div>

        <TextField
          name="Issue description"
          strongLabel
          value={description}
          onChange={this.descriptionOnChange} />
      </React.Fragment>;
    }

    let benefitTypeElement = '';

    if (formType === 'appeal') {
      benefitTypeElement = <BenefitType value={benefitType} onChange={this.benefitTypeOnChange} asDropdown />;
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
            disabled: requiredFieldsMissing || this.state.decisionDate.length < 10 || Boolean(this.state.dateError)
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
        <p {...noteDiv}> If the issue is a rating issue, please select
        "None of these match, see more options" and add it as an unidentified rating issue.</p>
        <div>
          <h2>
            Does issue {issueNumber} match any of these non-rating issue categories?
          </h2>
          <div className="add-nonrating-request-issue">
            {benefitTypeElement}
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
