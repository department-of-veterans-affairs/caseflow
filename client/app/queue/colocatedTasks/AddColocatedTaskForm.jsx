import React, { useState, useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import colocatedAdminActions from '../../../constants/CO_LOCATED_ADMIN_ACTIONS';

import styles from './AddColocatedTaskForm.module.scss';

const actionOptions = Object.entries(colocatedAdminActions).map(([value, label]) => ({ label, value }));

export const AddColocatedTaskForm = ({
  actionTypes = actionOptions,
  value = { type: null, instructions: '' },
  highlightFormItems = false,
  onChange
}) => {
  const [type, setType] = useState(value.type);
  const [instructions, setInstructions] = useState(value.instructions);

  // SearchableDropdown requires obj for `value` prop
  const selectedType = useMemo(() => (type ? actionTypes.find((opt) => opt.value === type) : null), [type]);

  useEffect(() => onChange({ type, instructions }), [type, instructions]);

  return (
    <div className="colocated-task-form">
      <div className={styles.field}>
        <SearchableDropdown
          errorMessage={highlightFormItems && !type ? 'administrative action type field is required' : null}
          name="type"
          label={COPY.ADD_COLOCATED_TASK_ACTION_TYPE_LABEL}
          placeholder="Select an action type"
          options={actionTypes}
          onChange={(opt) => setType(opt?.value)}
          value={selectedType}
        />
      </div>
      <div className={styles.field}>
        <TextareaField
          errorMessage={highlightFormItems && !instructions ? COPY.INSTRUCTIONS_ERROR_FIELD_REQUIRED : null}
          name="instructions"
          label={COPY.PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}
          onChange={(val) => setInstructions(val)}
          value={instructions}
        />
      </div>
    </div>
  );
};

AddColocatedTaskForm.propTypes = {
  actionTypes: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string,
      value: PropTypes.string
    })
  ),
  highlightFormItems: PropTypes.bool,
  onChange: PropTypes.func,
  value: PropTypes.shape({
    type: PropTypes.string,
    instructions: PropTypes.string
  })
};
