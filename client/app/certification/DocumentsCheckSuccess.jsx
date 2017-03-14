import React, { PropTypes } from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import FoundIcon from '../components/FoundIcon';
import NotFoundIcon from '..  /components/NotFoundIcon';
import DocumentsCheckTable from './DocumentsCheckTable';

export default class DocumentsCheckSuccess extends React.Component {
  render() {
    return <div>
      <div className="cf-app-segment cf-app-segment--alt">
      <h2>Check Documents</h2>
      <DocumentsMatchingBox/>
      <DocumentsCheckTable/>

      <p>
        Caseflow could not find the documents marked with an X (todo icon missing)
        in the appellant's eFolder. This usually happens when something doesn't match up. Try checking:
      </p>

      <ul>
        <li>The <strong>document type</strong> in VBMS to make sure it's <a href="/#mismatched-documents">labeled correctly</a></li>
        <li>The <strong>document date</strong> &#8212; the date in VBMS must match the date in VACOLS</li>
      </ul>

      <p>
        Once you've made corrections,&nbsp;
        <button type="button" className="cf-action-refresh cf-btn-link cf-btn-link--inline">refresh this page.</button>
      </p>

      <p>
        If you can’t find the document,&nbsp;
        <a href="#confirm-cancel-certification" className="cf-action-openmodal cf-btn-link">cancel this certification.</a>
      </p>

    </div>

    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification" className="cf-action-openmodal cf-btn-link">Cancel Certification</a>
      <button type="button" className="cf-push-right cf-action-refresh">Refresh Page</button>
    </div>
  </div>
  }
}
