import React from 'react';
import { Controller } from 'react-hook-form';
import PropTypes from 'prop-types';
import SearchableDropdown from 'app/components/SearchableDropdown';

export const Personnel = ({ control, register }) => {
  const VHA_TEAM_MEMBERS = [
    {
      label: 'Option 1',
      value: 'option1'
    },
    {
      label: 'Option 2',
      value: 'option2'
    },
    {
      label: 'Option 3',
      value: 'option3'
    }
  ];

  return (
    <>
      <Controller
        control={control}
        defaultValue
        name="personnel"
        render={() => {
          return (
            <>
              <SearchableDropdown
                label="VHA team members"
                name="VHA team members"
                options={VHA_TEAM_MEMBERS}
                inputRef={register}
                multi
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
  register: PropTypes.func
};
