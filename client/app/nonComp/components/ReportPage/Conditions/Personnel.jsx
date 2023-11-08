import React from 'react';
import PropTypes from 'prop-types';
import { Controller, useFormContext } from 'react-hook-form';
import { useSelector } from 'react-redux';

import SearchableDropdown from 'app/components/SearchableDropdown';

export const Personnel = ({ control, field, name }) => {
  const { setValue } = useFormContext();
  const teamMembers = useSelector((state) => (state.orgUsers.users));

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
        name={`${name}.options.personnel`}
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
                  setValue(`${name}.options.personnel`, valObj);
                }}
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
