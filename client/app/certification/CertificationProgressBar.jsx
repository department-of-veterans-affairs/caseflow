import React from 'react';
import { connect } from 'react-redux';
import ProgressBar from '../components/ProgressBar';
import { progressBarSections } from './constants/constants';


// TODO: use the redux store to grab data and render this.
class UnconnectedCertificationProgressBar extends React.Component {
  static sections() {
    return [
      {
        title: '1. Check Documents',
        value: progressBarSections.CHECK_DOCUMENTS
      },
      {
        title: '2. Confirm Case Details',
        value: progressBarSections.CONFIRM_CASE_DETAILS
      },
      {
        title: '3. Confirm Hearing',
        value: progressBarSections.CONFIRM_HEARING
      },
      {
        title: '4. Confirmation',
        value: progressBarSections.CONFIRMATION
      }
    ];
  }

  deriveSections() {
    const currentSection = this.props.currentSection;

    return UnconnectedCertificationProgressBar.sections().map((section) => {
      return {
        title: section.title,
        current: section.value === currentSection
      };
    });
  }

  render() {
    return <ProgressBar sections={this.deriveSections()}/>;
  }
}

const mapStateToProps = (state) => {
  return {
    currentSection: state.currentSection
  };
};

const CertificationProgressBar = connect(
  mapStateToProps
)(UnconnectedCertificationProgressBar);

export default CertificationProgressBar;
