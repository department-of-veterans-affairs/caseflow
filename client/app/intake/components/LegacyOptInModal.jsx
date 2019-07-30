import React from 'react';
import PropTypes from 'prop-types';

import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { formatDateStr } from '../../util/DateUtil';
import { isCorrection } from '../util';
import {
  addContestableIssue,
  addNonratingRequestIssue,
  toggleUntimelyExemptionModal,
  toggleLegacyOptInModal
} from '../actions/addIssues';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';

const NO_MATCH_TEXT = 'None of these match';

class LegacyOptInModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      vacolsId: null,
      vacolsSequenceId: null,
      radioKey: '',
      eligibleForSocOptIn: null
    };
  }

  radioOnChange = (value) => {
    // legacy opt in are keyed off of a combo of both vacolsId & vacolsSequenceId
    // NO_MATCH_TEXT does not have a vacolsSequenceId
    if (value === NO_MATCH_TEXT) {
      this.setState({
        vacolsId: null,
        eligibleForSocOptIn: null,
        vacolsSequenceId: null
      });
    } else {
      const legacyValues = value.split('-');
      const vacolsSequenceId = legacyValues.length > 1 ? legacyValues[1] : false;
      const legacyAppeal = this.props.intakeData.legacyAppeals.find((appeal) => appeal.vacols_id === legacyValues[0]);

      if (vacolsSequenceId) {
        let vacolsIssue = legacyAppeal.issues.find((i) => i.vacols_sequence_id === parseInt(vacolsSequenceId, 10));

        this.setState({
          vacolsId: legacyValues[0],
          eligibleForSocOptIn: legacyAppeal.eligible_for_soc_opt_in && vacolsIssue.eligible_for_soc_opt_in,
          vacolsSequenceId
        });
      }
    }

    this.setState({
      radioKey: value
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
      eligibleForSocOptIn: this.state.eligibleForSocOptIn
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
      const radioOptions = legacyAppeal.issues.map((issue) => {
        return {
          displayText: issue.description,
          value: `${issue.vacols_id}-${issue.vacols_sequence_id}`,
          disabled: Boolean(this.findOptinIssue(issue, intakeData.addedIssues))
        };
      });

      // on the last issue add a radio button for "None of these match"
      if (index === intakeData.legacyAppeals.length - 1) {
        radioOptions.push({
          displayText: NO_MATCH_TEXT,
          value: NO_MATCH_TEXT
        });
      }

      return (
        <RadioField
          vertical
          label={<h3>Notice of Disagreement Date {formatDateStr(legacyAppeal.date)}</h3>}
          name="rating-radio"
          options={radioOptions}
          key={`${index}legacy-opt-in`}
          value={this.state.radioKey}
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
        disabled: !this.state.radioKey
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

  render() {
    const { intakeData, onCancel } = this.props;

    const issueNumber = (intakeData.addedIssues || []).length + 1;

    return (
      <div className="intake-add-issues">
        <Modal buttons={this.getModalButtons()} visible closeHandler={onCancel} title={`Add issue ${issueNumber}`}>
          <div>
            <h2>Does issue {issueNumber} match any of these VACOLS issues?</h2>
            {this.getLegacyAppealsSections(intakeData)}
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
  skipText: PropTypes.string
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
