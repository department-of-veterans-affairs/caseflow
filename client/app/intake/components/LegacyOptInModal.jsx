import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import { formatDateStr } from '../../util/DateUtil';
import {
  addRatingRequestIssue,
  toggleUntimelyExemptionModal,
  toggleLegacyOptInModal } from '../actions/addIssues';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';

const NO_MATCH_TEXT = 'None of these match';

class LegacyOptInModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      vacolsId: ''
    };
  }

  radioOnChange = (value) => {
    this.setState({
      vacolsId: value
    });
  }

  requiresUntimelyExemption = () => {
    if (this.state.vacolsId !== NO_MATCH_TEXT) {
      return false;
    }

    return !this.props.intakeData.currentIssueAndNotes.currentIssue.timely;
  }

  onAddIssue = () => {
    // currently just adds the issue & checks for untimeliness
    // if vacols issue is selected, logic to be implemented by 7336 & 7337
    const currentIssue = this.props.intakeData.currentIssueAndNotes.currentIssue;
    const notes = this.props.intakeData.currentIssueAndNotes.notes;

    if (this.requiresUntimelyExemption()) {
      return this.props.toggleUntimelyExemptionModal({ currentIssue,
        notes: this.state.notes });
    }

    this.props.addRatingRequestIssue({
      issueId: currentIssue.reference_id,
      ratings: this.props.intakeData.ratings,
      isRating: true,
      notes
    });

    this.props.toggleLegacyOptInModal();
  }

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
          value: String(issue.vacols_sequence_id)
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
        value={this.state.vacolsId}
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
            disabled: !this.state.vacolsId
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
    toggleUntimelyExemptionModal,
    toggleLegacyOptInModal
  }, dispatch)
)(LegacyOptInModal);
