import React from 'react';
import PropTypes from 'prop-types';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import NotReady from './NotReady';
import AlreadyCertified from './AlreadyCertified';
import { connect } from 'react-redux';
import Footer from './Footer';
import * as Constants from './constants/constants';
import NotFoundIcon from '../components/NotFoundIcon';
import * as certificationActions from './actions/Certification';

class UnconnectedDocumentsCheck extends React.Component {
  // TODO: updating state in ComponentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  componentWillMount() {
    this.props.updateProgressBar();
  }

  areDatesExactlyMatching() {
    if (this.props.ssocs && this.props.ssocs.length) {
      return this.props.soc.isExactlyMatching &&
      this.props.ssocs.reduce((total, ssoc) => total && ssoc.isExactlyMatching);
    }

    return this.props.soc.isExactlyMatching;
  }

  render() {
    let {
      certificationStatus,
      nod,
      soc,
      form9,
      ssocs,
      documentsMatch,
      match,
      toggleCancellationModal
    } = this.props;

    let reloadPage = () => {
      window.location.reload();
    };

    if (certificationStatus === 'data_missing') {
      return <NotReady/>;
    }

    if (certificationStatus === 'already_certified') {
      return <AlreadyCertified/>;
    }

    const missingInformation =
      <div>
        <p>If the document status is marked
          with an <NotFoundIcon/>, try checking:</p>
        <ul>The <strong>document type</strong> in VBMS to make sure it's
          <a href="/certification/help#mismatched-documents"> labeled correctly.</a></ul>
        <ul>The <strong>document date</strong> in VBMS. NOD and Form 9 dates must match their VACOLS dates.
        SOC and SSOC dates are considered matching if the VBMS date is the same as the VACOLS date,
        or if the VBMS date is 4 days or fewer before the VACOLS date.
        <a href="/certification/help#cannot-find-documents"> Learn more about document dates.</a> </ul>
        <p>Once you've made corrections,
        <a href={`/certifications/${match.params.vacols_id}/check_documents`}>refresh this page.</a></p>
        <p>If you can't find the document, <a href="#"
          onClick={toggleCancellationModal}>cancel this certification.</a></p>
      </div>;

    /*
     * certificationStatus == 'mismatched_documents' or 'started'
     */
    return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Check Documents</h2>
        { documentsMatch ? <DocumentsMatchingBox areDatesExactlyMatching={this.areDatesExactlyMatching()}/> :
        <DocumentsNotMatchingBox/> }

        <DocumentsCheckTable nod={nod} soc={soc} form9={form9} ssocs={ssocs}/>

        { !documentsMatch && missingInformation }
      </div>

      <Footer
        buttonText={ documentsMatch ? 'Continue' : 'Refresh page' }
        nextPageUrl={ documentsMatch ?
          `/certifications/${match.params.vacols_id}/confirm_case_details` :
          ''
        }
        onClickContinue={ documentsMatch ? null : reloadPage }/>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  certificationStatus: state.certificationStatus,
  form9: state.form9,
  nod: state.nod,
  soc: state.soc,
  ssocs: state.ssocs,
  documentsMatch: state.documentsMatch
});

const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => {
    dispatch({
      type: Constants.UPDATE_PROGRESS_BAR,
      payload: {
        currentSection: Constants.progressBarSections.CHECK_DOCUMENTS
      }
    });
  },

  toggleCancellationModal: () => {
    dispatch(certificationActions.toggleCancellationModal());
  }
});

const DocumentsCheck = connect(
  mapStateToProps,
  mapDispatchToProps
)(UnconnectedDocumentsCheck);

DocumentsCheck.propTypes = {
  certificationStatus: PropTypes.string,
  nod: PropTypes.object,
  soc: PropTypes.object,
  form9: PropTypes.object,
  ssocs: PropTypes.arrayOf(PropTypes.object),
  documentsMatch: PropTypes.bool,
  match: PropTypes.object
};

export default DocumentsCheck;
