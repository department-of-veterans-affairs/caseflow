/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextField from '../../components/TextField';
import PropTypes from 'prop-types';

export default function ScenarioConfiguration(props) {
  const [isChecked, scenarioIsChecked] = useState(false);
  const [inputValue, setInputValue] = useState('');

  let scenario = props.scenario;
  let targetType = props.targetType;
  const currentState = props.currentState;
  const updateState = props.updateState;

  // scenarios:{
  //   "appealVeteranTest": {
  //   "targetType": "LegacyAppeal",
  //   "targetId": "3436456"
  //   }
  // 1. ask a question in regards to the keys of the scenarios key names and how to get them
  // to match. My hypothesis, we'll have to update the exampleSetup.JSON file
  const onChangeHandle = () => {
    scenarioIsChecked(!isChecked);
    updateState(
      {
        ...currentState,
        scenarios: [
          ...currentState.scenarios,
          {
            [scenario + 'Test']: {
              targetType: targetType,
              targetId: inputValue
            }
          }
        ]
      }
    );
  };

  return (
    <div className="load-test-container-checkbox test-class-sizing">
      <Checkbox
        label={scenario}
        name={scenario}
        onChange={(value) => {
          onChangeHandle(value);
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
            onChange={(value) => setInputValue(value)}
            optional
          />
        </div>
        )
      }
    </div>
  );
}

/* TODO:
  1.implement update for the text field in order to gain a tangible value to set in state.
    a.update state in text field.[created state for the value, but it isnt working.]
  2.currently targetType is an array of options to be selected. again, I need the value to be able to update state.
  3.will also need to consider a way to delete a state entry is the checkbox is unchecked.
*/

ScenarioConfiguration.propTypes = {
  scenario: PropTypes.string,
  targetType: PropTypes.array,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};
