import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example2 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: "1"
    };
  }

  onChange = (event) => {
    this.setState({
      value: event.target.value
    });
  }

  render = () => {
    let options = [
      { displayText: "Yes",
        value: "1" },
      { displayText: "No",
        value: "2" }
    ];

    return <RadioField
      label={<span><strong>Horizontal Radio Button</strong></span>}
      hideLabel={true}
      name="radio_example_2"
      options={options}
      value={this.state.value}
      onChange={this.onChange}
    ></RadioField>;
  }
}
