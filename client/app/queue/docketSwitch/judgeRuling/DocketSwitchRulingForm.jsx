import React, { useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';

import { useForm, Controller } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers';
import * as yup from 'yup';

import {
  DOCKET_SWITCH_RULING_TITLE,
  DOCKET_SWITCH_RULING_INSTRUCTIONS,
} from '../../../../COPY';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from '../../../components/Button';
import { sprintf } from 'sprintf-js';
import { dispositions } from '../constants';
import TextField from '../../../components/TextField';
import TextareaField from '../../../components/TextareaField';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import ReactMarkdown from 'react-markdown';

const schema = yup.object().shape({
  disposition: yup.
    mixed().
    oneOf(Object.keys(dispositions)).
    required(),
  hyperlink: yup.string(),
  context: yup.string().required(),
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
  instructions
}) => {
  const { register, handleSubmit, formState, control, setValue } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });

  const attorneyDefault = useMemo(
    () =>
      clerkOfTheBoardAttorneys.find(
        (opt) => defaultAttorneyId && opt.value === defaultAttorneyId
      ),
    [defaultAttorneyId, clerkOfTheBoardAttorneys]
  );
  const dispositionOptions = useMemo(() => Object.values(dispositions), []);

  const formatBreaks = (text = '') => {
    // Somehow the contents are occasionally an array, at least in tests
    // Here we'll format the individual items, then just join to ensure we return string
    if (Array.isArray(text)) {
      return text.map((item) => item.replace(/<br>|(?<! {2})\n/g, '  \n')).join(' ');
    }

    // Normally this should just be a string
    return text.replace(/<br>|(?<! {2})\n/g, '  \n');
  };

  useEffect(() => {
    setValue('attorney', attorneyDefault);
  }, [attorneyDefault]);

  return (
    <form
      className="docket-switch-ruling"
      onSubmit={handleSubmit(onSubmit)}
      aria-label="Rule on Docket Switch"
    >
      <AppSegment filledBackground>
        <h1>{sprintf(DOCKET_SWITCH_RULING_TITLE, appellantName)}</h1>
        <p style={{ marginBottom: '30px' }}>
        <div><ReactMarkdown source={formatBreaks(DOCKET_SWITCH_RULING_INSTRUCTIONS)} /></div>
        <hr />
        <div><ReactMarkdown source={formatBreaks(instructions)} /></div>
        <hr />
        </p>

        <RadioField
          name="disposition"
          label="How will you rule on this docket switch?"
          options={dispositionOptions}
          inputRef={register}
          strongLabel
          vertical
        />

        <TextField
          inputRef={register}
          name="hyperlink"
          label="Insert hyperlink to signed ruling letter"
          strongLabel
          optional
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
            defaultValue={attorneyDefault}
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
};
