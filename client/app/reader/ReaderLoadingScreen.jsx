import React from 'react';
import { bindActionCreators } from 'redux';
import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveDocs, onReceiveManifests, onReceiveAnnotations } from './LoadingScreen/LoadingScreenActions';
import { connect } from 'react-redux';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import * as Constants from './constants';

export class ReaderLoadingScreen extends React.Component {
  createLoadPromise = () => {
    if (this.props.loadedAppealId && this.props.loadedAppealId === this.props.vacolsId) {
      return Promise.resolve();
    }

    return ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents`, {}, ENDPOINT_NAMES.DOCUMENTS).
      then((response) => {
        const returnedObject = JSON.parse(response.text);
        const documents = returnedObject.appealDocuments;
        const { annotations, manifestVbmsFetchedAt, manifestVvaFetchedAt } = returnedObject;

        this.props.onReceiveDocs(documents, this.props.vacolsId);
        this.props.onReceiveManifests(manifestVbmsFetchedAt, manifestVvaFetchedAt);
        this.props.onReceiveAnnotations(annotations);
      });
  }

  render() {
    const failStatusMessageChildren = <div>
        It looks like Caseflow was unable to load this case.<br />
        Please <a href="">refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingScreenProps={{
        spinnerColor: Constants.READER_COLOR,
        message: 'Loading claims folder in Reader...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load documents'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return <div className="usa-grid">
      <div className="cf-app">
        {loadingDataDisplay}
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  loadedAppealId: state.readerReducer.loadedAppealId
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onReceiveDocs,
    onReceiveManifests,
    onReceiveAnnotations
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(ReaderLoadingScreen);
