import React from 'react';

// components
import RadioField from '../../../components/RadioField';

export default class Example4 extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      errorMessage: "This field is required",
      value: null
    };
  }

  onChange = (event) => {
    this.setState({
      value: event.target.value,
      errorMessage: null
    });
  }

  render = () => {
    return <RadioField
      label="Supplemental statement of the case"
      name="radio_example_4"
      options={[
        { displayText: "Furnished",
          value: "1" },
        { displayText: "Not furnished",
          value: "2" }
      ]}
      value={this.state.value}
      onChange={this.onChange}
      required={true}
      errorMessage={this.state.errorMessage}
    ></RadioField>;
  }
}
