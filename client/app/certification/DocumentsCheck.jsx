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


// TODO: refactor to use shared components where helpful
class UnconnectedDocumentsCheck extends React.Component {
  // TODO: updating state in ComponentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  componentWillMount() {
    this.props.updateProgressBar();
    console.log("LOL");
    console.log(this.props.certificationStatus);
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
        <p>Caseflow could not find the documents marked
          with an <NotFoundIcon/> in the appellant's eFolder. This usually happens when
          something doesn't match up. Try checking:</p>
        <ul>The <strong>document type</strong> in VBMS to make sure it's
          <a href="/help#mismatched-documents"> labeled correctly</a></ul>
        <ul>The <strong>document date</strong> — the date in VBMS must match
        the date in VACOLS</ul>
        <p>Once you've made corrections, <a href="">refresh this page.</a></p>
        <p>If you can't find the document, <a href="#"
          onClick={toggleCancellationModal}>cancel this certification.</a></p>
      </div>;

    /*
     * certificationStatus == 'mismatched_documents' or 'started'
     */
    return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Check Documents</h2>

        { documentsMatch ? <DocumentsMatchingBox/> : <DocumentsNotMatchingBox/> }

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

/*
 * Creates a component that's connected to the Redux store
 * using the state & dispatch map functions and the
 * ConfirmHearing function.
 */
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
