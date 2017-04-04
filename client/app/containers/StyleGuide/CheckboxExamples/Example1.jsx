import React from 'react';

// components
import Checkbox from '../../../components/Checkbox';

export default class Example1 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null
    };
  }

  onChange = (event) => {
    this.setState({
      value: event.target.checked
    });
  }

  render = () => {
    return <Checkbox
      label="Check me!"
      vertical={true}
      name="checkbox_example_1"
      onChange={this.onChange}
      value={this.state.value}
    ></Checkbox>;
  }
}
