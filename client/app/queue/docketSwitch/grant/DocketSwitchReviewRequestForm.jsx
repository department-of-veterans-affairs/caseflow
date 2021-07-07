import React, { useEffect, useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useForm, Controller } from 'react-hook-form';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { CheckoutButtons } from './CheckoutButtons';
import {
  DOCKET_SWITCH_GRANTED_REQUEST_LABEL,
  DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS,
  DOCKET_SWITCH_REVIEW_REQUEST_PRIOR_TO_RAMP_DATE_ERROR,
  DOCKET_SWITCH_REVIEW_REQUEST_FUTURE_DATE_ERROR
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { css } from 'glamor';
import DateSelector from 'app/components/DateSelector';
import RadioField from 'app/components/RadioField';
import CheckboxGroup from 'app/components/CheckboxGroup';
import DISPOSITIONS from 'constants/DOCKET_SWITCH_DISPOSITIONS';

const schema = yup.object().shape({
  receiptDate: yup.date().required().
    nullable().
    transform((value, originalValue) => originalValue === '' ? null : value).
    min('2017-11-01', DOCKET_SWITCH_REVIEW_REQUEST_PRIOR_TO_RAMP_DATE_ERROR).
    max(new Date(), DOCKET_SWITCH_REVIEW_REQUEST_FUTURE_DATE_ERROR),
  disposition: yup.
    mixed().
    oneOf(Object.keys(DISPOSITIONS)).
    required(),
  docketType: yup.string().required(),
  // Validation of issueIds is conditional upon the selected disposition
  issueIds: yup.array(yup.string()).when('disposition', {
    is: 'partially_granted',
    then: yup.array().min(1),
    otherwise: yup.array().min(0),
  }),
});

const docketTypeRadioOptions = [
  { value: 'direct_review', displayText: 'Direct Review' },
  { value: 'evidence_submission', displayText: 'Evidence Submission' },
  { value: 'hearing', displayText: 'Hearing' },
];

export const DocketSwitchReviewRequestForm = ({
  defaultValues,
  onSubmit,
  onCancel,
  appellantName,
  docketFrom,
  issues,
}) => {
  const {
    register,
    handleSubmit,
    control,
    formState,
    trigger,
    watch,
    errors
  } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
    reValidateMode: 'onChange',
    defaultValues,
  });
  const { touched } = formState;

  const sectionStyle = css({ marginBottom: '24px' });

  const issueOptions = useMemo(
    () =>
      issues &&
      issues.map((issue, idx) => ({
        id: issue.id.toString(),
        label: `${idx + 1}. ${issue.description}`,
      })),
    [issues]
  );

  const dispositionOptions = useMemo(
    () =>
      Object.values(DISPOSITIONS).filter(
        (disposition) => disposition.value !== 'denied'
      ),
    []
  );

  // We want to prevent accidental selection of the same docket type
  const filteredDocketTypeOpts = useMemo(() => {
    return docketTypeRadioOptions.map(({ value, displayText }) => ({
      value,
      displayText:
        value === docketFrom ? `${displayText} (current docket)` : displayText,
      disabled: value === docketFrom,
    }));
  }, [docketTypeRadioOptions, docketFrom]);

  const watchDisposition = watch('disposition');

  // Ensure that we trigger revalidation whenever disposition changes
  useEffect(() => {
    trigger();
  }, [watchDisposition]);

  const [issueVals, setIssueVals] = useState({});

  // We have to do a bit of manual manipulation for issue IDs due to nature of CheckboxGroup
  const handleIssueChange = (evt) => {
    const newIssues = { ...issueVals, [evt.target.name]: evt.target.checked };

    setIssueVals(newIssues);

    // Form wants to track only the selected issue IDs
    return Object.keys(newIssues).filter((key) => newIssues[key]);
  };

  // Handle prepopulating issue checkboxes if defaultValues are present
  useEffect(() => {
    if (defaultValues?.issueIds) {
      const newIssues = { ...issueVals };

      for (const id of defaultValues.issueIds) {
        newIssues[id] = true;
      }
      setIssueVals(newIssues);
    }
  }, [defaultValues]);

  // Need a bit of extra handling before passing along
  const formatFormData = (formData) => {
    // Ensure that all issue IDs are selected if full grant is chosen
    if (formData.disposition === 'granted') {
      formData.issueIds = issues.map((item) => String(item.id));
    }
    onSubmit?.(formData);
  };

  return (
    <form
      className="docket-switch-granted-request"
      onSubmit={handleSubmit(formatFormData)}
      aria-label="Grant Docket Switch Request"
    >
      <AppSegment filledBackground>
        <h1>{sprintf(DOCKET_SWITCH_GRANTED_REQUEST_LABEL, appellantName)}</h1>
        <div {...sectionStyle}>
          {DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS}
        </div>

        <DateSelector
          inputRef={register}
          errorMessage={touched.receiptDate && errors.receiptDate?.message}
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

        {watchDisposition === 'partially_granted' && (
          <Controller
            name="issueIds"
            control={control}
            render={({ onChange: onCheckChange }) => {
              return (
                <CheckboxGroup
                  name="issues"
                  label="Select the issue(s) that are switching dockets:"
                  strongLabel
                  options={issueOptions}
                  onChange={(event) => onCheckChange(handleIssueChange(event))}
                  values={issueVals}
                />
              );
            }}
          />
        )}

        {watchDisposition && (
          <RadioField
            name="docketType"
            label="Which docket will the issue(s) be switched to?"
            options={filteredDocketTypeOpts}
            inputRef={register}
            strongLabel
            vertical
          />
        )}
      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          disabled={!formState.isValid}
          onCancel={onCancel}
          onSubmit={handleSubmit(formatFormData)}
        />
      </div>
    </form>
  );
};

DocketSwitchReviewRequestForm.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  appellantName: PropTypes.string.isRequired,
  docketFrom: PropTypes.string.isRequired,
  issues: PropTypes.array,
  defaultValues: PropTypes.shape({
    disposition: PropTypes.string,
    receiptDate: PropTypes.string,
    docketType: PropTypes.string,
    issueIds: PropTypes.arrayOf(
      PropTypes.oneOfType([PropTypes.string, PropTypes.number])
    ),
  }),
};
