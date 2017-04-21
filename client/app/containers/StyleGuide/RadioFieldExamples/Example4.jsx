import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example4 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      value: null,
      errorMessage: "This field is required"
    };
  }

  onChange = (event) => {
    this.setState({
      value: event.target.value,
      errorMessage: null
    });
  }

  render = () => {
    let options = [
      { displayText: "Furnished",
        value: "1" },
      { displayText: "Not furnished",
        value: "2" }
    ];

    return <RadioField
      label="Supplemental statement of the case"
      name="radio_example_4"
      options={options}
      value={this.state.value}
      onChange={this.onChange}
      required={true}
      errorMessage={this.state.errorMessage}
    ></RadioField>;
  }
}
