import React from 'react';
import PropTypes from 'prop-types';

import CaseflowDistributionContent from './pages/CaseflowDistributionApp';

class CaseflowDistribution extends React.PureComponent {
  render() {
    console.log("this.props:", this.props)
    const {acd_levers, acd_history} = this.props
    return (
      <div>
        <h1>Hello world from CaseflowDistribution index</h1>
        <h2>Levers</h2>
        <div>{JSON.stringify(acd_levers)}</div>
        <div>{JSON.stringify(acd_history)}</div>
        <div>{JSON.stringify(acd_history)}</div>
      </div>
    )
  }
}

CaseflowDistribution.propTypes = {
  acd_levers: PropTypes.array,
  acd_history: PropTypes.array,
  user_is_an_acd_admin: PropTypes.bool
}

export default CaseflowDistribution;
