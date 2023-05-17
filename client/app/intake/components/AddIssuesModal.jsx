import React from 'react';
import PropTypes from 'prop-types';

import { map, findIndex, uniq } from 'lodash';

import { formatDateStr } from '../../util/DateUtil';
import Modal from '../../components/Modal';
import IntakeRadioField from './IntakeRadioField';
import TextField from '../../components/TextField';
import { issueByIndex } from '../util/issues';

class AddIssuesModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      approxDecisionDate: '',
      selectedContestableIssueIndex: '',
      notes: '',
      mstJustification: '',
      pactJustification: '',
      mstChecked: false,
      pactChecked: false,
      elementCount: 0,
      renderedFirstRadiofield: false
    };
  }

  addToElementCount = (increaseAmount) => {
    this.setState({ elementCount: this.elementCount + increaseAmount });
  }

  getElementCount = () => {
    if (this.state.renderedFirstRadiofield) {
      return this.state.elementCount;
    }
    this.setState({ renderedFirstRadiofield: true });

    return 0;
  }
  mstCheckboxChange = (checked) => this.setState({ mstChecked: checked });
  pactCheckboxChange = (checked) => this.setState({ pactChecked: checked });

  radioOnChange = (selectedContestableIssueIndex) => {
    this.setState({ selectedContestableIssueIndex });
  }

  notesOnChange = (notes) => this.setState({ notes });

  mstJustificationOnChange = (mstJustification) => this.setState({ mstJustification });
  pactJustificationOnChange = (pactJustification) => this.setState({ pactJustification });

  onAddIssue = () => {
    const {
      selectedContestableIssueIndex,
      notes,
      mstChecked,
      pactChecked,
      mstJustification,
      pactJustification
    } = this.state;
    const currentIssue = issueByIndex(this.props.intakeData.contestableIssues, selectedContestableIssueIndex);

    if (selectedContestableIssueIndex && !currentIssue.index) {
      currentIssue.index = selectedContestableIssueIndex;
    }

    // Ensure we have a value for decisionDate
    currentIssue.decisionDate = currentIssue.decisionDate || currentIssue.approxDecisionDate;

    if (mstChecked && mstJustification === '') {
      return;
    }
    if (pactChecked && pactJustification === '') {
      return;
    }

    this.props.onSubmit({
      currentIssue: {
        ...currentIssue,
        notes,
        mstChecked,
        pactChecked,
        mstJustification,
        pactJustification,
      }
    });
  };

  getContestableIssuesSections() {
    const { intakeData } = this.props;
    let iterations = -1;
    const addedIssues = intakeData.addedIssues ? intakeData.addedIssues : [];
    let preExistingMST;
    let preExistingPACT;
    let counter = 0;
    const issueKeys = Object.keys(intakeData.contestableIssues);

    let nestedIssues = [issueKeys.length];

    for (let i = 0; i < issueKeys.length; i++) {
      nestedIssues.push(intakeData.contestableIssues[issueKeys[i]]);
    }

    const sizes = nestedIssues.map((foundIssue) => {
      return Object.keys(foundIssue).length;
    });

    let accumulation = 0;
    let accumulationArr = [sizes.length];

    // Each contestable issue section on the child RadioField component consist of a seperate
    // array. This is a problem because this.state.selectedContestableIssueIndex does not
    // account for that, and the selected index is used as a prop to identify which Radio option is selected.
    // The fix is applying offsets so that the index is back to 0 for each new group.
    for (let i = 0; i < sizes.length; i++) {
      if (i === 0) {
        accumulationArr.push(0);
      }

      else {
        accumulation += sizes[i];
      }
      accumulationArr[i] = accumulation;
    }

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
          counterVal: counter,
          displayText: text,
          value: issue.index,
          disabled: foundIndex !== -1 || hasLaterIssueInChain,
          mst: contestableIssuesByIndex[issue.index].mstAvailable,
          pact: contestableIssuesByIndex[issue.index].pactAvailable
        };
      });

      counter += 1;
      iterations += 1;

      return (
        <IntakeRadioField
          vertical
          label={<h3>Past decisions from {formatDateStr(approxDecisionDate)}</h3>}
          totalElements={accumulationArr[iterations]}
          name="rating-radio"
          options={radioOptions}
          key={approxDecisionDate}
          value={this.state.selectedContestableIssueIndex}
          onChange={this.radioOnChange}
          renderMstAndPact={this.props.featureToggles.mstPactIdentification}
          mstJustification={this.state.mstJustification}
          mstJustificationOnChange={this.mstJustificationOnChange}
          pactJustification={this.state.pactJustification}
          pactJustificationOnChange={this.pactJustificationOnChange}
          renderMst={this.props.featureToggles.mst_identification ?
            this.props.featureToggles.mst_identification : this.props.featureToggles.mstIdentification}
          renderPact={this.props.featureToggles.pact_identification ?
            this.props.featureToggles.pact_identification : this.props.featureToggles.pactIdentification}
          userCanEditIntakeIssues={this.props.userCanEditIntakeIssues}
          mstChecked={this.state.mstChecked}
          setMstCheckboxFunction={this.mstCheckboxChange}
          pactChecked={this.state.pactChecked}
          setPactCheckboxFunction={this.pactCheckboxChange}
          preExistingMST={preExistingMST}
          preExistingPACT={preExistingPACT}
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

    if (this.props.onSkip && !this.props.intakeData.isDtaError) {
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
  intakeData: PropTypes.object,
  featureToggles: PropTypes.object,
  userCanEditIntakeIssues: PropTypes.bool
};

AddIssuesModal.defaultProps = {
  submitText: 'Next',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default AddIssuesModal;
