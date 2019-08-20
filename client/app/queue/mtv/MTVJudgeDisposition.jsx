import React, { useState } from 'react';
import PropTypes from 'prop-types';

import {
  JUDGE_ADDRESS_MTV_DESCRIPTION,
  JUDGE_ADDRESS_MTV_DISPOSITION_SELECT_LABEL,
  JUDGE_ADDRESS_MTV_VACATE_TYPE_LABEL,
  JUDGE_ADDRESS_MTV_DISPOSITION_NOTES_LABEL,
  JUDGE_ADDRESS_MTV_ASSIGN_ATTORNEY_LABEL
} from '../../../COPY.json';
import { MTVDispositionSelection } from './MTVDispositionSelection';
import TextareaField from '../../components/TextareaField';
import RadioField from '../../components/RadioField';
import { mtvVacateTypeOptions } from './index';
import SearchableDropdown from '../../components/SearchableDropdown';

export const MTVJudgeDisposition = ({ attorneys, task }) => {
  const { assignedTo } = task;

  const [disposition, setDisposition] = useState(null);
  const [vacateType, setVacateType] = useState(null);
  const [instructions, setInstructions] = useState('');
  const [attorneyId, setAttorneyId] = useState(assignedTo ? assignedTo.id : null);

  return (
    <div className="address-motion-to-vacate">
      <p>{JUDGE_ADDRESS_MTV_DESCRIPTION}</p>

      <p className="mtv-task-instructions">{task.instructions}</p>

      <MTVDispositionSelection
        label={JUDGE_ADDRESS_MTV_DISPOSITION_SELECT_LABEL}
        onChange={(val) => setDisposition(val)}
        value={disposition}
      />

      {disposition && disposition === 'granted' && (
        <RadioField
          name="disposition"
          label={JUDGE_ADDRESS_MTV_VACATE_TYPE_LABEL}
          options={mtvVacateTypeOptions}
          onChange={(val) => setVacateType(val)}
          value={vacateType}
          className={['mtv-vacate-type']}
        />
      )}

      <TextareaField
        name="instructions"
        label={JUDGE_ADDRESS_MTV_DISPOSITION_NOTES_LABEL}
        onChange={(val) => setInstructions(val)}
        value={instructions}
        className={['mtv-decision-instructions']}
      />

      <SearchableDropdown
        name="attorney"
        label={JUDGE_ADDRESS_MTV_ASSIGN_ATTORNEY_LABEL}
        searchable
        options={attorneys}
        placeholder="Select attorney"
        onChange={(option) => option && setAttorneyId(option.value)}
        value={attorneyId}
        // styling={css({ width: '30rem' })}
      />
    </div>
  );
};

MTVJudgeDisposition.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  task: PropTypes.object.isRequired,
  attorneys: PropTypes.array.isRequired
};
