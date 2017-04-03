import React from 'react';

// components
import CheckboxGroup from '../../../components/CheckboxGroup';

export default class Example3 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      values: {
        checkbox_example_3_1: false,
        checkbox_example_3_2: false,
        checkbox_example_3_3: false
      }
    };
  }

  onChange = (event) => {
    let state = this.state;

    state.values[event.target.getAttribute('id')] = event.target.checked;

    this.setState(state);
  }

  render = () => {
    let options = [
      {
        id: "checkbox_example_3_1",
        label: "Check me!"
      },
      {
        id: "checkbox_example_3_2",
        label: "No me!"
      },
      {
        id: "checkbox_example_3_3",
        label: "Disabled",
        disabled: true
      }
    ];

    return <CheckboxGroup
      label="Vertical Checkboxes:"
      name="checkbox_example_3"
      options={options}
      onChange={this.onChange}
      values={this.state.values}
      hideLabel={true}
    ></CheckboxGroup>;
  }
}
