import React from 'react';
import PropTypes from 'prop-types';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { isDate, max, parseISO } from 'date-fns';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_SELECT_APPELLANT_TITLE,
  SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD,
} from 'app/../COPY';
import Button from 'app/components/Button';
import DateSelector from 'app/components/DateSelector';
import RadioField from 'app/components/RadioField';
import { pageHeader } from '../styles';

export const subDateMinErrorMsg =
  "Date cannot be earlier than the NOD date or the Veteran's date of death";

const schema = yup.object().shape({
  substitutionDate: yup.
    date().
    required('Substitution Date is required').
    nullable().
    max(new Date(), 'Date cannot be in the future').
    when(['$nodDate', '$dateOfDeath'], (date1, date2, currentSchema) => {
      const dates = [date1, date2].map((d) => (isDate(d) ? d : parseISO(d))); // eslint-disable-line id-length

      return currentSchema.min(max(dates), subDateMinErrorMsg);
    }).
    transform((value, originalValue) => (originalValue === '' ? null : value)),
  participantId: yup.string().required('You must select a claimant'),
});

export const SubstituteAppellantBasicsForm = ({
  existingValues,
  onCancel,
  onSubmit,
  dateOfDeath,
  nodDate,
  relationships = [],
  loadingRelationships = false,
}) => {
  const { errors, handleSubmit, register } = useForm({
    // Use this for repopulating form from redux when user navigates back
    defaultValues: { ...existingValues },
    resolver: yupResolver(schema),
    context: { nodDate, dateOfDeath },
    reValidateMode: 'onChange',
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <AppSegment filledBackground>
        <section className={pageHeader}>
          <h1>{SUBSTITUTE_APPELLANT_SELECT_APPELLANT_TITLE}</h1>
          <div>{SUBSTITUTE_APPELLANT_SELECT_APPELLANT_SUBHEAD}</div>
        </section>

        <DateSelector
          inputRef={register}
          type="date"
          errorMessage={errors.substitutionDate?.message}
          name="substitutionDate"
          label="When was substitution granted for this appellant?"
          strongLabel
        />

        {loadingRelationships && <div>Fetching relationships...</div>}
        {!loadingRelationships &&
          (relationships ? (
            <RadioField
              errorMessage={errors?.participantId?.message}
              inputRef={register}
              label="Please select the substitute from the following claimants."
              name="participantId"
              options={relationships}
              strongLabel
              vertical
            />
          ) : (
            <div>No existing relationships found</div>
          ))}
      </AppSegment>
      <div className="controls cf-app-segment">
        <Button type="submit" name="submit" classNames={['cf-right-side']}>
          Continue
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
SubstituteAppellantBasicsForm.propTypes = {
  existingValues: PropTypes.shape({
    substitutionDate: PropTypes.string,
    participantId: PropTypes.string,
  }),
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  nodDate: PropTypes.oneOfType([PropTypes.string, PropTypes.instanceOf(Date)]),
  dateOfDeath: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.instanceOf(Date),
  ]),
  relationships: PropTypes.arrayOf(
    PropTypes.shape({
      value: PropTypes.string,
      displayText: PropTypes.string,
    })
  ),
  loadingRelationships: PropTypes.bool,
};
