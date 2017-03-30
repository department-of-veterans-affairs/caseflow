import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example4 extends React.Component {
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
      label="Three or more options are automatically vertical:"
      name="radio_example_4"
      options={[
        { displayText: "One",
          value: "1" },
        { displayText: "Two",
          value: "2" },
        { displayText: "Three",
          value: "3" }
      ]}
      value={this.state.value}
      onChange={this.onChange}
    ></RadioField>;
  }
}
