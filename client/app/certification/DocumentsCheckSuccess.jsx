import React, { PropTypes } from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import FoundIcon from '../components/FoundIcon';
import NotFoundIcon from '../components/NotFoundIcon';
import DocumentsCheckTable from './DocumentsCheckTable';

export default class DocumentsCheckSuccess extends React.Component {
  render() {
    return <div>
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Check Documents</h2>
        <DocumentsMatchingBox/>
        <DocumentsCheckTable/>
      </div>

      <div className="cf-app-segment">
        <a href="#confirm-cancel-certification" className="cf-action-openmodal cf-btn-link">Cancel Certification</a>
        <button type="button" className="cf-push-right">Continue</button>
      </div>
    </div>
  }
}
