import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import { get } from 'lodash';
import * as yup from 'yup';
import SearchableDropdown from 'app/components/SearchableDropdown';
import ISSUE_CATEGORIES from 'constants/ISSUE_CATEGORIES';
import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';

export const issueTypeSchema = yup.object({
  issueTypes: yup.array().min(1, ERRORS.AT_LEAST_ONE_OPTION)
});

const formattedIssueTypes = ISSUE_CATEGORIES.vha.map((issue) => {
  return {
    value: issue,
    label: issue
  };
}).
  sort((stringA, stringB) => stringA.label.localeCompare(stringB.label));

export const IssueType = ({ control, field, name }) => {
  const { errors } = useFormContext();
  const nameIssueTypes = `${name}.options.issueTypes`;

  return (
    <div className="report-page-multi-select-dropdown issue-type">
      <Controller
        control={control}
        name={nameIssueTypes}
        defaultValue={field.options.issueTypes ?? []}
        render={({ onChange, ref, ...rest }) => (
          <SearchableDropdown
            {...rest}
            errorMessage={get(errors, nameIssueTypes)?.message}
            inputRef={ref}
            label="Issue Type"
            multi
            onChange={onChange}
            options={formattedIssueTypes}
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
