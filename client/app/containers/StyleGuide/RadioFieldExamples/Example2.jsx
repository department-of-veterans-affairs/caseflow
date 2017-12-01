import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example2 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: '1'
    };
  }

  onChange = (value) => {
    this.setState({
      value
    });
  }

  render = () => {
    let options = [
      { displayText: 'Yes',
        value: '1' },
      { displayText: 'No',
        value: '2' }
    ];

    return <RadioField
      label={<h3 id="horizontal_radio">Horizontal Radio Button</h3>}
      name="radio_example_2"
      options={options}
      value={this.state.value}
      onChange={this.onChange}
    />;
  }
}
