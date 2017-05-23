import React from 'react';
import { bindActionCreators } from 'redux';
import ApiUtil from '../util/ApiUtil';
import { onReceiveDocs, onReceiveAnnotations, onInitialDataLoadingFail } from './actions';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';
import { loadingSymbolHtml } from '../components/RenderFunctions';
import * as Constants from './constants';
import _ from 'lodash';

const PARALLEL_DOCUMENT_REQUESTS = 3;

const documentUrl = ({ id }) => `/document/${id}/pdf`;

export class LoadingScreen extends React.Component {

  componentDidMount = () => {
    ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents`).then((response) => {
      const returnedObject = JSON.parse(response.text);
      const documents = returnedObject.appealDocuments;
      const { annotations } = returnedObject;

      this.props.onReceiveDocs(documents);
      this.props.onReceiveAnnotations(annotations);

      const downloadDocuments = (documentUrls, index) => {
        if (index >= documentUrls.length) {
          return;
        }

        ApiUtil.get(documentUrls[index], { cache: true }).then(
          () => downloadDocuments(documentUrls, index + PARALLEL_DOCUMENT_REQUESTS)
        );
      };

      for (let i = 0; i < PARALLEL_DOCUMENT_REQUESTS; i++) {
        downloadDocuments(documents.map((doc) => documentUrl(doc)), i);
      }
    }, this.props.onInitialDataLoadingFail);
  }

  render() {
    if (this.props.documentsLoaded) {
      return this.props.children;
    }

    if (this.props.initialDataLoadingFail) {
      return <StatusMessage
        title="Unable to load documents">
        It looks like Caseflow was unable to load this case. Please <a href="">refresh the page</a> and try again.
        </StatusMessage>;
    }

    return <div className="usa-grid">
        <div className="cf-app">
          <div
            id="loading-symbol"
            className="cf-app-segment cf-app-segment--alt cf-pdf-center-text">
            {loadingSymbolHtml('', '300px', Constants.READER_COLOR)}
            <p>Loading document list in Reader...</p>
          </div>
        </div>
      </div>;
  }
}

const mapStateToProps = (state) => ({
  ..._.pick(state, 'initialDataLoadingFail'),
  documentsLoaded: _.size(state.documents)
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onInitialDataLoadingFail,
    onReceiveDocs,
    onReceiveAnnotations
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(LoadingScreen);
