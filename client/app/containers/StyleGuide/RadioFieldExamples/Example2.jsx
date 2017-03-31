import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example2 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: "2"
    };
  }

  onChange = (event) => {
    this.setState({
      value: event.target.value
    });
  }

  render = () => {
    return <RadioField
      label="Here's one with an option initially checked:"
      name="radio_example_2"
      options={[
        { displayText: "One",
          value: "1" },
        { displayText: "Two",
          value: "2" }
      ]}
      value={this.state.value}
      onChange={this.onChange}
    ></RadioField>;
  }
}
