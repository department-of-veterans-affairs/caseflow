import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example1 extends React.Component {
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
    return <RadioField
      label="Vertical Radio Button"
      hideLabel={true}
      name="radio_example_1"
      options={[
        { displayText: <span>Yosemite National Park</span>,
          value: "1" },
        { displayText: "Grand Canyon National Park",
          value: "2" },
        { displayText: "Yellowstone National Park and related services",
          value: "3" }
      ]}
      value={this.state.value}
      onChange={this.onChange}
    ></RadioField>;
  }
}
