import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import * as yup from 'yup';
import { get } from 'lodash';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { AT_LEAST_ONE_OPTION } from 'constants/REPORT_PAGE_VALIDATION_ERRORS';

const DROPDOWN_OPTIONS = [
  {
    label: 'Higher-Level Reviews',
    value: 'HigherLevelReview'
  },
  {
    label: 'Supplemental Claims',
    value: 'SupplementalClaim'
  },
  {
    label: 'Remands',
    value: 'Remand'
  }
];

export const decisionReviewTypeSchema = yup.object({
  decisionReviewTypes: yup.array().min(1, AT_LEAST_ONE_OPTION)
});

export const DecisionReviewType = ({ control, field, name }) => {
  const { errors } = useFormContext();
  const nameDecisionReviewTypes = `${name}.options.decisionReviewTypes`;

  return (
    <div className="report-page-multi-select-dropdown decision-review-types">
      <Controller
        control={control}
        name={nameDecisionReviewTypes}
        defaultValue={field.options.decisionReviewTypes ?? []}
        render={({ onChange, ref, ...rest }) => (
          <SearchableDropdown
            {...rest}
            errorMessage={get(errors, nameDecisionReviewTypes)?.message}
            inputRef={ref}
            label="Decision Review Type"
            multi
            onChange={onChange}
            options={DROPDOWN_OPTIONS}
          />
        )}
      />
    </div>
  );
};

DecisionReviewType.propTypes = {
  control: PropTypes.object,
  field: PropTypes.object,
  name: PropTypes.string,
};
