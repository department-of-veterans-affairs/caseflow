import React, { useState } from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../COPY';
import Modal from '../../components/Modal';
import SelectIssueDispositionDropdown from '../components/SelectIssueDispositionDropdown';
import TextareaField from '../../components/TextareaField';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS';
import SearchableDropdown from '../../components/SearchableDropdown';

export const AddDecisionIssueModal = ({
  connectedRequestIssues,
  appeal,
  decisionIssue: initialDecisionIssue,
  onCancel,
  onSubmit
}) => {
  const [decisionIssue, setDecisionIssue] = useState(initialDecisionIssue);

  const buttons = [
    { classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel },
    { classNames: ['usa-button', 'usa-button-primary'],
      name: 'Add Issue',
      onClick: onSubmit }
  ];

  return (
    <Modal buttons={buttons} closeHandler={onCancel} title="Add decision">
      <span className="add-decision-modal">{COPY.DECISION_ISSUE_MODAL_TITLE}</span>

      <div>
        {COPY.CONTESTED_ISSUE}
        <ul>
          {connectedRequestIssues.map((issue) => (
            <li key={issue.id}>{issue.description}</li>
          ))}
        </ul>
      </div>

      {/* {!editingExistingIssue && (
        <React.Fragment>
          <h3>{COPY.DECISION_ISSUE_MODAL_TITLE}</h3>
          <p {...paragraphH3SiblingStyle}>{COPY.DECISION_ISSUE_MODAL_SUB_TITLE}</p>
        </React.Fragment>
      )} */}

      <h3>{COPY.DECISION_ISSUE_MODAL_DISPOSITION}</h3>
      <SelectIssueDispositionDropdown
        // highlight={highlightModal}
        issue={decisionIssue}
        appeal={appeal}
        updateIssue={({ disposition }) => {
          setDecisionIssue({ ...decisionIssue,
            disposition });
        }}
        noStyling
      />
      <br />
      <h3>{COPY.DECISION_ISSUE_MODAL_DESCRIPTION}</h3>
      <TextareaField
        // labelStyling={textAreaStyle}
        // styling={textAreaStyle}
        // errorMessage={highlightModal && !decisionIssue.description ? 'This field is required' : null}
        label={COPY.DECISION_ISSUE_MODAL_DESCRIPTION_EXAMPLE}
        name="Text Box"
        onChange={(description) => {
          setDecisionIssue({ ...decisionIssue,
            description });
        }}
        value={decisionIssue.description}
      />
      <h3>{COPY.DECISION_ISSUE_MODAL_DIAGNOSTIC_CODE}</h3>
      <SearchableDropdown
        name="Diagnostic code"
        placeholder={COPY.DECISION_ISSUE_MODAL_DIAGNOSTIC_CODE}
        hideLabel
        value={decisionIssue.diagnostic_code}
        options={Object.keys(DIAGNOSTIC_CODE_DESCRIPTIONS).map((key) => ({ label: key,
          value: key }))}
        onChange={(diagnosticCode) =>
          setDecisionIssue({ ...decisionIssue,
            diagnostic_code: diagnosticCode?.value || '' })
        }
      />
      {/* <h3>{COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}</h3>
      <SearchableDropdown
        name="Benefit type"
        placeholder={COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}
        hideLabel
        value={decisionIssue.benefit_type}
        options={_.map(BENEFIT_TYPES, (value, key) => ({ label: value,
          value: key }))}
        onChange={(benefitType) =>
          this.setState({
            decisionIssue: {
              ...decisionIssue,
              benefit_type: benefitType.value
            }
          })
        }
      />
      <h3>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_DESCRIPTION}</h3>
      <p {...exampleDiv} {...paragraphH3SiblingStyle}>
        {COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_EXAMPLE}
      </p>
      <h3>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_TITLE}</h3>
      <SearchableDropdown
        name="Issues"
        placeholder="Select issues"
        hideLabel
        value={null}
        options={appeal.issues.
          filter((issue) => !decisionIssue.request_issue_ids.includes(issue.id)).
          map((issue) => ({
            label: issue.description,
            value: issue.id
          }))}
        onChange={(issue) =>
          this.setState({
            decisionIssue: {
              ...decisionIssue,
              request_issue_ids: [...decisionIssue.request_issue_ids, issue.value]
            }
          })
        }
      />
      {this.connectedRequestIssuesWithoutCurrentId(connectedRequestIssues, openRequestIssueId).map((issue) => (
        <div key={issue.id} {...connectedIssueDiv}>
          <span>{issue.description}</span>
          <Button
            classNames={['cf-btn-link']}
            onClick={() =>
              this.setState({
                decisionIssue: {
                  ...decisionIssue,
                  request_issue_ids: decisionIssue.request_issue_ids.filter((id) => id !== issue.id)
                }
              })
            }
          >
            Remove
          </Button>
        </div>
      ))} */}
    </Modal>
  );
};
AddDecisionIssueModal.propTypes = {
  appeal: PropTypes.object,
  decisionIssue: PropTypes.object,
  connectedRequestIssues: PropTypes.array,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
