import React from 'react';
import PropTypes from 'prop-types';
import CaseflowDistributionContent from '../components/CaseflowDistributionContent';

class CaseflowDistributionApp extends React.PureComponent {
  render() {

    return (
      <div>
        <div> {/* Wrapper*/}
          <CaseflowDistributionContent
            levers = {this.props.acd_levers}
            saveChanges = {[]}
            initialHistory={this.props.acd_history}
            leverStore={this.props.leverStore}
            isAdmin = {this.props.user_is_an_acd_admin}
            sectionTitles = {this.props.sectionTitles}
          />
        </div>
      </div>
    );

  }
}

CaseflowDistributionApp.propTypes = {
  acd_levers: PropTypes.array,
  acd_history: PropTypes.array,
  user_is_an_acd_admin: PropTypes.bool,
  leverStore: PropTypes.any,
  sectionTitles: PropTypes.array
};

export default CaseflowDistributionApp;
