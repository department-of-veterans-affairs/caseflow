import React from 'react';
import PropTypes from 'prop-types';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  GRANTED_SUBSTITUTION_SELECT_APPELLANT_TITLE,
  GRANTED_SUBSTITUTION_SELECT_APPELLANT_SUBHEAD,
} from 'app/../COPY';
import Button from 'app/components/Button';
import DateSelector from 'app/components/DateSelector';
import RadioField from 'app/components/RadioField';

const schema = yup.object().shape({
  substitutionDate: yup.
    date().
    required().
    nullable().
    transform((value, originalValue) => (originalValue === '' ? null : value)),
  participantId: yup.string().required('You must select a claimant'),
});

const sectionStyle = css({ marginBottom: '24px' });

export const GrantedSubstitutionBasicsForm = ({
  onCancel,
  onSubmit,
  relationships = [],
}) => {
  const {
    errors,
    formState: { touched },
    handleSubmit,
    register,
  } = useForm({
    defaultValues: {}, // Use this for repopulating form from redux when user navigates back
    resolver: yupResolver(schema),
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <AppSegment filledBackground>
        <h1>{GRANTED_SUBSTITUTION_SELECT_APPELLANT_TITLE}</h1>
        <div {...sectionStyle}>
          {GRANTED_SUBSTITUTION_SELECT_APPELLANT_SUBHEAD}
        </div>

        <DateSelector
          inputRef={register}
          type="date"
          errorMessage={
            touched.substitutionDate && errors.substitutionDate?.message
          }
          name="substitutionDate"
          label="When was substitution granted for this appellant?"
          strongLabel
        />

        <RadioField
          errorMessage={errors?.participantId?.message}
          inputRef={register}
          label="Please select the granted substitute from the following claimants"
          name="participantId"
          options={relationships}
          strongLabel
          vertical
        />
      </AppSegment>
      <div className="controls cf-app-segment">
        <Button type="submit" name="submit" classNames={['cf-right-side']}>
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
GrantedSubstitutionBasicsForm.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  relationships: PropTypes.arrayOf(
    PropTypes.shape({
      value: PropTypes.string,
      displayText: PropTypes.string,
    })
  ),
};
