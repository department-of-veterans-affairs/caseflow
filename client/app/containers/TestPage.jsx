import React from 'react';

export default class TestPage extends React.Component {
  render() {
    return(<div className="sub-page">
      Test Page
      <a onClick={() => { this.props.handleAlert('error', 'test', 'bar') }} className="handleAlert"/>
      <a onClick={() => { this.props.handleAlertClear()}} className="handleAlertClear"/>
    </div>);
  }
}
