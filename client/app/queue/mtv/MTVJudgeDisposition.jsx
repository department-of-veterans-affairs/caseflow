import React, { useState } from 'react';
import PropTypes from 'prop-types';

import { Link } from 'react-router-dom';

import {
  JUDGE_ADDRESS_MTV_TITLE,
  JUDGE_ADDRESS_MTV_DESCRIPTION,
  JUDGE_ADDRESS_MTV_DISPOSITION_SELECT_LABEL,
  JUDGE_ADDRESS_MTV_VACATE_TYPE_LABEL,
  JUDGE_ADDRESS_MTV_HYPERLINK_LABEL,
  JUDGE_ADDRESS_MTV_DISPOSITION_NOTES_LABEL,
  JUDGE_ADDRESS_MTV_ASSIGN_ATTORNEY_LABEL
} from '../../../COPY.json';
import { MTVDispositionSelection } from './MTVDispositionSelection';
import TextareaField from '../../components/TextareaField';
import RadioField from '../../components/RadioField';
import { mtvVacateTypeOptions, mtvDispositionText } from './index';
import SearchableDropdown from '../../components/SearchableDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../components/Button';
import { css } from 'glamor';
import { MTVTaskHeader } from './MTVTaskHeader';
import TextField from '../../components/TextField';

const vacateTypeText = (val) => {
  const opt = mtvVacateTypeOptions.find((i) => i.value === val);

  return opt && opt.displayText;
};

const formatInstructions = ({ disposition, vacateType, hyperlink, instructions }) => {
  const parts = [`I am proceeding with a ${mtvDispositionText[disposition]}.`];

  switch (disposition) {
  case 'granted':
    parts.push(`This will be a ${vacateTypeText(vacateType)}`);
    parts.push(instructions);
    break;
  default:
    parts.push(instructions);
    parts.push('\nHere is the hyperlink to the signed denial document');
    parts.push(hyperlink);
    break;
  }

  return parts.join('\n');
};

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
  const [hyperlink, setHyperlink] = useState(null);
  const [attorneyId, setAttorneyId] = useState(selectedAttorney ? selectedAttorney.id : null);

  const handleSubmit = () => {
    const formattedInstructions = formatInstructions({
      disposition,
      vacateType,
      hyperlink,
      instructions
    });

    const result = {
      task_id: task.taskId,
      instructions: formattedInstructions,
      assigned_to_id: attorneyId,
      disposition,
      vacate_type: vacateType
    };

    onSubmit(result);
  };

  const isValid = () => {
    if (
      !disposition ||
      !instructions ||
      !attorneyId ||
      (disposition === 'granted' && !vacateType) ||
      (disposition !== 'granted' && !hyperlink)
    ) {
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
            required
            className={['mtv-vacate-type']}
          />
        )}

        {disposition && disposition !== 'granted' && (
          <TextField
            name="hyperlink"
            label={JUDGE_ADDRESS_MTV_HYPERLINK_LABEL}
            value={hyperlink}
            onChange={(val) => setHyperlink(val)}
            required
            className={['mtv-review-hyperlink']}
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
          disabled={!isValid() || submitting}
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
