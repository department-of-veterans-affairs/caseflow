import React from 'react';

// components
import CheckboxGroup from '../../../components/CheckboxGroup';

export default class Example3 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      values: {
        checkboxExample31: false,
        checkboxExample32: false,
        checkboxExample33: false
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
        id: "checkboxExample31",
        label: "Yosemite National Park"
      },
      {
        id: "checkboxExample32",
        label: "Grand Canyon National Park"
      },
      {
        id: "checkboxExample33",
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
