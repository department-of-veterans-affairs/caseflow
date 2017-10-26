import React from 'react';
import { bindActionCreators } from 'redux';
import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveDocs, onReceiveManifests, onReceiveAnnotations, onInitialDataLoadingFail
} from './LoadingScreen/LoadingScreenActions';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';
import LoadingScreen from '../components/LoadingScreen';
import * as Constants from './constants';
import _ from 'lodash';

const PARALLEL_DOCUMENT_REQUESTS = 3;

export class ReaderLoadingScreen extends React.Component {

  componentDidMount = () => {
    // We clear any loading failures before trying to load.
    this.props.onInitialDataLoadingFail(false);

    ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents`, {}, ENDPOINT_NAMES.DOCUMENTS).then((response) => {
      const returnedObject = JSON.parse(response.text);
      const documents = returnedObject.appealDocuments;
      const { annotations, manifestVbmsFetchedAt, manifestVvaFetchedAt } = returnedObject;

      this.props.onReceiveDocs(documents, this.props.vacolsId);
      this.props.onReceiveManifests(manifestVbmsFetchedAt, manifestVvaFetchedAt);
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
    onReceiveManifests,
    onReceiveAnnotations
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(ReaderLoadingScreen);
