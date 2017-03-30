import React from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import { Link } from 'react-router-dom';
import { connect } from 'react-redux';



// TODO: refactor to use shared components where helpful
const UnconnectedDocumentsCheck = ({
  form9Match,
  form9Date,
  nodMatch,
  nodDate,
  socMatch,
  socDate,
  /* TODO: add ssoc_match and ssoc_dates */
  vbmsId,
  veteranName,
  certificationStatus,
  vacolsId,
  match
}) => {
  return <div>
    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Check Documents</h2>
      { match ? <DocumentsMatchingBox/> : <DocumentsNotMatchingBox/> }
      <DocumentsCheckTable form9Match={form9Match}
        form9Date={form9Date}
        nodMatch={nodMatch}
        nodDate={nodDate}
        socMatch={socMatch}
        socDate={socDate} />
    </div>

    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
      <Link
        to={`/certifications/${match.params.vacols_id}/confirm_hearing`}>
        <button type="button" className="cf-push-right">
          Continue
        </button>
      </Link>
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
    /* TODO: add ssoc_match and ssoc_dates */
    vbmsId: state.vbmsId,
    veteranName: state.veteranName,
    certificationStatus: state.certificationStatus,
    vacolsId: state.vacolsId
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
