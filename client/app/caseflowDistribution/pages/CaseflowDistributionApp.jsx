import React from 'react';
import PropTypes from 'prop-types';

class CaseflowDistributionContent extends React.PureComponent {
  render() {
    <div className="cf-app-segment cf-app-segment--alt">
      <div> {/*Wrapper*/}
        <h1>Hello World From CaseflowDistributionContent</h1>
        {this.props.acd_levers.map((lever) => {
          <div>{lever.item}</div>
        })}
      </div>
    </div>

  }
}

CaseflowDistributionContent.propTypes = {
  acd_levers: PropTypes.array,
  acd_history: PropTypes.array,
  user_is_an_acd_admin: PropTypes.bool
};

export default CaseflowDistributionContent;
