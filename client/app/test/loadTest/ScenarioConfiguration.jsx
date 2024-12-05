<<<<<<< HEAD
/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';

=======
import React, { useState } from 'react';
>>>>>>> feature/APPEALS-59217
import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextField from '../../components/TextField';
import PropTypes from 'prop-types';
<<<<<<< HEAD

export default function ScenarioConfiguration(props) {
  const [isChecked, scenarioIsChecked] = useState(false);

  let scenario = props.scenario;
  let targetType = props.targetType;

  const onChangeHandle = () => {
    scenarioIsChecked(!isChecked);
=======
export default function ScenarioConfiguration(props) {
  const [checked, setChecked] = useState(false);
  const [targetId, setTargetId] = useState('');

  const scenario = props.scenario;
  const targetType = props.targetType;
  const currentState = props.currentState;
  const updateState = props.updateState;
  const currentScenarios = currentState.scenarios;
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
    if (scenariosArray.find((selection) => selection === chosenScenario)) {
      currentScenarios.splice(scenariosArray.indexOf(chosenScenario), 1);
      setChecked(false);
    } else {
      currentScenarios.push({ [chosenScenario]: {} });
      setChecked(true);
    }

    updateState(
      {
        ...currentState,
        scenarios: currentScenarios
      }
    );
  };

  const handleTargetSelect = (chosenTarget, associatedScenario) => {
    if (chosenTarget === null) {
      currentScenarios[scenariosArray.indexOf(associatedScenario)] = { [associatedScenario]: {} };
    } else {
      currentScenarios[scenariosArray.indexOf(associatedScenario)] = {
        [associatedScenario]: { targetType: chosenTarget, targetId: '' }
      };
    }

    updateState(
      {
        ...currentState,
        scenarios: currentScenarios
      }
    );
  };

  const handleTargetIdSelect = (value) => {
    setTargetId(value);

    currentScenarios[scenariosArray.indexOf(scenario)][scenario].targetId = value;

    updateState(
      {
        ...currentState,
        scenarios: currentScenarios
      }
    );
>>>>>>> feature/APPEALS-59217
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
