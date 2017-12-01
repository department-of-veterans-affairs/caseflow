import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import ProgressBar from '../components/ProgressBar';
import { progressBarSections } from './constants/constants';


// TODO: use the redux store to grab data and render this.
export class CertificationProgressBar extends React.Component {
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
        title: '4. Sign and Certify',
        value: progressBarSections.SIGN_AND_CERTIFY
      }
    ];
  }

  deriveSections() {
    const currentSection = this.props.currentSection;

    return CertificationProgressBar.sections().map((section) => {
      return {
        title: section.title,
        current: section.value === currentSection
      };
    });
  }

  render() {

    let showProgressBar = !this.props.serverError;

    return <div>
      { showProgressBar && <ProgressBar sections={this.deriveSections()}/> }
      </div>;
  }
}

const mapStateToProps = (state) => ({
  currentSection: state.currentSection,
  serverError: state.serverError
});

export default connect(
  mapStateToProps
)(CertificationProgressBar);

CertificationProgressBar.propTypes = {
  currentSection: PropTypes.string
};
