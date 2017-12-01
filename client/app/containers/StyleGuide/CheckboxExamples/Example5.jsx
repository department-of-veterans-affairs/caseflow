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
        id: 'checkboxExample51',
        label: 'Option 1'
      },
      {
        id: 'checkboxExample52',
        label: 'Option 2'
      }
    ];

    return <CheckboxGroup
      label={<h3>Forced Vertical Checkboxes</h3>}
      name="checkbox_example_5"
      options={options}
      onChange={this.onChange}
      values={this.state.values}
      vertical={true}
    ></CheckboxGroup>;
  }
}
