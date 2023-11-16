import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import { get } from 'lodash';
import * as yup from 'yup';
import SearchableDropdown from 'app/components/SearchableDropdown';
import ISSUE_TYPES from '../../../../../constants/ISSUE_TYPES';

export const issueTypeSchema = yup.object({
  issueTypes: yup.string().required('Please select an option')
});

// Convert to array and sort alphabetically by label
const formattedIssueTypeCodes = Object.entries(ISSUE_TYPES).map((issue_type) => {
  return {
    value: issue_type[0],
    label: issue_type[1]
  };
}).
  sort((stringA, stringB) => stringA.label.localeCompare(stringB.label));

export const IssueType = ({ control, field, name }) => {
  const { errors } = useFormContext();

  return (
    <div className="issueTypeContainer">
      <Controller
        control={control}
        name={`${name}.options.issueTypeCodes`}
        defaultValue={field.options.issueTypeCodes ?? []}
        render={({ onChange, ref, ...rest }) => (
          <SearchableDropdown
            {...rest}
            errorMessage={get(errors, `${name}.options.issueTypeCodes`)?.message}
            inputRef={ref}
            label="Issue Type"
            multi
            onChange={onChange}
            options={formattedIssueTypeCodes}
          />
        )}
      />
    </div>
  );
};

IssueType.propTypes = {
  control: PropTypes.object,
  field: PropTypes.object,
  name: PropTypes.string,
};
