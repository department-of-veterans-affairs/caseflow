/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextField from '../../components/TextField';
import PropTypes from 'prop-types';

export default function ScenarioConfiguration(props) {
  const [isChecked, scenarioIsChecked] = useState(false);

  let scenario = props.scenario;
  let targetType = props.targetType;

  const onChangeHandle = () => {
    scenarioIsChecked(!isChecked);
  };

  return (
    <div className="load-test-container-checkbox test-class-sizing">
      <Checkbox
        label={scenario}
        name={scenario}
        onChange={() => {
          onChangeHandle();
        }}
        value={isChecked}
      />
      {isChecked && targetType.length > 0 &&
        (<div className="load-test-checkbox-hidden-content">
          <SearchableDropdown
            name={`${scenario}-target-type`}
            label="Target Type"
            options={targetType}
            isClearable
          />
          <br />
          <TextField
            name="testTargetID"
            label="Target Type ID"
            optional
          />
        </div>
        )
      }
    </div>
  );
}

ScenarioConfiguration.propTypes = {
  scenario: PropTypes.string,
  targetType: PropTypes.array
};
