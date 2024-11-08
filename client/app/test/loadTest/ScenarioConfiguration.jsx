/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextField from '../../components/TextField';
import PropTypes from 'prop-types';
// import { current } from '@reduxjs/toolkit';

export default function ScenarioConfiguration(props) {
  const [checked, setChecked] = useState(false);

  const scenario = props.scenario;
  const targetType = props.targetType;
  const currentState = props.currentState;
  const updateState = props.updateState;

  const handleScenarioSelect = (chosenScenario) => {
    let updatedSelections = currentState.scenarios;

    if (updatedSelections.find((selection) => selection === chosenScenario)) {
      updatedSelections.splice(updatedSelections.indexOf(chosenScenario), 1);
      setChecked(false);
    } else {
      updatedSelections.push(chosenScenario);
      setChecked(true);
    }

    updateState(
      {
        ...currentState,
        scenarios: updatedSelections
      }
    );
  };

  return (
    <div className="load-test-container-checkbox test-class-sizing">
      <Checkbox
        label={scenario}
        name={scenario}
        onChange={() => handleScenarioSelect(scenario)}
        isChecked={checked}
      />
      {checked && targetType.length > 0 &&
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
  targetType: PropTypes.array,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};
