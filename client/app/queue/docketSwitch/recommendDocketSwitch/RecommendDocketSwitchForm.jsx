import React, { useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';

import { useForm, Controller } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

import {
  DOCKET_SWITCH_RECOMMENDATION_TITLE,
  DOCKET_SWITCH_RECOMMENDATION_INSTRUCTIONS,
} from '../../../../COPY';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../../components/Button';
import { sprintf } from 'sprintf-js';
import DISPOSITIONS from '../../../../constants/DOCKET_SWITCH_DISPOSITIONS';
import TextField from '../../../components/TextField';
import TextareaField from '../../../components/TextareaField';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';

const schema = yup.object().shape({
  summary: yup.string().required(),
  timely: yup.string().required(),
  disposition: yup.
    mixed().
    oneOf(Object.keys(DISPOSITIONS)).
    required(),
  hyperlink: yup.string(),
  judge: yup.
    object().
    shape({ label: yup.string().required(), value: yup.number().required() }).
    required(),
});

const TIMELY_OPTIONS = [
  { displayText: 'Yes', value: 'yes' },
  { displayText: 'No', value: 'no' },
];

export const RecommendDocketSwitchForm = ({
  appellantName,
  defaultJudgeId,
  judgeOptions = [],
  onCancel,
  onSubmit,
}) => {
  const { register, handleSubmit, formState, control, setValue } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });

  // The `SearchableDropdown` component uses objects as values, so here we determine that if defaultJudgeId is set
  const judgeDefault = useMemo(
    () =>
      judgeOptions.find(
        (opt) => defaultJudgeId && opt.value === defaultJudgeId
      ),
    [defaultJudgeId, judgeOptions]
  );
  const dispositionOptions = useMemo(() => Object.values(DISPOSITIONS), []);

  useEffect(() => {
    setValue('judge', judgeDefault);
  }, [judgeDefault]);

  return (
    <form
      className="docket-switch-recommendation"
      onSubmit={handleSubmit(onSubmit)}
      aria-label="Recommendation on Docket Switch"
    >
      <AppSegment filledBackground>
        <h1>{sprintf(DOCKET_SWITCH_RECOMMENDATION_TITLE, appellantName)}</h1>
        <p style={{ marginBottom: '30px' }}>
          {DOCKET_SWITCH_RECOMMENDATION_INSTRUCTIONS}
        </p>

        <TextareaField
          inputRef={register}
          name="summary"
          label="Add a summary of the request to switch dockets:"
          strongLabel
        />

        <RadioField
          name="timely"
          label="Is this request timely?"
          options={TIMELY_OPTIONS}
          inputRef={register}
          strongLabel
          vertical
        />

        <RadioField
          name="disposition"
          label="What is your recommendation for this request to switch dockets?"
          options={dispositionOptions}
          inputRef={register}
          strongLabel
          vertical
        />

        <TextField
          inputRef={register}
          name="hyperlink"
          label="Insert hyperlink to draft letter"
          strongLabel
        />

        <div style={{ maxWidth: '35rem' }}>
          <Controller
            as={SearchableDropdown}
            control={control}
            defaultValue={judgeDefault}
            name="judge"
            label="Assign to judge"
            searchable
            options={judgeOptions}
            placeholder="Select judge"
            strongLabel
          />
        </div>
      </AppSegment>
      <div className="controls cf-app-segment">
        <Button
          type="submit"
          name="submit"
          disabled={!formState.isValid}
          classNames={['cf-right-side']}
        >
          Submit
        </Button>
        {onCancel && (
          <Button
            type="button"
            name="Cancel"
            classNames={['cf-right-side', 'usa-button-secondary']}
            onClick={onCancel}
            styling={{ style: { marginRight: '1rem' } }}
          >
            Cancel
          </Button>
        )}
      </div>
    </form>
  );
};

RecommendDocketSwitchForm.propTypes = {
  appellantName: PropTypes.string.isRequired,
  defaultJudgeId: PropTypes.number,
  judgeOptions: PropTypes.array.isRequired,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func.isRequired,
};
