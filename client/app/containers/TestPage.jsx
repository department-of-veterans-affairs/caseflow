import React from 'react';

import DateSelector from '../../app/components/DateSelector';

export default class TestPage extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      testDate: ''
    };
  }

  render() {
    return <div className="sub-page">
      Test Page
      <a onClick={() => {
        this.props.handleAlert('error', 'test', 'bar');
      }} className="handleAlert"/>
      <a onClick={() => {
        this.props.handleAlertClear();
      }} className="handleAlertClear"/>
      <DateSelector
        label="Test Date"
        name="testDate"
        onChange={(event) => {
          this.setState({ testDate: event.target.value });
        }}
        required={true}
        value={this.state.testDate}
      />
    </div>;
  }
}
