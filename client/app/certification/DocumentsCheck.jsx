import React, { PropTypes } from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import NotReady from './NotReady';
import AlreadyCertified from './AlreadyCertified';
import { connect } from 'react-redux';
import Footer from './Footer';
import * as Constants from './constants/constants';

// TODO: refactor to use shared components where helpful
class UnconnectedDocumentsCheck extends React.Component {
  // TODO: updating state in ComponentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  componentWillMount() {
    this.props.updateProgressBar();
  }

  /*
   * This function acts as a router for the page. Statuses 'started' and
   * 'mismatched_documents' go to 'check_documents'. Status 'already_certified'
   * goes to 'already_certified'. Status 'data_missing' goes to 'not_ready'. Any
   * unrecognized statuses also to go 'not_ready', but will throw a warning in the
   * console.
   */
  documentCheckPage() {
    if (["started", "mismatched_documents"].includes(this.props.certificationStatus)) {
      return "check_documents";
    } else if (this.props.certificationStatus === "already_certified") {
      return "already_certified";
    }
    if (this.props.certificationStatus !== "data_missing") {
      console.warn('Unknown certification status');
    }

    return "not_ready";
  }

  render() {

    let { form9Match,
      form9Date,
      nodMatch,
      nodDate,
      socMatch,
      socDate,
      ssocDatesWithMatches,
      documentsMatch,
      match,
      certificationId
    } = this.props;

    return <div>
      { this.documentCheckPage() === "not_ready" && <NotReady/> }
      { this.documentCheckPage() === "already_certified" && <AlreadyCertified/>}
      { this.documentCheckPage() === "check_documents" && <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Check Documents</h2>
        { documentsMatch ? <DocumentsMatchingBox/> : <DocumentsNotMatchingBox/> }
        <DocumentsCheckTable form9Match={form9Match}
          form9Date={form9Date}
          nodMatch={nodMatch}
          nodDate={nodDate}
          socMatch={socMatch}
          socDate={socDate}
          ssocDatesWithMatches={ssocDatesWithMatches}
          documentsMatch={documentsMatch}/>
      </div>

      <div className="cf-app-segment">
        <Footer
          nextPageUrl={
            `/certifications/${match.params.vacols_id}/confirm_case_details`
          }
          certificationId={certificationId}/>
      </div>
    </div> }
    </div>;
  }
}

const mapStateToProps = (state) => ({
  certificationStatus: state.certificationStatus,
  form9Match: state.form9Match,
  form9Date: state.form9Date,
  nodMatch: state.nodMatch,
  nodDate: state.nodDate,
  socMatch: state.socMatch,
  socDate: state.socDate,
  ssocDatesWithMatches: state.ssocDatesWithMatches,
  documentsMatch: state.documentsMatch,
  certificationId: state.certificationId

});

const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => {
    dispatch({
      type: Constants.UPDATE_PROGRESS_BAR,
      payload: {
        currentSection: Constants.progressBarSections.CHECK_DOCUMENTS
      }
    });
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
  form9Date: PropTypes.string,
  nodMatch: PropTypes.bool,
  nodDate: PropTypes.string,
  socMatch: PropTypes.bool,
  socDate: PropTypes.string,
  documentsMatch: PropTypes.bool,
  match: PropTypes.object.isRequired
};

export default DocumentsCheck;
