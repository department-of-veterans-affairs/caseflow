import React from 'react';

// components
import CheckboxGroup from '../../../components/CheckboxGroup';

export default class Example6 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      values: {
        checkbox_example_6_1: false,
        checkbox_example_6_2: false,
        checkbox_example_6_3: false
      },
      errorMessage: "You must choose an option"
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
        id: "checkbox_example_6_1",
        label: "Check me!"
      },
      {
        id: "checkbox_example_6_2",
        label: "No, check me!"
      }
    ];


    return <CheckboxGroup
      label="You must check an option:"
      name="checkbox_example_6"
      options={options}
      onChange={this.onChange}
      values={this.state.values}
      required={true}
      errorMessage={this.state.errorMessage}
    ></CheckboxGroup>;
  }
}
