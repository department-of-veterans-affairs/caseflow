import React from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import { connect } from 'react-redux';
import Footer from './Footer';


// TODO: refactor to use shared components where helpful
const UnconnectedDocumentsCheck = ({
  form9Match,
  form9Date,
  nodMatch,
  nodDate,
  socMatch,
  socDate,
  documentsMatch,
  match,
  certificationId

  /* TODO: add ssoc_match and ssoc_dates */
}) => {
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
          `/certifications/${match.params.vacols_id}/sign_and_certify`
        }
        certificationId={certificationId}/>
    </div>

  </div>;
};

const mapStateToProps = (state) => {
  return {
    form9Match: state.form9Match,
    form9Date: state.form9Date,
    nodMatch: state.nodMatch,
    nodDate: state.nodDate,
    socMatch: state.socMatch,
    socDate: state.socDate,
    documentsMatch: state.documentsMatch,
    certificationId: state.certificationId

    /* TODO: add ssoc_match and ssoc_dates */
  };
};


/*
 * Creates a component that's connected to the Redux store
 * using the state & dispatch map functions and the
 * ConfirmHearing function.
 */
const DocumentsCheck = connect(
  mapStateToProps
)(UnconnectedDocumentsCheck);

export default DocumentsCheck;
