import React from 'react';

// components
import RadioField from '../../components/RadioField';

export default class StyleGuideRadioField extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      selectedValue: null
    };
  }

  onChange = (value) => {
    this.setState({
      selectedValue: value
    });
  }

  render = () => {

    let ShowChange = () => {
      return <em>
        You checked option with value
        <strong>{this.state.selectedValue}</strong>
      </em>;
    };

    return <div>
      <h2 id="radios">Radio Buttons</h2>
      <RadioField
        label="Here's one:"
        name="radio_example_1"
        options={[
          { displayText: "One",
            value: "1" }
        ]}
      ></RadioField>
      <RadioField
        label="Here's one with an option initially checked:"
        name="radio_example_2"
        options={[
          { displayText: "One",
            value: "1" },
          { displayText: "Two",
            value: "2" }
        ]}
        value="2"
      ></RadioField>
      <p>The component will automatically render two or less options
        horizontally unless its "vertical" property is set to true:</p>
      <RadioField
        label="Two options in forced vertical display:"
        name="radio_example_3"
        options={[
          { displayText: "One",
            value: "1" },
          { displayText: "Two",
            value: "2" }
        ]}
        value="2"
        vertical={true}
      ></RadioField>
      <RadioField
        label="Three or more options are automatically vertical:"
        name="radio_example_4"
        options={[
          { displayText: "One",
            value: "1" },
          { displayText: "Two",
            value: "2" },
          { displayText: "Three",
            value: "3" }
        ]}
        value="2"
      ></RadioField>
      <RadioField
        label="Here's a required field:"
        name="radio_example_5"
        options={[
          { displayText: "One",
            value: "1" },
          { displayText: "Two",
            value: "2" }
        ]}
        required={true}
      ></RadioField>
      <div className="show-change">
        <RadioField
          label="This field handles a value change:"
          name="radio_example_6"
          options={[
            { displayText: "One",
              value: "1" },
            { displayText: "Two",
              value: "2" }
          ]}
          onChange={this.onChange}
        ></RadioField>{ this.state.selectedValue && <ShowChange /> }
      </div>
      <p>This field hides its label:</p>
      <RadioField
        label="This label is hidden:"
        name="radio_example_5"
        options={[
          { displayText: "One",
            value: "1" },
          { displayText: "Two",
            value: "2" }
        ]}
        required={true}
        hideLabel={true}
      ></RadioField>
    </div>;
  }
}
