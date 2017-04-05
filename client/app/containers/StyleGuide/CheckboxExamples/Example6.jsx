import React from 'react';

// components
import CheckboxGroup from '../../../components/CheckboxGroup';

export default class Example6 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      values: {
        checkboxExample61: false,
        checkboxExample62: false
      },
      errorMessage: "You must choose an option"
    };
  }

  onChange = (event) => {
    let state = this.state;

    state.values[event.target.getAttribute('id')] = event.target.checked;
    state.errorMessage = null;

    this.setState(state);
  }

  render = () => {
    let options = [
      {
        id: "checkboxExample61",
        label: "Option 1"
      },
      {
        id: "checkboxExample62",
        label: "Option 2"
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
