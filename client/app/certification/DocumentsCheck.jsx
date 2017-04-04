import React from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import { Link } from 'react-router-dom';
import { connect } from 'react-redux';
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
    let { form9Match,
      form9Date,
      nodMatch,
      nodDate,
      socMatch,
      socDate,
      documentsMatch,
      match } = this.props;

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
        <a href="#confirm-cancel-certification"
          className="cf-action-openmodal cf-btn-link">
          Cancel Certification
        </a>
        <Link
          to={`/certifications/${match.params.vacols_id}/confirm_case_details`}>
          <button type="button" className="cf-push-right">
            Continue
          </button>
        </Link>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    form9Match: state.form9Match,
    form9Date: state.form9Date,
    nodMatch: state.nodMatch,
    nodDate: state.nodDate,
    socMatch: state.socMatch,
    socDate: state.socDate,
    documentsMatch: state.documentsMatch

    /* TODO: add ssoc_match and ssoc_dates */
  };
};

const mapDispatchToProps = (dispatch) => {
  return {
    updateProgressBar: () => {
      dispatch({
        type: Constants.UPDATE_PROGRESS_BAR,
        payload: {
          currentSection: Constants.progressBarSections.CHECK_DOCUMENTS
        }
      });
    }
  };
};

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
