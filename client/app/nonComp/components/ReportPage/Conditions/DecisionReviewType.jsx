import React from 'react';
import PropTypes from 'prop-types';
import { useFormContext } from 'react-hook-form';
import Checkbox from 'app/components/Checkbox';
import * as yup from 'yup';
import { get } from 'lodash';
import { AT_LEAST_ONE_OPTION } from 'constants/REPORT_PAGE_VALIDATION_ERRORS';

const CHECKBOX_OPTIONS = [
  {
    label: 'Higher-Level Reviews',
    name: 'HigherLevelReview'
  },
  {
    label: 'Supplemental Claims',
    name: 'SupplementalClaim'
  }
];

export const decisionReviewTypeSchema = yup.object({
  HigherLevelReview: yup.boolean(),
  SupplementalClaim: yup.boolean(),
}).test('at-least-one-true', AT_LEAST_ONE_OPTION, (obj) => {
  const atLeastOneTrue = Object.values(obj).some((value) => value === true);

  if (!atLeastOneTrue) {
    return false;
  }

  return true;
});

export const DecisionReviewType = ({ field, name, register }) => {
  const { errors } = useFormContext();
  const hasFormErrors = get(errors, name);

  const classNames = hasFormErrors ?
    'decisionReviewTypeContainer decisionReviewTypeContainerError' :
    'decisionReviewTypeContainer';

  const errorMessage = get(errors, name)?.options?.message;

  return (
    <div className={classNames}>
      {hasFormErrors ?
        <div className="usa-input-error-message" style={{ padding: 0 }}>{errorMessage}</div> :
        null
      }
      <div className="decisionReviewCheckboxContainer">
        {CHECKBOX_OPTIONS.map((checkbox) => (
          <Checkbox
            defaultValue={field.options?.[checkbox.name]}
            key={`checkbox-${checkbox.name}`}
            inputRef={register}
            label={checkbox.label}
            name={`${name}.options.${checkbox.name}`}
            unpadded
          />
        ))}
      </div>
    </div>
  );
};

DecisionReviewType.propTypes = {
  field: PropTypes.object,
  name: PropTypes.string,
  register: PropTypes.func
};
