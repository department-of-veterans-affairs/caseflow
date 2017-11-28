import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example1 extends React.Component {
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
      { displayText: <span>Yosemite National Park</span>,
        value: '1' },
      { displayText: 'Grand Canyon National Park',
        value: '2' },
      { displayText: 'Yellowstone National Park and related services',
        value: '3' }
    ];

    return <RadioField
      label={<h3 id="vertical_radio">Vertical Radio Button</h3>}
      name="radio_example_1"
      options={options}
      value={this.state.value}
      onChange={this.onChange}
    />;
  }
}
