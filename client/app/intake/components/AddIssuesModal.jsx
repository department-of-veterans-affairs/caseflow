import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import { formatDateStr } from '../../util/DateUtil';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import {
  addRatingRequestIssue,
  toggleNonratingRequestIssueModal,
  toggleUntimelyExemptionModal
} from '../actions/addIssues';
import TextField from '../../components/TextField';
import { issueById } from '../util/issues';

class AddIssuesModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      profileDate: '',
      referenceId: '',
      notes: ''
    };
  }

  radioOnChange = (value) => {
    this.setState({
      referenceId: value
    });
  }

  notesOnChange = (value) => {
    this.setState({
      notes: value
    });
  }

  requiresUntimelyExemption = () => {
    if (this.props.formType === 'supplemental_claim') {
      return false;
    }
    const currentIssue = issueById(this.props.intakeData.ratings, this.state.referenceId);

    return !currentIssue.timely;
  }

  onAddIssue = () => {
    if (this.requiresUntimelyExemption()) {
      const currentIssue = issueById(this.props.intakeData.ratings, this.state.referenceId);

      this.props.toggleUntimelyExemptionModal({ currentIssue,
        notes: this.state.notes });
    } else {
      this.props.addRatingRequestIssue({
        issueId: this.state.referenceId,
        ratings: this.props.intakeData.ratings,
        isRating: true,
        notes: this.state.notes
      });
      this.props.closeHandler();
    }
  }

  getNextButtonText = () => {
    if (this.props.intakeData.legacyIssues.length > 0) {
      return 'Next';
    }
    return 'Add this issue';
  }

  render() {
    let {
      intakeData,
      closeHandler
    } = this.props;

    const addedIssues = intakeData.addedIssues ? intakeData.addedIssues : [];
    const ratingRequestIssuesSections = _.map(intakeData.ratings, (rating) => {
      const radioOptions = _.map(rating.issues, (issue) => {
        const foundIndex = addedIssues.map((addedIssue) => addedIssue.id).indexOf(issue.reference_id);
        const text = foundIndex === -1 ?
          issue.decision_text :
          `${issue.decision_text} (already selected for issue ${foundIndex + 1})`;

        return {
          displayText: text,
          value: issue.reference_id,
          disabled: foundIndex !== -1
        };
      });

      return <RadioField
        vertical
        label={<h3>Past decisions from { formatDateStr(rating.profile_date) }</h3>}
        name="rating-radio"
        options={radioOptions}
        key={rating.profile_date}
        value={this.state.referenceId}
        onChange={this.radioOnChange}
      />;
    });

    const issueNumber = (intakeData.addedIssues || []).length + 1;

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
            disabled: !this.state.referenceId
          },
          { classNames: ['usa-button', 'usa-button-secondary', 'no-matching-issues'],
            name: 'None of these match, see more options',
            onClick: this.props.toggleNonratingRequestIssueModal
          }
        ]}
        visible
        closeHandler={closeHandler}
        title={`Add issue ${issueNumber}`}
      >
        <div>
          <h2>
            Does issue {issueNumber} match any of these issues from past descriptions?
          </h2>
          <p>
            Tip: sometimes applicants list desired outcome, not what the past decision was
             -- so select the best matching decision.
          </p>
          <br />
          { ratingRequestIssuesSections }
          <TextField
            name="Notes"
            value={this.state.notes}
            optional
            strongLabel
            onChange={this.notesOnChange} />
        </div>
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    addRatingRequestIssue,
    toggleNonratingRequestIssueModal,
    toggleUntimelyExemptionModal
  }, dispatch)
)(AddIssuesModal);
