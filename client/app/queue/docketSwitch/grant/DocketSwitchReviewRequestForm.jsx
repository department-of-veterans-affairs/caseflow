import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { useForm } from 'react-hook-form';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { CheckoutButtons } from './CheckoutButtons';
import {
  DOCKET_SWITCH_GRANTED_REQUEST_LABEL,
  DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS
} from '../../../../COPY';
import { sprintf } from 'sprintf-js';
import { yupResolver } from '@hookform/resolvers';
import * as yup from 'yup';
import { css } from 'glamor';
import DateSelector from 'app/components/DateSelector';
import RadioField from '../../../components/RadioField';
import CheckboxGroup from '../../../components/CheckboxGroup';
import DISPOSITIONS from 'constants/DOCKET_SWITCH';

const schema = yup.object().shape({
  receiptDate: yup.date().required(),
  disposition: yup.
    mixed().
    oneOf(Object.keys(DISPOSITIONS)).
    required()
});

const docketTypeRadioOptions = [
  { value: 'direct_review',
    displayText: 'Direct Review' },
  { value: 'evidence_submission',
    displayText: 'Evidence Submission' },
  { value: 'hearing',
    displayText: 'Hearing' }
];

export const DocketSwitchReviewRequestForm = ({
  onSubmit,
  onCancel,
  appellantName,
  appeal
}) => {
  const { register, handleSubmit, formState, watch } = useForm({
    // add yup validation, etc
    // See DocketSwitchDenialForm for inspiration
    resolver: yupResolver(schema),
    mode: 'onChange',
  });
  const sectionStyle = css({ marginBottom: '24px' });
  const issueOptions = () => appeal.issues.map((issue, idx) => ({
    id: issue.id,
    label: `${idx + 1}. ${issue.description}`
  }));

  const dispositionOptions = useMemo(() => Object.values(DISPOSITIONS).filter((item) => item.value !== 'denied'), []);

  const watchDisposition = watch('disposition');

  return (
    <form
      className="docket-switch-granted-request"
      onSubmit={handleSubmit(onSubmit)}
      aria-label="Grant Docket Switch Request"
    >
      <AppSegment filledBackground>
        {/* This should go into COPY.json */}
        <h1>{sprintf(DOCKET_SWITCH_GRANTED_REQUEST_LABEL, appellantName)}</h1>
        <div {...sectionStyle}>{DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS}</div>

        {/* Add <form> and form fields */}
        <DateSelector
          inputRef={register}
          type="date"
          name="receiptDate"
          label="What is the Receipt Date of the docket switch request?"
          strongLabel
        />

        <RadioField
          name="disposition"
          label="How are you proceeding with this request to switch dockets?"
          options={dispositionOptions}
          inputRef={register}
          strongLabel
          vertical
        />

        { watchDisposition === 'partially_granted' &&
         <CheckboxGroup
           name="issues"
           label="Select the issue(s) that are switching dockets:"
           strongLabel
           options={issueOptions()}
         />
        }

        {watchDisposition &&
         <RadioField
           name="docketType"
           label="Which docket will the issue(s) be switched to?"
           options={docketTypeRadioOptions}
           inputRef={register}
           strongLabel
           vertical
         />
        }

      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          disabled={!formState.isValid}
          onCancel={onCancel}
          onSubmit={handleSubmit(onSubmit)}
        />
      </div>
    </form>
  );
};

DocketSwitchReviewRequestForm.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  appellantName: PropTypes.string.isRequired,
  appeal: PropTypes.object
};
