import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example3 extends React.Component {
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
      label="Forced Vertical Layout"
      hideLabel={true}
      name="radio_example_3"
      options={[
        { displayText: "One",
          value: "1" },
        { displayText: "Two",
          value: "2" }
      ]}
      vertical={true}
      value={this.state.value}
      onChange={this.onChange}
    ></RadioField>;
  }
}
