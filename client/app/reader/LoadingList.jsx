import React, { PropTypes } from 'react';
import { bindActionCreators } from 'redux';
import ApiUtil from '../util/ApiUtil';
import * as ReaderActions from './actions';
import { connect } from 'react-redux';

export class LoadingList extends React.Component {

  componentDidMount = () => {
    ApiUtil.get(`reader/appeal/${this.props.vacolsId}/documents/metadata`).then((documents) => {
      this.props.onReceiveDocs(documents);

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
    })
  }

  render = () => {
    <div>LOADING AF</div>
  }
}

const mapDispatchToProps = (dispatch) => ({
  onReceiveDocs: (docId) => dispatch(onReceiveDocs(docId))
});

export default connect(null, mapDispatchToProps)(LoadingList);
