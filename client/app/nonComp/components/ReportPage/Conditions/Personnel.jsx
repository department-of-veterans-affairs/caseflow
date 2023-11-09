import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import { useSelector } from 'react-redux';
import { object, array } from 'yup';
import { get } from 'lodash';

import SearchableDropdown from 'app/components/SearchableDropdown';

export const personnelSchema = object({
  personnel: array().of(object()).
    min(1, 'Error: At least one person must be selected').
    typeError('Error: At least one person must be selected')
});

export const Personnel = ({ control, field, name }) => {
  const { setValue, errors } = useFormContext();
  const teamMembers = useSelector((state) => (state.orgUsers.users));
  const namePersonnel = `${name}.options.personnel`;

  const dropdownOptions = teamMembers.map((member) => (
    {
      label: member.full_name,
      value: member.css_id
    }
  ));

  return (
    <>
      <Controller
        control={control}
        defaultValue={field.options.personnel ?? ''}
        name={namePersonnel}
        render={({ ref, ...rest }) => {
          return (
            <>
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
            </>
          );
        }}
      />
    </>
  );
};

Personnel.propTypes = {
  control: PropTypes.object,
  name: PropTypes.string,
  field: PropTypes.object,
};
