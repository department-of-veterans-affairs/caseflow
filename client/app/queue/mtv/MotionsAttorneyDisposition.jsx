import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { Link } from 'react-router-dom';
import {
  MOTIONS_ATTORNEY_ADDRESS_MTV_TITLE,
  MOTIONS_ATTORNEY_REVIEW_MTV_DESCRIPTION,
  MOTIONS_ATTORNEY_REVIEW_MTV_DISPOSITION_SELECT_LABEL,
  MOTIONS_ATTORNEY_REVIEW_MTV_DISPOSITION_NOTES_LABEL,
  MOTIONS_ATTORNEY_REVIEW_MTV_ASSIGN_JUDGE_LABEL
} from '../../../COPY';
import { MTVDispositionSelection } from './MTVDispositionSelection';
import TextareaField from '../../components/TextareaField';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { css } from 'glamor';
import { MTVTaskHeader } from './MTVTaskHeader';
import { DISPOSITION_TEXT } from '../../../constants/MOTION_TO_VACATE';
import { sprintf } from 'sprintf-js';
import { DecisionHyperlinks } from './forms/DecisionHyperlinks';

const formatReviewAttyInstructions = ({ disposition, hyperlinks, instructions }) => {
  const parts = [`I recommend ${DISPOSITION_TEXT[disposition]}.`, instructions];

  if (hyperlinks.length) {
    parts.push('\n\nDocument Links:');

    // Handle the link to draft, and remove from array
    const motionDraft = hyperlinks.shift();

    parts.push(`\n\nHere is the hyperlink to the draft of the motion:\n${motionDraft.link}`);

    // Handle denied/dismissed draft
    const denialDraft = hyperlinks.shift();

    if (['denied', 'dismissed'].includes(disposition)) {
      parts.push(`\n\nHere is the hyperlink to the ${DISPOSITION_TEXT[disposition]} draft:\n${denialDraft.link}`);
    }

    // Handle any remaining hyperlinks that might exist
    for (const item of hyperlinks) {
      parts.push(`\n\nHere is the hyperlink to the ${item.type}:\n${item.link}\n`);
    }
  }

  return parts.join('\n');
};

export const MotionsAttorneyDisposition = ({ judges, selectedJudge, task, appeal, onSubmit, submitting = false }) => {
  const cancelLink = `/queue/appeals/${task.externalAppealId}`;

  const [disposition, setDisposition] = useState(null);
  const [hyperlinks, setHyperlinks] = useState([]);
  const [instructions, setInstructions] = useState('');
  const [judgeId, setJudgeId] = useState(selectedJudge ? selectedJudge.id : null);

  const handleSubmit = () => {
    const formattedInstructions = formatReviewAttyInstructions({
      disposition,
      hyperlinks,
      instructions
    });

    return console.log('formattedInstructions', formattedInstructions);

    const newTask = {
      instructions: formattedInstructions,
      assigned_to_id: judgeId
    };

    onSubmit(newTask);
  };

  const valid = () => {
    if (!disposition || !judgeId) {
      return false;
    }

    return true;
  };

  return (
    <div className="address-motion-to-vacate">
      <AppSegment filledBackground>
        <MTVTaskHeader title={MOTIONS_ATTORNEY_ADDRESS_MTV_TITLE} task={task} appeal={appeal} />

        <p>{MOTIONS_ATTORNEY_REVIEW_MTV_DESCRIPTION}</p>

        {task.instructions && <p className="mtv-task-instructions">{task.instructions}</p>}

        <MTVDispositionSelection
          label={MOTIONS_ATTORNEY_REVIEW_MTV_DISPOSITION_SELECT_LABEL}
          onChange={(val) => setDisposition(val)}
          value={disposition}
        />

        <TextareaField
          name="instructions"
          label={sprintf(MOTIONS_ATTORNEY_REVIEW_MTV_DISPOSITION_NOTES_LABEL, disposition || 'granted')}
          onChange={(val) => setInstructions(val)}
          value={instructions}
          className={['mtv-review-instructions']}
          optional
          strongLabel
        />

        {disposition && <DecisionHyperlinks onChange={(values) => setHyperlinks(values)} disposition={disposition} />}

        <SearchableDropdown
          name="judge"
          label={MOTIONS_ATTORNEY_REVIEW_MTV_ASSIGN_JUDGE_LABEL}
          searchable
          options={judges}
          placeholder="Select judge"
          onChange={(option) => option && setJudgeId(option.value)}
          value={judgeId}
          styling={css({ width: '30rem' })}
          strongLabel
        />
      </AppSegment>
      <div className="controls cf-app-segment">
        <Button
          type="button"
          name="submit"
          classNames={['cf-right-side']}
          onClick={handleSubmit}
          disabled={!valid() || submitting}
          styling={css({ marginLeft: '1rem' })}
        >
          Submit
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

MotionsAttorneyDisposition.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  submitting: PropTypes.bool,
  task: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired,
  judges: PropTypes.array.isRequired,
  selectedJudge: PropTypes.object
};
