import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import { get } from 'lodash';
import * as yup from 'yup';
import SearchableDropdown from 'app/components/SearchableDropdown';
import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';
import { ISSUE_DISPOSITION_LIST } from 'constants/REPORT_TYPE_CONSTANTS';

export const issueDispositionSchema = yup.object({
  issueDispositions: yup.array().min(1, ERRORS.AT_LEAST_ONE_OPTION)
});

export const IssueDisposition = ({ control, field, name }) => {
  const { errors } = useFormContext();
  const fieldName = `${name}.options.issueDispositions`;

  return (
    <div className="report-page-multi-select-dropdown issue-dispositions">
      <Controller
        control={control}
        name={fieldName}
        defaultValue={field.options.issueDispositions ?? []}
        render={({ onChange, ref, ...rest }) => (
          <SearchableDropdown
            {...rest}
            errorMessage={get(errors, fieldName)?.message}
            inputRef={ref}
            label="Issue Disposition"
            multi
            onChange={onChange}
            options={ISSUE_DISPOSITION_LIST}
          />
        )}
      />
    </div>
  );
};

IssueDisposition.propTypes = {
  control: PropTypes.object,
  field: PropTypes.object,
  name: PropTypes.string,
};
