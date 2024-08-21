/* eslint-disable max-lines, max-len */

import React from 'react';

import SearchableDropdown from '../../components/SearchableDropdown';
import OFFICE_INFO from '../../../constants/REGIONAL_OFFICE_FOR_CSS_STATION.json';

export default function UserConfiguration() {

  // console.log(OFFICE_INFO);

  // const filteredStations = () => {
  //   const allStations = OFFICE_INFO;

  //   const stationsWithOffices = allStations.map((station, office) => {
  //     // if (office === 'NA') {
  //     //   allStations.delete(station);
  //     // }

  //     return station;
  //   });

  //   return stationsWithOffices;
  // };

  // console.log(filteredStations);

  return (
    <div>
      <p>Station ID</p>
      <SearchableDropdown
        name="Station id dropdown"
        hideLabel
        // onInputChange={handleInputChange}
        // options={OFFICE_INFO.keys} searchable
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
        // filterOption={() => true}
        // value={userSelect}
      />
    </div>
  );
}
