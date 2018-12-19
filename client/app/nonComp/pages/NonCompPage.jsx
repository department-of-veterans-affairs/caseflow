import React from 'react';
import { connect } from 'react-redux';
import NonCompTabs from '../components/NonCompTabs.jsx';

class NonCompPageUnconnected extends React.PureComponent {
  render = () => {
    return <div>
      <h1>{this.props.businessLine}</h1>
      <h2>Reviews needing action</h2>
      <p>Review each issue and select a disposition</p>
      <NonCompTabs/>
    </div>;
  }
}


const NonCompPage = connect(
  (state) => ({
    businessLine: state.businessLine
  })
)(NonCompPageUnconnected);


export default NonCompPage;
