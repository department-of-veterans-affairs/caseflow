import React from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
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

  render() {

    /* TODO: add ssoc_match and ssoc_dates */
    let {
      form9Match,
      form9Date,
      nodMatch,
      nodDate,
      socMatch,
      socDate,
      documentsMatch,
      match,
      certificationId
    } = this.props;

    return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Check Documents</h2>
        { documentsMatch ? <DocumentsMatchingBox/> : <DocumentsNotMatchingBox/> }
        <DocumentsCheckTable form9Match={form9Match}
          form9Date={form9Date}
          nodMatch={nodMatch}
          nodDate={nodDate}
          socMatch={socMatch}
          socDate={socDate}
          documentsMatch={documentsMatch}/>
      </div>

      <div className="cf-app-segment">
        <Footer
          nextPageUrl={
            `/certifications/${match.params.vacols_id}/confirm_case_details`
          }
          certificationId={certificationId}/>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  form9Match: state.form9Match,
  form9Date: state.form9Date,
  nodMatch: state.nodMatch,
  nodDate: state.nodDate,
  socMatch: state.socMatch,
  socDate: state.socDate,
  documentsMatch: state.documentsMatch,
  certificationId: state.certificationId
    /* TODO: add ssoc_match and ssoc_dates */
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

export default DocumentsCheck;
