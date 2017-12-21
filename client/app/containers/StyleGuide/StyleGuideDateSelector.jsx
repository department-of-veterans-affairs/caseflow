import React from 'react';
import DateSelector from '../../components/DateSelector';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideDateSelector extends React.PureComponent {
  constructor(props){
    super(props);

    this.state = {
      dateValue: ''
    };
  }

  onChange = (dateValue) => {
    this.setState({ dateValue })
  }

  render() {
    return <div>
      <StyleGuideComponentTitle
        title="Date Input"
        id="date-input"
        link="StyleGuideDateSelector.jsx"
      />
      <p>
        Date input allows users to click in the input box
        and type in a date quickly and in a format that validates
        each input. Designers and writers are recommented to add an
        example in the correct format above the component (example:
        07/04/1776) so that users have a quick and easy instruction.
      </p>
      <DateSelector
        name="Example: 07/04/1776"
        onChange={this.onChange}
        value={this.state.dateValue}
        errorMessage="Invalid Date"
      />
    </div>;
  }
}
