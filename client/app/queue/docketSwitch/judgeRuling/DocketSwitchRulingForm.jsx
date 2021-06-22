import React, { useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';

import { useForm, Controller } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

import {
  DOCKET_SWITCH_RULING_TITLE,
  DOCKET_SWITCH_RULING_INSTRUCTIONS,
} from 'app/../COPY';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from 'app/components/Button';
import { sprintf } from 'sprintf-js';
import DISPOSITIONS from 'constants/DOCKET_SWITCH_DISPOSITIONS';
import TextareaField from 'app/components/TextareaField';
import RadioField from 'app/components/RadioField';
import SearchableDropdown from 'app/components/SearchableDropdown';
import ReactMarkdown from 'react-markdown';
import gfm from 'remark-gfm';
import { css } from 'glamor';

const schema = yup.object().shape({
  disposition: yup.
    mixed().
    oneOf(Object.keys(DISPOSITIONS)).
    required(),
  context: yup.string(),
  attorney: yup.
    object().
    shape({ label: yup.string().required(), value: yup.number().required() }).
    required(),
});

export const DocketSwitchRulingForm = ({
  appellantName,
  defaultAttorneyId,
  clerkOfTheBoardAttorneys = [],
  onCancel,
  onSubmit,
  instructions,
}) => {
  const { register, handleSubmit, formState, control, setValue } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });

  const defaultAttorney = useMemo(
    () =>
      clerkOfTheBoardAttorneys.find(
        (opt) => defaultAttorneyId && opt.value === defaultAttorneyId
      ),
    [defaultAttorneyId, clerkOfTheBoardAttorneys]
  );

  const dispositionOptions = useMemo(() => Object.values(DISPOSITIONS), []);

  const sectionStyle = css({ marginBottom: '24px' });

  useEffect(() => {
    setValue('attorney', defaultAttorney);
  }, [defaultAttorney]);

  return (
    <form
      className="docket-switch-ruling"
      onSubmit={handleSubmit(onSubmit)}
      aria-label="Rule on Docket Switch"
    >
      <AppSegment filledBackground>
        <h1>{sprintf(DOCKET_SWITCH_RULING_TITLE, appellantName)}</h1>
        <div {...sectionStyle}>
          <ReactMarkdown source={DOCKET_SWITCH_RULING_INSTRUCTIONS} />
        </div>
        <hr {...sectionStyle} />
        <div {...sectionStyle}>
          <ReactMarkdown plugins={[gfm]} source={instructions[0]} linkTarget="_blank" />
        </div>
        <hr {...sectionStyle} />

        <RadioField
          name="disposition"
          label="How will you rule on this docket switch?"
          options={dispositionOptions}
          inputRef={register}
          strongLabel
          vertical
        />

        <TextareaField
          inputRef={register}
          name="context"
          label="Provide any additional context and instructions"
          strongLabel
        />

        <div style={{ maxWidth: '35rem' }}>
          <Controller
            as={SearchableDropdown}
            control={control}
            defaultValue={defaultAttorney}
            name="attorney"
            label="Assign to Office of the Clerk of the Board"
            searchable
            options={clerkOfTheBoardAttorneys}
            placeholder="Select attorney"
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

DocketSwitchRulingForm.propTypes = {
  appellantName: PropTypes.string.isRequired,
  defaultAttorneyId: PropTypes.number,
  clerkOfTheBoardAttorneys: PropTypes.array.isRequired,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func.isRequired,
  instructions: PropTypes.array.isRequired
};
