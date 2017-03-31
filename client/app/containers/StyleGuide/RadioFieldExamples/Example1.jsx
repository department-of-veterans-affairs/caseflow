import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example1 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null
    };
  }

  onChange = (event) => {
    this.setState({
      value: event.target.value
    });
  }

  render = () => {
    return <RadioField
      label="Here's one:"
      name="radio_example_1"
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
