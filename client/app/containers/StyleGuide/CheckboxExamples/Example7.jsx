import React from 'react';

// components
import Checkbox from '../../../components/Checkbox';

export default class Example7 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null,
      errorMessage: "You must acknowledge this."
    };
  }

  onChange = (value) => {
    this.setState({
      value,
      errorMessage: null
    });
  }

  render = () => {
    let acknowledgement = "I acknowldge that this information is correct. " +
      "I agree to follow the rules.";

    return <Checkbox
      label={acknowledgement}
      name="checkbox_example_7"
      onChange={this.onChange}
      value={this.state.value}
      errorMessage={this.state.errorMessage}
    ></Checkbox>;
  }
}
