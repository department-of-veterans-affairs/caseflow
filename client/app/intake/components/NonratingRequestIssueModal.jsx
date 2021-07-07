import React from 'react';
import PropTypes from 'prop-types';

import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';

import BenefitType from '../components/BenefitType';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import DateSelector from '../../components/DateSelector';
import ISSUE_CATEGORIES from '../../../constants/ISSUE_CATEGORIES';
import { validateDateNotInFuture, isTimely } from '../util/issues';
import { formatDateStr } from '../../util/DateUtil';

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
  };

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
  };

  descriptionOnChange = (value) => {
    this.setState({
      description: value
    });
  };

  decisionDateOnChange = (value) => {
    this.setState({
      decisionDate: value,
      dateError: this.errorOnDecisionDate(value)
    });
  };

  errorOnDecisionDate = (value) => {
    if (value.length === 10) {
      const error = validateDateNotInFuture(value) ? null : 'Decision date cannot be in the future.';

      return error;
    }
  };

  selectedNonratingIssueIdOnChange = (value) => {
    if (value === NO_MATCH_TEXT) {
      this.setState({
        selectedNonratingIssueId: value,
        description: '',
        decisionDate: '',
        ineligibleReason: null
      });
    } else {
      const activeNonratingRequestIssue = this.props.intakeData.activeNonratingRequestIssues.find(
        (issue) => issue.id === String(value)
      );

      this.setState({
        selectedNonratingIssueId: activeNonratingRequestIssue.id,
        description: activeNonratingRequestIssue.description,
        decisionDate: activeNonratingRequestIssue.decisionDate,
        ineligibleDueToId: activeNonratingRequestIssue.id,
        decisionReviewTitle: activeNonratingRequestIssue.decisionReviewTitle,
        ineligibleReason: 'duplicate_of_nonrating_issue_in_active_review'
      });
    }
  };

  onAddIssue = () => {
    const { formType, intakeData } = this.props;
    const {
      benefitType,
      category: { value: category },
      description,
      decisionDate,
      ineligibleDueToId,
      ineligibleReason,
      decisionReviewTitle
    } = this.state;

    const currentIssue = {
      benefitType,
      category,
      description,
      decisionDate,
      ineligibleDueToId,
      ineligibleReason,
      decisionReviewTitle,
      isRating: false,
      timely: isTimely(formType, decisionDate, intakeData.receiptDate)
    };

    this.props.onSubmit({ currentIssue });
  };

  requiredFieldsMissing() {
    const { formType } = this.props;
    const { description, category, decisionDate, benefitType } = this.state;

    return !description || !category || !decisionDate || (formType === 'appeal' && !benefitType);
  }

  getModalButtons() {
    const btns = [
      {
        classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
        name: this.props.cancelText,
        onClick: this.props.onCancel
      },
      {
        classNames: ['usa-button', 'add-issue'],
        name: this.props.submitText,
        onClick: this.onAddIssue,
        disabled: this.requiredFieldsMissing() || this.state.decisionDate.length < 10 || Boolean(this.state.dateError)
      }
    ];

    if (this.props.onSkip) {
      btns.push({
        classNames: ['usa-button', 'usa-button-secondary', 'no-matching-issues'],
        name: this.props.skipText,
        onClick: this.props.onSkip
      });
    }

    return btns;
  }

  getNonratingRequestIssueOptions() {
    const { intakeData } = this.props;
    const { category } = this.state;

    const options = intakeData.activeNonratingRequestIssues.
      filter((issue) => {
        return category && issue.category === category.value;
      }).
      map((issue) => {
        return {
          displayText: `${issue.category}: ${issue.description}, decided ${formatDateStr(issue.decisionDate)}`,
          value: issue.id,
          disabled: false
        };
      });

    const noMatch = [
      {
        displayText: NO_MATCH_TEXT,
        value: NO_MATCH_TEXT,
        disabled: false
      }
    ];

    return [...options, ...noMatch];
  }

  getNonratingRequestIssueSelection() {
    const { intakeData } = this.props;
    const { category, selectedNonratingIssueId } = this.state;
    const issueNumber = (intakeData.addedIssues || []).length + 1;
    const issueOpts = this.getNonratingRequestIssueOptions();

    return issueOpts.length < 2 ? null : (
      <RadioField
        vertical
        label={<h3>Does issue {issueNumber} match any of the issues actively being reviewed?</h3>}
        name="rating-radio"
        options={issueOpts}
        key={category}
        value={selectedNonratingIssueId}
        onChange={this.selectedNonratingIssueIdOnChange}
      />
    );
  }

  getAdditionalDetails() {
    const { decisionDate, description } = this.state;

    return (
      <React.Fragment>
        <div className="decision-date">
          <DateSelector
            name="decision-date"
            label="Decision date"
            strongLabel
            value={decisionDate}
            errorMessage={this.state.dateError}
            onChange={this.decisionDateOnChange}
          />
        </div>

        <TextField name="Issue description" strongLabel value={description} onChange={this.descriptionOnChange} />
      </React.Fragment>
    );
  }

  render() {
    const { formType, intakeData, onCancel } = this.props;
    const { benefitType, category, selectedNonratingIssueId } = this.state;

    const issueNumber = (intakeData.addedIssues || []).length + 1;

    const nonratingRequestIssueSelection = this.getNonratingRequestIssueSelection();

    const additionalDetails =
      selectedNonratingIssueId === NO_MATCH_TEXT || !nonratingRequestIssueSelection ?
        this.getAdditionalDetails() :
        null;

    const compensationCategories = nonratingRequestIssueCategories(
      benefitType === 'compensation' && formType === 'appeal' ? 'compensation_all' : benefitType);

    const benefitTypeElement =
      formType === 'appeal' ? <BenefitType value={benefitType} onChange={this.benefitTypeOnChange} asDropdown /> : null;

    return (
      <div className="intake-add-issues">
        <Modal buttons={this.getModalButtons()} visible closeHandler={onCancel} title={`Add issue ${issueNumber}`}>
          <p {...noteDiv}>
            {' '}
            If the issue is a rating issue, please select "None of these match, see more options" and add it as an
            unidentified rating issue.
          </p>
          <div>
            <h2>Does issue {issueNumber} match any of these non-rating issue categories?</h2>
            <div className="add-nonrating-request-issue">
              {benefitTypeElement}
              <SearchableDropdown
                name="issue-category"
                label="Issue category"
                strongLabel
                placeholder="Select or enter..."
                options={compensationCategories}
                value={category}
                onChange={this.categoryOnChange}
              />
            </div>
            <div className="add-nonrating-request-issue-description">
              {nonratingRequestIssueSelection}
              {additionalDetails}
            </div>
          </div>
        </Modal>
      </div>
    );
  }
}

NonratingRequestIssueModal.propTypes = {
  onSubmit: PropTypes.func,
  submitText: PropTypes.string,
  onCancel: PropTypes.func,
  cancelText: PropTypes.string,
  onSkip: PropTypes.func,
  skipText: PropTypes.string,
  intakeData: PropTypes.object,
  formType: PropTypes.string,
  activeNonratingRequestIssues: PropTypes.object,
  receiptDate: PropTypes.string,
  addedIssues: PropTypes.array
};

NonratingRequestIssueModal.defaultProps = {
  submitText: 'Add this issue',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default NonratingRequestIssueModal;
