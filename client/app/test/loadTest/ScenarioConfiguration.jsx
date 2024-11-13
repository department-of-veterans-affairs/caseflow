/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextField from '../../components/TextField';
import PropTypes from 'prop-types';
export default function ScenarioConfiguration(props) {
  const [checked, setChecked] = useState(false);

  const scenario = props.scenario;
  const targetType = props.targetType;
  const currentState = props.currentState;
  const updateState = props.updateState;
  const scenariosArray = currentState.scenarios.map((selection) =>
    Object.keys(selection)[0]
  );
  const nullCheck = (target) => {
    if (target === null) {
      return null;
    }

    return target.value;
  };

  const handleScenarioSelect = (chosenScenario) => {
    const currentSelections = currentState.scenarios;
    let updatedSelections = currentState.scenarios.map((selection) =>
      Object.keys(selection)[0]
    );

    if (updatedSelections.find((selection) => selection === chosenScenario)) {
      currentSelections.splice(updatedSelections.indexOf(chosenScenario), 1);
      setChecked(false);
    } else {
      currentSelections.push({ [chosenScenario]: {} });
      setChecked(true);
    }

    updateState(
      {
        ...currentState,
        scenarios: currentSelections
      }
    );
  };

  const handleTargetSelect = (chosenTarget, associatedScenario) => {
    let currentScenarios = currentState.scenarios;

    if (chosenTarget === null) {
      currentScenarios[scenariosArray.indexOf(associatedScenario)] = { [associatedScenario]: {} };
    } else {
      currentScenarios[scenariosArray.indexOf(associatedScenario)] = { [associatedScenario]: { targetType: chosenTarget } };
    }

    updateState(
      {
        ...currentState,
        scenarios: currentScenarios
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
            onChange={(event) => handleTargetSelect(nullCheck(event), scenario)}
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
