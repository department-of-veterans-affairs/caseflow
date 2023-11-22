import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import { useSelector } from 'react-redux';
import { object, array } from 'yup';
import { get } from 'lodash';

import { MISSING_PERSONNEL } from 'constants/REPORT_PAGE_VALIDATION_ERRORS';
import SearchableDropdown from 'app/components/SearchableDropdown';

export const personnelSchema = object({
  personnel: array().of(object()).
    min(1, MISSING_PERSONNEL).
    typeError(MISSING_PERSONNEL)
});

export const Personnel = ({ control, field, name }) => {
  const { setValue, errors } = useFormContext();
  const teamMembers = useSelector((state) => (state.orgUsers.users));
  const namePersonnel = `${name}.options.personnel`;

  const dropdownOptions = useMemo(() => {
    return teamMembers.map((member) => (
      {
        label: member.full_name,
        value: member.css_id
      }
    )).sort((stringA, stringB) => stringA.label.localeCompare(stringB.label));
  }, [teamMembers]);

  return (
    <div className="report-page-multi-select-dropdown">
      <Controller
        control={control}
        defaultValue={field.options.personnel ?? ''}
        name={namePersonnel}
        render={({ ref, ...rest }) => {
          return (
            <SearchableDropdown
              {...rest}
              label="VHA team members"
              options={dropdownOptions}
              inputRef={ref}
              multi
              onChange={(valObj) => {
                setValue(namePersonnel, valObj);
              }}
              errorMessage={get(errors, namePersonnel)?.message}
            />
          );
        }}
      />
    </div>
  );
};

Personnel.propTypes = {
  control: PropTypes.object,
  name: PropTypes.string,
  field: PropTypes.object,
};
