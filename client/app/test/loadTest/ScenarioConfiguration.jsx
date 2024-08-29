/* eslint-disable max-lines, max-len */

import React from 'react';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import LOAD_TEST_SCENARIOS from '../../constants/LoadTestScenarios.json';

export default class ScenarioConfiguration extends React.Component {
  constructor(props) {
    super(props);

    this.state = {}

    { LOAD_TEST_SCENARIOS.map((scenario_group) => {
      console.log(scenario_group);
      this.state[[scenario_group["scenario"]]] = false;

      console.log("load props");
      console.log(this.state);
      })
    };


  }

  onChange = (scenario, value) => {
    console.log(this.state);
    console.log("beforestate");
    if(this.state[scenario] != value){
      console.log("changes");
      this.setState({[scenario]: value});
    }
    console.log(scenario);
    console.log(this.state);
  }

  retrieveValue = (scenario) => {
    console.log("retrieveValue");
    return this.state[scenario];
  }

  render = () => {
    return (
      <div>
        { LOAD_TEST_SCENARIOS.map((scenario_group) => {
            return (
              <div key={scenario_group["scenario"]}>
                <Checkbox
                label={scenario_group["scenario"]}
                name={scenario_group["scenario"]}
                onClick={this.onChange(scenario_group["scenario"])}
                value={this.retrieveValue(scenario_group["scenario"])}
                />
              </div>
            );
          })
        }
      </div>
    );
  }
}
