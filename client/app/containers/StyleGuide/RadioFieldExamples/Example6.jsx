import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example6 extends React.Component {
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
      label="This label is hidden:"
      name="radio_example_7"
      options={[
        { displayText: "One",
          value: "1" },
        { displayText: "Two",
          value: "2" }
      ]}
      required={true}
      value={this.state.value}
      onChange={this.onChange}
      hideLabel={true}
    ></RadioField>;
  }
}
