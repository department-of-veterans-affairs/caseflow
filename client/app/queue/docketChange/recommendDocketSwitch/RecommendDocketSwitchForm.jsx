import React from 'react';
import PropTypes from 'prop-types';

import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers';
import * as yup from 'yup';

import { DOCKET_SWITCH_RECOMMENDATION_TITLE } from '../../../../COPY';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../../components/Button';
import { sprintf } from 'sprintf-js';
import { dispositionOptions, dispositions } from '../constants';
import TextareaField from '../../../components/TextareaField';
import RadioField from '../../../components/RadioField';

const schema = yup.object().shape({
  summary: yup.string(),
  timely: yup.string().required(),
  disposition: yup.
    mixed().
    oneOf(dispositions).
    required(),
  hyperlink: yup.string(),
});

const TIMELY_OPTIONS = [
  { displayText: 'Yes', value: 'yes' },
  { displayText: 'No', value: 'no' },
];

export const RecommendDocketSwitchForm = ({
  claimantName,
  onCancel,
  onSubmit,
}) => {
  const { register, handleSubmit, errors, formState } = useForm({
    resolver: yupResolver(schema),
    mode: 'onBlur',
  });

  return (
    <form
      className="docket-change-recommendation"
      onSubmit={handleSubmit(onSubmit)}
    >
      <AppSegment filledBackground>
        <h1>{sprintf(DOCKET_SWITCH_RECOMMENDATION_TITLE, claimantName)}</h1>

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
          label="What is your recommendattion for this request to switch dockets?"
          options={dispositionOptions}
          inputRef={register}
          strongLabel
          vertical
        />
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
  claimantName: PropTypes.string.isRequired,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func.isRequired,
};
