import React, { useState } from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../components/SearchableDropdown';
import FeatureToggleConfiguration from './FeatureToggleConfiguration';
import FunctionConfiguration from './FunctionConfiguration';
import OFFICE_INFO from '../../../constants/REGIONAL_OFFICE_FOR_CSS_STATION';
import OrganizationsConfiguration from './OrganizationsConfiguration';
import RoleConfiguration from './RoleConfiguration';

export default function UserConfiguration(props) {
  const [stationSelected, setStationSelected] = useState('');
  const [officeSelected, setOfficeSelected] = useState('');

  const filteredStations = [];
  const stationsMapping = new Map();
  const functionsAvailable = props.form_values.functions_available;
  const roles = props.form_values.all_csum_roles;
  const organizations = props.form_values.all_organizations;
  const featureToggles = props.form_values.feature_toggles_available;
  const currentState = props.currentState;
  const updateState = props.updateState;
  const errors = props.errors;

  const handleStationSelect = ({ value }) => {
    setStationSelected(value);
    setOfficeSelected('');
    updateState(
      {
        ...currentState,
        user: {
          ...currentState.user,
          station_id: value,
          regional_office: ''
        }
      }
    );
  };

  Object.entries(OFFICE_INFO).forEach((info) => {
    if (info[1] !== 'NA') {
      if (info[1] !== Array) {
        info[1] = [info[1]];
      }
      stationsMapping.set(info[0], info[1]);
      filteredStations.push({ value: info[0], label: info[0] });
    }
  });

  const stationAssignedOffices = OFFICE_INFO[stationSelected];

  const officeAvailable = [];
  let officesAvailable;

  if (typeof stationAssignedOffices === 'object') {
    stationAssignedOffices.forEach((station) => {
      officesAvailable = {
        value: station,
        label: station
      };
      officeAvailable.push(officesAvailable);
    });
  } else if (typeof stationAssignedOffices === 'string') {
    officeAvailable.push({ value: stationAssignedOffices, label: stationAssignedOffices });
  }

  const handleOfficeSelect = ({ value }) => {
    setOfficeSelected(value);
    props.updateState(
      {
        ...currentState,
        user: {
          ...currentState.user,
          regional_office: value
        }
      }
    );
  };

  featureToggles.sort();

  return (
    <div>
      <h3><strong>Station ID</strong></h3>
      <SearchableDropdown
        name="Station id dropdown"
        hideLabel
        options={filteredStations} searchable
        onChange={(newVal) => {
          handleStationSelect(newVal);
        }}
        filterOption={() => true}
        value={stationSelected}
      />
      {errors.station_id && <div className="error">{errors.station_id}</div>}
      <br />
      <h3><strong>Regional Office</strong></h3>
      <SearchableDropdown
        name="Regional office dropdown"
        hideLabel
        options={officeAvailable} searchable
        onChange={(newVal) => {
          handleOfficeSelect(newVal);
        }}
        filterOption={() => true}
        value={officeSelected}
      />
      {errors.regional_office && <div className="error">{errors.regional_office}</div>}
      <br />
      <h3 className="header-style"><strong>Organizations</strong></h3>
      <div className="load-test-container">
        {organizations.map((organization) => (
          <OrganizationsConfiguration
            key={organization}
            currentState={currentState}
            updateState={props.updateState}
            org={organization}
          />
        ))}
      </div>
      <br />
      <h3 className="header-style"><strong>Functions</strong></h3>
      <div className="load-test-container test-class-sizing">
        {functionsAvailable.map((functionOption) => (
          <FunctionConfiguration
            key={functionOption}
            functionOption={functionOption}
            currentState={currentState}
            updateState={props.updateState}
          />
        ))}
      </div>
      <br />
      <h3 className="header-style"><strong>Roles</strong></h3>
      <div className="load-test-container test-class-sizing">
        {roles.map((role) => (
          <RoleConfiguration
            key={role}
            role={role}
            currentState={currentState}
            updateState={props.updateState}
          />
        ))}
      </div>
      <br />
      <h3 className="header-style"><strong>Feature Toggles</strong></h3>
      <div className="load-test-container test-class-sizing">
        {featureToggles.map((featureToggle) => (
          <FeatureToggleConfiguration
            key={featureToggle.name}
            featureToggle={featureToggle}
            currentState={currentState}
            updateState={props.updateState}
          />
        ))}
      </div>
    </div>
  );
}

UserConfiguration.propTypes = {
  all_organizations: PropTypes.array,
  featuresList: PropTypes.array,
  form_values: PropTypes.object,
  functions_available: PropTypes.array,
  register: PropTypes.func,
  currentState: PropTypes.object,
  updateState: PropTypes.func,
  errors: PropTypes.object
};
