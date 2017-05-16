import React, { PropTypes } from 'react';
import { bindActionCreators } from 'redux';
import ApiUtil from '../util/ApiUtil';
import { onReceiveDocs, onReceiveAnnotations } from './actions';
import { connect } from 'react-redux';
import { loadingSymbolHtml } from '../components/RenderFunctions.jsx';
import * as Constants from './constants';

const PARALLEL_DOCUMENT_REQUESTS = 3;

export class LoadingList extends React.Component {
  documentUrl = (doc) => {
    return `/document/${doc.id}/pdf`;
  }

  annotationUrl = (doc) => {
    return `/document/${doc.id}/annotations`;
  }

  componentDidMount = () => {
    ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents/metadata`).then((response) => {
      const returnedObject = JSON.parse(response.text);
      const documents = returnedObject.appealDocuments;
      const annotations = returnedObject.annotations;

      this.props.onReceiveDocs(documents);
      this.props.onReceiveAnnotations(annotations);

      let downloadDocuments = (documentUrls, index) => {
        if (index >= documentUrls.length) {
          return;
        }

        ApiUtil.get(documentUrls[index], { cache: true }).
          then(() => {
            downloadDocuments(documentUrls, index + PARALLEL_DOCUMENT_REQUESTS);
          });
      };

      for (let i = 0; i < PARALLEL_DOCUMENT_REQUESTS; i++) {
        downloadDocuments(documents.map((doc) => {
          return this.documentUrl(doc);
        }), i);
      }
    });
  }

  render = () => {
    return <div className="usa-grid">
        <div className="cf-app">
          <div className="cf-app-segment cf-app-segment--alt cf-pdf-center-text">
            {loadingSymbolHtml('', '300px', Constants.READER_COLOR)}
            <p>Loading document list in Reader now...</p>
          </div>
        </div>
      </div>;
  }
}

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    onReceiveDocs,
    onReceiveAnnotations
  }, dispatch),
});

export default connect(null, mapDispatchToProps)(LoadingList);
