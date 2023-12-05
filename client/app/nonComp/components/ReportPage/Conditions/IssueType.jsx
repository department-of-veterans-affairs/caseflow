import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import { get } from 'lodash';
import * as yup from 'yup';
import SearchableDropdown from 'app/components/SearchableDropdown';
import ISSUE_CATEGORIES from 'constants/ISSUE_CATEGORIES';

export const issueTypeSchema = yup.object({
  issueTypes: yup.string().required('Please select an option')
});

const formattedIssueTypeCodes = ISSUE_CATEGORIES.vha.map((issue) => {
  return {
    value: issue,
    label: issue
  };
}).
  sort((stringA, stringB) => stringA.label.localeCompare(stringB.label));

export const IssueType = ({ control, field, name }) => {
  const { errors } = useFormContext();
  const nameIssueTypeCodes = `${name}.options.issueTypeCodes`;

  return (
    <div className="issue-type-container">
      <Controller
        control={control}
        name={nameIssueTypeCodes}
        defaultValue={field.options.issueTypeCodes ?? []}
        render={({ onChange, ref, ...rest }) => (
          <SearchableDropdown
            {...rest}
            errorMessage={get(errors, nameIssueTypeCodes)?.message}
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
