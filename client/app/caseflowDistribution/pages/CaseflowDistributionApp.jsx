import React from 'react';
import PropTypes from 'prop-types';
import CaseflowDistributionContent from '../components/CaseflowDistributionContent';

class CaseflowDistributionApp extends React.PureComponent {
  render() {

    return (
      <div className="cf-app-segment cf-app-segment--alt">
        <div> {/* Wrapper*/}
          <h1>Hello World From CaseflowDistributionContent</h1>
          { console.log('this.props Caseflow Distribution App:', this.props)}
          <CaseflowDistributionContent
            levers = {this.props.acd_levers}
            saveChanges = {[]}
            formattedHistory={this.props.acd_history}
            leverStore={this.props.leverStore}
            isAdmin = {this.props.user_is_an_acd_admin}
          />
        </div>
      </div>
    );

  }
}

CaseflowDistributionApp.propTypes = {
  acd_levers: PropTypes.array,
  acd_history: PropTypes.array,
  user_is_an_acd_admin: PropTypes.bool
};

export default CaseflowDistributionApp;
