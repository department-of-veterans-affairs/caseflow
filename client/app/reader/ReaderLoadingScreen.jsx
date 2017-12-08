import React from 'react';
import { bindActionCreators } from 'redux';
import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveDocs, onReceiveManifests, onReceiveAnnotations, onInitialDataLoadingFail
} from './LoadingScreen/LoadingScreenActions';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import * as Constants from './constants';
import _ from 'lodash';

export class ReaderLoadingScreen extends React.Component {

  componentDidMount = () => {
    if (this.props.loadedAppealId && this.props.loadedAppealId === this.props.vacolsId) {
      return;
    }

    this.promiseStartTimeMs = Date.now();
    this.loadPromise = ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents`, {}, ENDPOINT_NAMES.DOCUMENTS).then((response) => {
      const returnedObject = JSON.parse(response.text);
      const documents = returnedObject.appealDocuments;
      const { annotations, manifestVbmsFetchedAt, manifestVvaFetchedAt } = returnedObject;

      this.props.onReceiveDocs(documents, this.props.vacolsId);
      this.props.onReceiveManifests(manifestVbmsFetchedAt, manifestVvaFetchedAt);
      this.props.onReceiveAnnotations(annotations);
    });
  }

  render() {
    // We create this.loadPromise in componentDidMount().
    // componentDidMount() is only called after the component is inserted into the DOM,
    // which means that render() will be called beforehand. My inclination was to use
    // componentWillMount() instead, but React docs tell us not to introduce side-effects
    // in that method. I don't know why that's a bad idea. But this approach lets us
    // keep the side effects in componentDidMount().
    if (!this.loadPromise) {
      return null;
    }

    const failComponent = <StatusMessage
      title="Unable to load documents">
        It looks like Caseflow was unable to load this case.<br />
        Please <a href="">refresh the page</a> and try again.
    </StatusMessage>;

    return <LoadingDataDisplay
      loadPromise={this.loadPromise}
      promiseStartTimeMs={this.promiseStartTimeMs}
      timeoutMs={30 * 1000}
      slowLoadThresholdMs={15 * 1000}
      slowLoadMessage="Loading is taking longer than usual..."
      loadingScreenProps={{
        spinnerColor: Constants.READER_COLOR,
        message: 'Loading claims folder in Reader...'
      }}
      successComponent={this.props.children}
      failComponent={failComponent}
    />;
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
