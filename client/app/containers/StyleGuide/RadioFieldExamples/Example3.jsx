import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example3 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: '2'
    };
  }

  onChange = (value) => {
    this.setState({
      value
    });
  }

  render = () => {
    let options = [
      { displayText: 'One',
        value: '1' },
      { displayText: 'Two',
        value: '2' }
    ];

    return <RadioField
      label={<h3>Horizontal Radio Button Forced Into Vertical Layout</h3>}
      name="radio_example_3"
      options={options}
      vertical={true}
      value={this.state.value}
      onChange={this.onChange}
    ></RadioField>;
  }
}
