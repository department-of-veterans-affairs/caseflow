import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { upperFirst } from 'lodash';

import COPY from '../../../../COPY';
import Modal from '../../../components/Modal';
import SelectIssueDispositionDropdown from '../../components/SelectIssueDispositionDropdown';
import TextareaField from '../../../components/TextareaField';
import BENEFIT_TYPES from '../../../../constants/BENEFIT_TYPES';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS';
import SearchableDropdown from '../../../components/SearchableDropdown';

import cx from 'classnames';
import styles from './AddEditDecisionIssueModal.module.scss';

const isValid = ({ disposition, description }) => disposition && description;

export const AddEditDecisionIssueModal = ({
  connectedRequestIssues,
  appeal,
  decisionIssue: initialDecisionIssue,
  operation = 'add',
  onCancel,
  onSubmit
}) => {
  const [decisionIssue, setDecisionIssue] = useState(initialDecisionIssue);
  const [highlight, setHighlight] = useState(false);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: `${operation === 'edit' ? 'Update' : 'Add'} Issue`,
      onClick: () => {
        setHighlight(false);
        if (isValid(decisionIssue)) {
          return onSubmit?.(decisionIssue);
        }

        setHighlight(true);
      }
    }
  ];

  const title = `${upperFirst(operation)} decision`;

  return (
    <Modal className={styles.modal} buttons={buttons} closeHandler={onCancel} title={title}>
      <div>
        {COPY.CONTESTED_ISSUE}
        <ul>
          {connectedRequestIssues.map((issue) => (
            <li key={issue.id}>{issue.description}</li>
          ))}
        </ul>
      </div>

      {operation === 'add' && (
        <React.Fragment>
          <h3>{COPY.DECISION_ISSUE_MODAL_TITLE}</h3>
          <p className={styles.h3Sibling}>{COPY.DECISION_ISSUE_MODAL_SUB_TITLE}</p>
        </React.Fragment>
      )}

      <h3>{COPY.DECISION_ISSUE_MODAL_DISPOSITION}</h3>
      <SelectIssueDispositionDropdown
        highlight={highlight}
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
        errorMessage={highlight && !decisionIssue.description ? 'Text Box field is required' : null}
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
        options={Object.keys(DIAGNOSTIC_CODE_DESCRIPTIONS).map((key) => ({
          label: key,
          value: key
        }))}
        onChange={(diagnosticCode) =>
          setDecisionIssue({
            ...decisionIssue,
            diagnostic_code: diagnosticCode?.value || ''
          })
        }
      />
      <h3>{COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}</h3>
      <SearchableDropdown
        name="Benefit type"
        placeholder={COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}
        hideLabel
        value={decisionIssue.benefit_type}
        options={Object.entries(BENEFIT_TYPES).map(([key, value]) => ({
          label: value,
          value: key
        }))}
        onChange={(benefitType) =>
          setDecisionIssue({
            ...decisionIssue,
            benefit_type: benefitType?.value
          })
        }
      />
      <h3>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_DESCRIPTION}</h3>
      <p className={cx(styles.example, styles.h3Sibling)}>{COPY.DECISION_ISSUE_MODAL_CONNECTED_ISSUES_EXAMPLE}</p>
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
          setDecisionIssue({
            ...decisionIssue,
            request_issue_ids: [...decisionIssue.request_issue_ids, issue.value]
          })
        }
      />
    </Modal>
  );
};
AddEditDecisionIssueModal.propTypes = {
  appeal: PropTypes.object,
  decisionIssue: PropTypes.object,
  operation: PropTypes.oneOf(['add', 'edit']),
  connectedRequestIssues: PropTypes.array,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
