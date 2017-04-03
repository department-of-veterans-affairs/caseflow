import React from 'react';

// components
import CheckboxGroup from '../../../components/CheckboxGroup';

export default class Example4 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      values: {
        checkboxExample41: false,
        checkboxExample42: true
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
        id: "checkboxExample41",
        label: "Check me!"
      },
      {
        id: "checkboxExample42",
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
