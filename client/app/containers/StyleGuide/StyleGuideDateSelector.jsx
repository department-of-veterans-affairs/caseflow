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
      <DateSelector
        name="Example: 07/04/1776"
        onChange={this.onChange}
        value={this.state.dateValue}
        errorMessage="Invalid Date"
      />
    </div>;
  }
}
