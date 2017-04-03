import React from 'react';

// components
import CheckboxGroup from '../../../components/CheckboxGroup';

export default class Example4 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      values: {
        checkbox_example_4_1: false,
        checkbox_example_4_2: true
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
        id: "checkbox_example_4_1",
        label: "Check me!"
      },
      {
        id: "checkbox_example_4_2",
        label: "No me!"
      }
    ];

    return <CheckboxGroup
      label="Horizontal Checkboxes:"
      name="checkbox_example_4"
      options={options}
      onChange={this.onChange}
      values={this.state.values}
      hideLabel={true}
    ></CheckboxGroup>;
  }
}
