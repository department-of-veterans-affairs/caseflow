import React from 'react';
import PropTypes from 'prop-types';

import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { formatDateStr } from '../../util/DateUtil';
import {
  addContestableIssue,
  addNonratingRequestIssue,
  toggleUntimelyExemptionModal,
  toggleLegacyOptInModal
} from '../actions/addIssues';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import { generateSkipButton } from '../util/buttonUtils';

const NO_MATCH_TEXT = 'None of these match';
const noneMatchOpt = (issue) => ({
  displayText: `No VACOLS issues were found matching the issue: ${issue?.description}`,
  value: 'no_match'
});

class LegacyOptInModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      vacolsId: null,
      vacolsSequenceId: null,
      radioVal: '',
      eligibleForSocOptIn: null,
      eligibleForSocOptInWithExemption: null
    };
  }

  radioOnChange = (value) => {
    // legacy opt in are keyed off of a combo of both vacolsId & vacolsSequenceId
    // "No match" does not have a vacolsSequenceId
    if (value === 'no_match') {
      this.setState({
        vacolsId: null,
        vacolsSequenceId: null,
        eligibleForSocOptIn: null,
        eligibleForSocOptInWithExemption: null
      });
    } else {
      const legacyValues = value.split('-');
      const vacolsSequenceId = legacyValues.length > 1 ? legacyValues[1] : false;
      const legacyAppeal = this.props.intakeData.legacyAppeals.find((appeal) => appeal.vacols_id === legacyValues[0]);

      if (vacolsSequenceId) {
        const vacolsIssue = legacyAppeal.issues.find((i) => i.vacols_sequence_id === parseInt(vacolsSequenceId, 10));
        const eligibleWithExemption = legacyAppeal.eligible_for_soc_opt_in_with_exemption &&
          vacolsIssue.eligible_for_soc_opt_in_with_exemption;

        this.setState({
          vacolsId: legacyValues[0],
          vacolsSequenceId,
          eligibleForSocOptIn: legacyAppeal.eligible_for_soc_opt_in && vacolsIssue.eligible_for_soc_opt_in,
          eligibleForSocOptInWithExemption: eligibleWithExemption
        });
      }
    }

    this.setState({
      radioVal: value
    });
  };

  requiresUntimelyExemption = () => {
    if (this.props.formType === 'supplemental_claim') {
      return false;
    }
    if (this.props.intakeData.currentIssueAndNotes.currentIssue.vacolsId || this.state.vacolsId) {
      return false;
    }

    return !this.props.intakeData.currentIssueAndNotes.currentIssue.timely;
  };

  onAddIssue = () => {
    this.props.onSubmit({
      vacolsId: this.state.vacolsId,
      vacolsSequenceId: this.state.vacolsSequenceId,
      eligibleForSocOptIn: this.state.eligibleForSocOptIn,
      eligibleForSocOptInWithExemption: this.state.eligibleForSocOptInWithExemption
    });
  };

  // do no allow the same legacy issue to be selected more than once
  findOptinIssue = (legacyIssue, addedIssues) => {
    return (addedIssues || []).find((element) => {
      return (
        element.vacolsId === legacyIssue.vacols_id &&
        element.vacolsSequenceId === legacyIssue.vacols_sequence_id.toString()
      );
    });
  };

  getLegacyAppealsSections(intakeData) {
    return intakeData.legacyAppeals.map((legacyAppeal, index) => {
      const radioOptions = legacyAppeal.issues.map((issue) => ({
        displayText: issue.description,
        value: `${issue.vacols_id}-${issue.vacols_sequence_id}`,
        disabled: Boolean(this.findOptinIssue(issue, intakeData.addedIssues))
      }));

      return (
        <RadioField
          vertical
          label={<h3>Notice of Disagreement Date {formatDateStr(legacyAppeal.date)}</h3>}
          name="rating-radio"
          options={radioOptions}
          key={`${index}legacy-opt-in`}
          value={this.state.radioVal}
          onChange={this.radioOnChange}
        />
      );
    });
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
        disabled: !this.state.radioVal
      }
    ];

    generateSkipButton(btns, this.props);

    return btns;
  }

  render() {
    const { intakeData, currentIssue, onCancel } = this.props;

    const issueNumber = (intakeData.addedIssues || []).length + 1;

    return (
      <div className="intake-add-issues">
        <Modal buttons={this.getModalButtons()} visible closeHandler={onCancel} title={`Add issue ${issueNumber}`}>
          <div>
            <h2>Does issue {issueNumber} match any of these VACOLS issues?</h2>
            {this.getLegacyAppealsSections(intakeData)}
            <RadioField
              vertical
              label={<h3>{NO_MATCH_TEXT}</h3>}
              name="rating-radio"
              options={[noneMatchOpt(currentIssue)]}
              key="none-match"
              value={this.state.radioVal}
              onChange={this.radioOnChange}
            />
          </div>
        </Modal>
      </div>
    );
  }
}

LegacyOptInModal.propTypes = {
  onSubmit: PropTypes.func,
  submitText: PropTypes.string,
  onCancel: PropTypes.func,
  cancelText: PropTypes.string,
  onSkip: PropTypes.func,
  skipText: PropTypes.string,
  intakeData: PropTypes.object,
  currentIssue: PropTypes.object,
  formType: PropTypes.string
};

LegacyOptInModal.defaultProps = {
  submitText: 'Next',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default connect(
  null,
  (dispatch) =>
    bindActionCreators(
      {
        addContestableIssue,
        addNonratingRequestIssue,
        toggleUntimelyExemptionModal,
        toggleLegacyOptInModal
      },
      dispatch
    )
)(LegacyOptInModal);
