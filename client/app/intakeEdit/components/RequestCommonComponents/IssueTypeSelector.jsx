import React from 'react';
import { Controller, useFormContext } from 'react-hook-form';
import SearchableDropdown from 'app/components/SearchableDropdown';
import ISSUE_CATEGORIES from 'constants/ISSUE_CATEGORIES';
import { useSelector } from 'react-redux';

const IssueTypeSelector = () => {
  const { control } = useFormContext();
  const benefitType = useSelector((state) => state.benefitType);

  const formattedIssueTypes = ISSUE_CATEGORIES[benefitType].map((issue) => {
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
        onChange={(valObj) => {
          onChange(valObj?.value);
        }}
      />
    )}
  />;
};

export default IssueTypeSelector;
