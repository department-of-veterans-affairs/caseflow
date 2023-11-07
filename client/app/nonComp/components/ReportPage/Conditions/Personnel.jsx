import React, { useEffect, useState } from 'react';
import { Controller } from 'react-hook-form';
import PropTypes from 'prop-types';

import SearchableDropdown from 'app/components/SearchableDropdown';
import ApiUtil from 'app/util/ApiUtil';

export const Personnel = ({ control, register }) => {
  const [teamMemberOptions, setTeamMemberOptions] = useState();

  useEffect(() => {
    ApiUtil.get('/organizations/vha/users').then((response) => {
      setTeamMemberOptions(response.body.organization_users.data.map((member) => (
        {
          label: member.attributes.full_name,
          value: member.attributes.css_id
        }
      )));
    });
  }, []);

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
                options={teamMemberOptions}
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
