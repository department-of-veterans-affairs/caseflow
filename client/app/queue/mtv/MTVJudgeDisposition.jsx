import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { Link } from 'react-router-dom';

import {
  JUDGE_ADDRESS_MTV_TITLE,
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
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import { css } from 'glamor';
import { MTVTaskHeader } from './MTVTaskHeader';

export const MTVJudgeDisposition = ({
  attorneys,
  selectedAttorney,
  task,
  appeal,
  onSubmit = () => null,
  submitting = false
}) => {
  const cancelLink = `/queue/appeals/${task.externalAppealId}`;

  const [disposition, setDisposition] = useState(null);
  const [vacateType, setVacateType] = useState(null);
  const [instructions, setInstructions] = useState('');
  const [attorneyId, setAttorneyId] = useState(selectedAttorney ? selectedAttorney.id : null);

  const handleSubmit = () => {
    const newTask = {
      instructions,
      assigned_to_id: attorneyId
    };

    onSubmit(newTask);
  };

  const valid = () => {
    if (!disposition || !instructions || !attorneyId || (disposition === 'granted' && !vacateType)) {
      return false;
    }

    return true;
  };

  return (
    <div className="address-motion-to-vacate">
      <AppSegment filledBackground>
        <MTVTaskHeader title={JUDGE_ADDRESS_MTV_TITLE} task={task} appeal={appeal} />

        <p>{JUDGE_ADDRESS_MTV_DESCRIPTION}</p>

        <p className="mtv-task-instructions">{task.instructions}</p>

        <MTVDispositionSelection
          label={JUDGE_ADDRESS_MTV_DISPOSITION_SELECT_LABEL}
          onChange={(val) => {
            setVacateType(null);
            setDisposition(val);
          }}
          value={disposition}
        />

        {disposition && disposition === 'granted' && (
          <RadioField
            name="vacate_type"
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
          styling={css({ width: '30rem' })}
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

MTVJudgeDisposition.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  submitting: PropTypes.bool,
  task: PropTypes.object.isRequired,
  appeal: PropTypes.object.isRequired,
  attorneys: PropTypes.array.isRequired,
  selectedAttorney: PropTypes.object
};
