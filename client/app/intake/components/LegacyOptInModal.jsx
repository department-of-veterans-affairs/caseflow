import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import { formatDateStr } from '../../util/DateUtil';
import {
  addRatingRequestIssue,
  addNonratingRequestIssue,
  toggleUntimelyExemptionModal,
  toggleLegacyOptInModal } from '../actions/addIssues';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';

import _ from 'lodash';

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
    const legacyValues = value.split('-');
    const vacolsSequenceId = legacyValues.length > 1 ? legacyValues[1] : false;
    const legacyAppeal = this.props.intakeData.legacyAppeals.find((appeal) => appeal.vacols_id === legacyValues[0]);

    if (vacolsSequenceId) {
      let vacolsIssue = _.find(legacyAppeal.issues, { vacols_sequence_id: parseInt(vacolsSequenceId, 10) });

      this.setState({
        vacolsId: legacyValues[0],
        eligibleForSocOptIn: (legacyAppeal.eligible_for_soc_opt_in && vacolsIssue.eligible_for_soc_opt_in),
        vacolsSequenceId
      });
    }

    this.setState({
      radioKey: value
    });
  }

  requiresUntimelyExemption = () => {
    if (this.props.formType === 'supplemental_claim') {
      return false;
    }
    if (this.props.intakeData.currentIssueAndNotes.currentIssue.vacolsId || this.state.vacolsId) {
      return false;
    }

    return !this.props.intakeData.currentIssueAndNotes.currentIssue.timely;
  }

  onAddIssue = () => {
    const currentIssue = this.props.intakeData.currentIssueAndNotes.currentIssue;
    const notes = this.props.intakeData.currentIssueAndNotes.notes;

    if (this.requiresUntimelyExemption()) {
      return this.props.toggleUntimelyExemptionModal({ currentIssue,
        notes,
        vacolsId: this.state.vacolsId,
        vacolsSequenceId: this.state.vacolsSequenceId,
        eligibleForSocOptIn: this.state.eligibleForSocOptIn });
    } else if (currentIssue.ratingIssueReferenceId) {
      this.props.addRatingRequestIssue({
        contestableIssueIndex: currentIssue.index,
        contestableIssues: this.props.intakeData.contestableIssues,
        isRating: true,
        vacolsId: this.state.vacolsId,
        vacolsSequenceId: this.state.vacolsSequenceId,
        eligibleForSocOptIn: this.state.eligibleForSocOptIn,
        notes
      });
    } else {
      this.props.addNonratingRequestIssue({
        ...currentIssue,
        vacolsId: this.state.vacolsId,
        vacolsSequenceId: this.state.vacolsSequenceId,
        eligibleForSocOptIn: this.state.eligibleForSocOptIn
      });
    }
    this.props.toggleLegacyOptInModal();
  };

  render() {
    let {
      intakeData,
      closeHandler
    } = this.props;

    const issueNumber = (intakeData.addedIssues || []).length + 1;
    const legacyAppealsSections = intakeData.legacyAppeals.map((legacyAppeal, index) => {
      const radioOptions = legacyAppeal.issues.map((issue) => {
        return {
          displayText: issue.description,
          value: `${issue.vacols_id}-${issue.vacols_sequence_id}`
        };
      });

      // on the last issue add a radio button for "None of these match"
      if (index === intakeData.legacyAppeals.length - 1) {
        radioOptions.push({
          displayText: NO_MATCH_TEXT,
          value: NO_MATCH_TEXT
        });
      }

      return <RadioField
        vertical
        label={<h3>Notice of Disagreement Date { formatDateStr(legacyAppeal.date) }</h3>}
        name="rating-radio"
        options={radioOptions}
        key={`${index}legacy-opt-in`}
        value={this.state.radioKey}
        onChange={this.radioOnChange}
      />;
    });

    return <div className="intake-add-issues">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel adding this issue',
            onClick: closeHandler
          },
          { classNames: ['usa-button', 'add-issue'],
            name: 'Add this issue',
            onClick: this.onAddIssue,
            disabled: !this.state.radioKey
          }
        ]}
        visible
        closeHandler={closeHandler}
        title={`Add issue ${issueNumber}`}
      >
        <div>
          <h2>
            Does issue {issueNumber} match any of these VACOLS issues?
          </h2>
          { legacyAppealsSections }
        </div>
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    addRatingRequestIssue,
    addNonratingRequestIssue,
    toggleUntimelyExemptionModal,
    toggleLegacyOptInModal
  }, dispatch)
)(LegacyOptInModal);
