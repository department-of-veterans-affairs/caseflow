import React from 'react';
import PropTypes from 'prop-types';

import { map, findIndex, uniq } from 'lodash';

import { formatDateStr } from '../../util/DateUtil';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import { issueByIndex } from '../util/issues';
import { generateSkipButton } from '../util/buttonUtils';

class AddIssuesModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      approxDecisionDate: '',
      selectedContestableIssueIndex: '',
      notes: ''
    };
  }

  radioOnChange = (selectedContestableIssueIndex) => this.setState({ selectedContestableIssueIndex });

  notesOnChange = (notes) => this.setState({ notes });

  onAddIssue = () => {
    const { selectedContestableIssueIndex, notes } = this.state;
    const currentIssue = issueByIndex(this.props.intakeData.contestableIssues, selectedContestableIssueIndex);

    if (selectedContestableIssueIndex && !currentIssue.index) {
      currentIssue.index = selectedContestableIssueIndex;
    }

    // Ensure we have a value for decisionDate
    currentIssue.decisionDate = currentIssue.decisionDate || currentIssue.approxDecisionDate;

    this.props.onSubmit({
      currentIssue: {
        ...currentIssue,
        notes
      }
    });
  };

  getContestableIssuesSections() {
    const { intakeData } = this.props;

    const addedIssues = intakeData.addedIssues ? intakeData.addedIssues : [];

    return map(intakeData.contestableIssues, (contestableIssuesByIndex, approxDecisionDate) => {
      const radioOptions = map(contestableIssuesByIndex, (issue) => {
        const foundIndex = findIndex(addedIssues, { index: issue.index });
        let text =
          foundIndex === -1 ? issue.description : `${issue.description} (already selected for issue ${foundIndex + 1})`;

        let hasLaterIssueInChain = false;

        // if current decisionIssueId is not in any of the latest issues, it is a prior decision
        let foundLatestIssueIds = issue.latestIssuesInChain.filter((latestIssue) => {
          return latestIssue.id === issue.decisionIssueId;
        });

        if (foundLatestIssueIds.length === 0) {
          hasLaterIssueInChain = true;
          let dates = uniq(
            issue.latestIssuesInChain.map((latestIssue) => {
              return formatDateStr(latestIssue.approxDecisionDate);
            })
          ).join(', ');

          text = `${text} (Please select the most recent decision on ${dates})`;
        }

        return {
          displayText: text,
          value: issue.index,
          disabled: foundIndex !== -1 || hasLaterIssueInChain
        };
      });

      return (
        <RadioField
          vertical
          label={<h3>Past decisions from {formatDateStr(approxDecisionDate)}</h3>}
          name="rating-radio"
          options={radioOptions}
          key={approxDecisionDate}
          value={this.state.selectedContestableIssueIndex}
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
        disabled: !this.state.selectedContestableIssueIndex
      }
    ];

    if (!this.props.intakeData.isDtaError) {
      generateSkipButton(btns, this.props);
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
            <h2>Does issue {issueNumber} match any of these issues from past descriptions?</h2>
            <p>
              Tip: sometimes applicants list desired outcome, not what the past decision was -- so select the best
              matching decision.
            </p>
            <br />
            {this.getContestableIssuesSections()}
            <TextField name="Notes" value={this.state.notes} optional strongLabel onChange={this.notesOnChange} />
          </div>
        </Modal>
      </div>
    );
  }
}

AddIssuesModal.propTypes = {
  onSubmit: PropTypes.func,
  submitText: PropTypes.string,
  onCancel: PropTypes.func,
  cancelText: PropTypes.string,
  onSkip: PropTypes.func,
  skipText: PropTypes.string,
  intakeData: PropTypes.object
};

AddIssuesModal.defaultProps = {
  submitText: 'Next',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default AddIssuesModal;
