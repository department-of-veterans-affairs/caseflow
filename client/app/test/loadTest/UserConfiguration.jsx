/* eslint-disable max-lines, max-len */

import React from 'react';

import SearchableDropdown from '../../components/SearchableDropdown';

const UserConfiguration = () => {
  return (
    <div>
      <p>Station ID</p>
      <SearchableDropdown
        name="Station id dropdown"
        hideLabel
        // onInputChange={handleInputChange}
        // options={slicedUserOptions} searchable
        // onChange={handleUserSelect}
        // Disable native filter
        filterOption={() => true}
        // value={userSelect}
      />
      <br />
      <p>Regional Office</p>
      <SearchableDropdown
        name="Regional office dropdown"
        hideLabel
        // onInputChange={handleInputChange}
        // options={slicedUserOptions} searchable
        // onChange={handleUserSelect}
        // Disable native filter
        filterOption={() => true}
        // value={userSelect}
      />
    </div>
  );
}

export default UserConfiguration;
