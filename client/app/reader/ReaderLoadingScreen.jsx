import React from 'react';
import { bindActionCreators } from 'redux';
import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveDocs, onReceiveAnnotations, onInitialDataLoadingFail } from './actions';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';
import LoadingScreen from '../components/LoadingScreen';
import * as Constants from './constants';
import _ from 'lodash';

const PARALLEL_DOCUMENT_REQUESTS = 3;

export class ReaderLoadingScreen extends React.Component {

  componentDidMount = () => {
    // This means we received documents from the backend. This happens when someone is requesting
    // an individual document. We don't want to load the entire case, so we avoid the API call.
    if (this.props.appealDocuments && this.props.annotations) {
      this.props.onReceiveDocs(this.props.appealDocuments, this.props.vacolsId);
      this.props.onReceiveAnnotations(this.props.annotations);
    } else {
      // We clear any loading failures before trying to load.
      this.props.onInitialDataLoadingFail(false);

      ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents`, {}, ENDPOINT_NAMES.DOCUMENTS).then((response) => {
        const returnedObject = JSON.parse(response.text);
        const documents = returnedObject.appealDocuments;
        const { annotations } = returnedObject;

        this.props.onReceiveDocs(documents, this.props.vacolsId);
        this.props.onReceiveAnnotations(annotations);

        const downloadDocuments = (documentUrls, index) => {
          if (index >= documentUrls.length) {
            return;
          }

          ApiUtil.get(documentUrls[index], {
            cache: true,
            withCredentials: true
          }, ENDPOINT_NAMES.DOCUMENT_CONTENT).then(
            () => downloadDocuments(documentUrls, index + PARALLEL_DOCUMENT_REQUESTS)
          );
        };

        for (let i = 0; i < PARALLEL_DOCUMENT_REQUESTS; i++) {
          downloadDocuments(_.map(documents, 'content_url'), i);
        }
      }, this.props.onInitialDataLoadingFail);
    }
  }

  render() {
    if (this.props.loadedAppealId && this.props.loadedAppealId === this.props.vacolsId) {
      return this.props.children;
    }

    return <div className="usa-grid">
      <div className="cf-app">
        {this.props.initialDataLoadingFail ?
          <StatusMessage
            title="Unable to load documents">
              It looks like Caseflow was unable to load this case.<br />
              Please <a href="">refresh the page</a> and try again.
          </StatusMessage> :
          <LoadingScreen
            spinnerColor={Constants.READER_COLOR}
            message="Loading claims folder in Reader..."/>
        }
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  ..._.pick(state.readerReducer, 'initialDataLoadingFail'),
  loadedAppealId: state.readerReducer.loadedAppealId
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onInitialDataLoadingFail,
    onReceiveDocs,
    onReceiveAnnotations
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(ReaderLoadingScreen);
