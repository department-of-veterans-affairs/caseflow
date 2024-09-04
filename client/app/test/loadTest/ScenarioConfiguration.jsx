/* eslint-disable max-lines, max-len */

import React, {useState} from 'react';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import TextField from '../../components/TextField';
import LOAD_TEST_SCENARIOS from '../../constants/LoadTestScenarios.json';

export default function ScenarioConfiguration(props){
  const [isChecked, scenarioIsChecked] = useState(false);

  console.log('config');
  console.log(props);
  let scenario = props.scenario;
  let targetType = props.targetType;

  console.log(isChecked);
  console.log(targetType);

  const onChangeHandle = () => {
    scenarioIsChecked(!isChecked);
  }

  console.log(scenario);
  console.log(targetType);
  console.log(targetType.length);
  console.log("checked");


  return (
    <div>
      <Checkbox
      label={scenario}
      name={scenario}
      onChange={() => {onChangeHandle()}}
      value={isChecked || false}
      />
      {isChecked && targetType.length > 0 &&
        (<div>
          <SearchableDropdown
          label="Target Type"
          options={targetType}
          isClearable
          />
          <br/>
          <TextField
          name="testTargetID"
          label="Target Type ID"
          optional={true}
        />
        </div>
      )}
    </div>
  );
}
