import React from 'react';
import { Controller, useFormContext } from 'react-hook-form';
import SearchableDropdown from 'app/components/SearchableDropdown';
import ISSUE_CATEGORIES from 'constants/ISSUE_CATEGORIES';

const IssueTypeSelector = () => {
  const { control, errors } = useFormContext();

  const formattedIssueTypes = ISSUE_CATEGORIES.vha.map((issue) => {
    return {
      value: issue,
      label: issue
    };
  });

  return <Controller
    control={control}
    name="nonratingIssueCategory"
    render={({ onChange, ref, ...rest }) => (
      <SearchableDropdown
        {...rest}
        label="Issue type"
        options={formattedIssueTypes}
        inputRef={ref}
        errorMessage={errors.nonratingIssueCategory?.message}
        onChange={(valObj) => {
          onChange(valObj?.value);
        }}
      />
    )}
  />;
};

export default IssueTypeSelector;
