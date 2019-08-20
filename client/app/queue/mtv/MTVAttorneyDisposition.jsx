import React, { useState } from 'react';
import PropTypes from 'prop-types';

import {
  ATTORNEY_REVIEW_MTV_DESCRIPTION,
  ATTORNEY_REVIEW_MTV_DISPOSITION_SELECT_LABEL,
  ATTORNEY_REVIEW_MTV_DISPOSITION_NOTES_LABEL,
  ATTORNEY_REVIEW_MTV_HYPERLINK_LABEL,
  ATTORNEY_REVIEW_MTV_ASSIGN_JUDGE_LABEL
} from '../../../COPY.json';
import { MTVDispositionSelection } from './MTVDispositionSelection';
import TextareaField from '../../components/TextareaField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

export const MTVAttorneyDisposition = ({ judges, task }) => {
  const { assignedTo } = task;

  const [disposition, setDisposition] = useState(null);
  const [hyperlink, setHyperlink] = useState(null);
  const [instructions, setInstructions] = useState('');
  const [judgeId, setJudgeId] = useState(assignedTo ? assignedTo.id : null);

  return (
    <AppSegment filledBackground>
      <div className="address-motion-to-vacate">
        <p>{ATTORNEY_REVIEW_MTV_DESCRIPTION}</p>

        <p className="mtv-task-instructions">{task.instructions}</p>

        <MTVDispositionSelection
          label={ATTORNEY_REVIEW_MTV_DISPOSITION_SELECT_LABEL}
          onChange={(val) => setDisposition(val)}
          value={disposition}
        />

        <TextareaField
          name="instructions"
          label={ATTORNEY_REVIEW_MTV_DISPOSITION_NOTES_LABEL}
          onChange={(val) => setInstructions(val)}
          value={instructions}
          className={['mtv-review-instructions']}
        />

        <TextField
          name="hyperlink"
          label={ATTORNEY_REVIEW_MTV_HYPERLINK_LABEL}
          value={hyperlink}
          onChange={(val) => setHyperlink(val)}
          className={['mtv-review-hyperlink']}
        />

        <SearchableDropdown
          name="judge"
          label={ATTORNEY_REVIEW_MTV_ASSIGN_JUDGE_LABEL}
          searchable
          options={judges}
          placeholder="Select judge"
          onChange={(option) => option && setJudgeId(option.value)}
          value={judgeId}
          // styling={css({ width: '30rem' })}
        />
      </div>
    </AppSegment>
  );
};

MTVAttorneyDisposition.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  task: PropTypes.object.isRequired,
  judges: PropTypes.array.isRequired
};
