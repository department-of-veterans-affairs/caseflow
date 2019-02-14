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
  toggleUntimelyExemptionModal,
  toggleLegacyOptInModal
} from '../actions/addIssues';
import TextField from '../../components/TextField';
import { issueByIndex } from '../util/issues';

class AddIssuesModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      approxDecisionDate: '',
      selectedContestableIssueIndex: '',
      notes: ''
    };
  }

  radioOnChange = (value) => {
    this.setState({
      selectedContestableIssueIndex: value
    });
  }

  notesOnChange = (value) => {
    this.setState({
      notes: value
    });
  }

  hasLegacyAppeals = () => {
    return this.props.intakeData.legacyAppeals.length > 0;
  }

  requiresUntimelyExemption = () => {
    if (this.props.formType === 'supplemental_claim') {
      return false;
    }
    const currentIssue = issueByIndex(this.props.intakeData.contestableIssues,
      this.state.selectedContestableIssueIndex);

    return !currentIssue.timely;
  }

  onAddIssue = () => {
    const currentIssue = issueByIndex(this.props.intakeData.contestableIssues,
      this.state.selectedContestableIssueIndex);

    if (this.hasLegacyAppeals()) {
      this.props.toggleLegacyOptInModal({ currentIssue,
        notes: this.state.notes });
    } else if (this.requiresUntimelyExemption()) {
      this.props.toggleUntimelyExemptionModal({ currentIssue,
        notes: this.state.notes });
    } else {
      this.props.addRatingRequestIssue({
        contestableIssueIndex: this.state.selectedContestableIssueIndex,
        contestableIssues: this.props.intakeData.contestableIssues,
        isRating: true,
        notes: this.state.notes
      });
      this.props.closeHandler();
    }
  }

  getNextButtonText = () => {
    if (this.hasLegacyAppeals()) {
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

    const contestableIssuesSections = _.map(intakeData.contestableIssues,
      (contestableIssuesByIndex, approxDecisionDate) => {
        const radioOptions = _.map(contestableIssuesByIndex, (issue) => {
          const foundIndex = _.findIndex(addedIssues, { index: issue.index });
          const text = foundIndex === -1 ?
            issue.description :
            `${issue.description} (already selected for issue ${foundIndex + 1})`;

          return {
            displayText: text,
            value: issue.index,
            disabled: foundIndex !== -1
          };
        }
        );

        return <RadioField
          vertical
          label={<h3>Past decisions from { formatDateStr(approxDecisionDate) }</h3>}
          name="rating-radio"
          options={radioOptions}
          key={approxDecisionDate}
          value={this.state.selectedContestableIssueIndex}
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
            disabled: !this.state.selectedContestableIssueIndex
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
          { contestableIssuesSections }
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
    toggleUntimelyExemptionModal,
    toggleLegacyOptInModal
  }, dispatch)
)(AddIssuesModal);
