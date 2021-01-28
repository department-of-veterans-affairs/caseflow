import React from 'react';
import PropTypes from 'prop-types';

import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

import {
  DOCKET_SWITCH_DENIAL_TITLE,
  DOCKET_SWITCH_DENIAL_INSTRUCTIONS,
} from 'app/../COPY';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Button from 'app/components/Button';
import { sprintf } from 'sprintf-js';
import DateSelector from 'app/components/DateSelector';
import TextareaField from 'app/components/TextareaField';
import { css } from 'glamor';

const schema = yup.object().shape({
  receiptDate: yup.date().required(),
  context: yup.string().required(),
});

export const DocketSwitchDenialForm = ({
  appellantName,
  onCancel,
  onSubmit,
}) => {
  const { register, handleSubmit, formState } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });

  const sectionStyle = css({ marginBottom: '24px' });

  return (
    <form
      className="docket-switch-denial"
      onSubmit={handleSubmit(onSubmit)}
      aria-label="Deny Docket Switch"
    >
      <AppSegment filledBackground>
        <h1>{sprintf(DOCKET_SWITCH_DENIAL_TITLE, appellantName)}</h1>
        <div {...sectionStyle}>{DOCKET_SWITCH_DENIAL_INSTRUCTIONS}</div>

        <DateSelector
          inputRef={register}
          type="date"
          name="receiptDate"
          label="What is the Receipt Date of the docket switch request?"
          strongLabel
        />

        <TextareaField
          inputRef={register}
          name="context"
          label="Provide context for this denial (this will be visible in the Case Timeline)"
          strongLabel
        />
      </AppSegment>
      <div className="controls cf-app-segment">
        <Button
          type="submit"
          name="submit"
          disabled={!formState.isValid}
          classNames={['cf-right-side']}
        >
          Confirm
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

DocketSwitchDenialForm.propTypes = {
  appellantName: PropTypes.string.isRequired,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func.isRequired,
};
