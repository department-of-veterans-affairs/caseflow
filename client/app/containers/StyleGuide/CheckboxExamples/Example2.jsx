import React from 'react';

// components
import Checkbox from '../../../components/Checkbox';

export default class Example2 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: true
    };
  }

  onChange = (event) => {
    this.setState({
      value: event.target.checked
    });
  }

  render = () => {
    return <Checkbox
      label="Option"
      vertical={true}
      name="checkbox_example_2"
      onChange={this.onChange}
      value={this.state.value}
    ></Checkbox>;
  }
}
