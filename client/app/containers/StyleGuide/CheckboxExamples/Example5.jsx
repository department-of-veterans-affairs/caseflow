import React from 'react';

// components
import CheckboxGroup from '../../../components/CheckboxGroup';

export default class Example5 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      values: {
        checkboxExample51: false,
        checkboxExample52: true
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
        id: "checkboxExample51",
        label: "Check me!"
      },
      {
        id: "checkboxExample52",
        label: "No me!"
      }
    ];

    return <CheckboxGroup
      label="Horizontal checkboxes forced vertically:"
      name="checkbox_example_5"
      options={options}
      onChange={this.onChange}
      values={this.state.values}
      hideLabel={true}
      vertical={true}
    ></CheckboxGroup>;
  }
}
