import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { Link } from 'react-router-dom';

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
import Button from '../../components/Button';
import JudgeDropdown from '../../../app/components/DataDropdowns/Judge';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import JudgeSelectComponent from '../JudgeSelectComponent.jsx';
import { css } from 'glamor';

const formatReviewAttyInstructions = ({ disposition, hyperlink, instructions }) => {
  return `
  
  `;
};

export const MTVAttorneyDisposition = ({ judges, task, appeal, onSubmit }) => {
  // const { assignedTo } = task;

  const cancelLink = `/queue/appeals/${task.externalAppealId}`;

  const [disposition, setDisposition] = useState(null);
  const [hyperlink, setHyperlink] = useState(null);
  const [instructions, setInstructions] = useState('');
  // const [judgeId, setJudgeId] = useState(assignedTo ? assignedTo.id : null);
  const [judgeId, setJudgeId] = useState(null);

  const handleSubmit = () => {
    const newTask = {
      instructions: formatReviewAttyInstructions({ disposition,
        hyperlink,
        instructions }),
      assigned_to_id: judgeId
    };

    onSubmit(newTask);
  };

  const valid = () => {
    if (!disposition || !instructions || !judgeId || (disposition === 'denied' && !hyperlink)) {
      return false;
    }

    return true;
  };

  return (
    <div className="address-motion-to-vacate">
      <AppSegment filledBackground>
        <h1>Review {appeal.veteranFullName}'s Motion to Vacate</h1>

        <div className="case-meta">
          <span>
            <strong>Veteran ID:</strong> {appeal.veteranFileNumber}
          </span>
          <span style={{ marginLeft: '3rem' }}>
            <strong>Task:</strong> {task.label}
          </span>
        </div>
        <div className="cf-help-divider" style={{ margin: '15px 0' }} />

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

        {disposition && disposition === 'denied' && (
          <TextField
            name="hyperlink"
            label={ATTORNEY_REVIEW_MTV_HYPERLINK_LABEL}
            value={hyperlink}
            onChange={(val) => setHyperlink(val)}
            className={['mtv-review-hyperlink']}
          />
        )}

        {/* <JudgeSelectComponent label={ATTORNEY_REVIEW_MTV_ASSIGN_JUDGE_LABEL} judgeSelector={judgeId} selectingJudge /> */}

        {/* <JudgeDropdown
          label={ATTORNEY_REVIEW_MTV_ASSIGN_JUDGE_LABEL}
          onChange={(option) => option && setJudgeId(option.value)}
        /> */}

        <SearchableDropdown
          name="judge"
          label={ATTORNEY_REVIEW_MTV_ASSIGN_JUDGE_LABEL}
          searchable
          options={judges}
          placeholder="Select judge"
          onChange={(option) => option && setJudgeId(option.value)}
          value={judgeId}
          styling={css({ width: '30rem' })}
        />
      </AppSegment>
      <div className="controls cf-app-segment">
        <Button
          type="button"
          name="submit"
          classNames={['cf-right-side']}
          onClick={handleSubmit}
          //   loading={loading}
          disabled={!valid()}
          styling={css({ marginLeft: '1rem' })}
        >
          Submit Review
        </Button>
        <Link to={cancelLink}>
          <Button type="button" name="Cancel" classNames={['cf-right-side', 'usa-button-secondary']}>
            Cancel
          </Button>
        </Link>
      </div>
    </div>
  );
};

MTVAttorneyDisposition.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  task: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired,
  judges: PropTypes.array.isRequired
};
