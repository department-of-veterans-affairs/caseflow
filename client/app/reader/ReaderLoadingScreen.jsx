import React from 'react';
import { bindActionCreators } from 'redux';
import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveDocs, onReceiveManifests, onReceiveAnnotations } from './LoadingScreen/LoadingScreenActions';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import * as Constants from './constants';

export class ReaderLoadingScreen extends React.Component {

  constructor() {
    super();
    this.state = {};
  }

  componentDidMount = () => {
    if (this.props.loadedAppealId && this.props.loadedAppealId === this.props.vacolsId) {
      return;
    }

    const loadPromise = ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents`, {}, ENDPOINT_NAMES.DOCUMENTS).then((response) => {
      const returnedObject = JSON.parse(response.text);
      const documents = returnedObject.appealDocuments;
      const { annotations, manifestVbmsFetchedAt, manifestVvaFetchedAt } = returnedObject;

      this.props.onReceiveDocs(documents, this.props.vacolsId);
      this.props.onReceiveManifests(manifestVbmsFetchedAt, manifestVvaFetchedAt);
      this.props.onReceiveAnnotations(annotations);
    });

    this.setState({
      promiseStartTimeMs: Date.now(),
      loadPromise
    });
  }

  render() {
    // We create this.loadPromise in componentDidMount().
    // componentDidMount() is only called after the component is inserted into the DOM,
    // which means that render() will be called beforehand. My inclination was to use
    // componentWillMount() instead, but React docs tell us not to introduce side-effects
    // in that method. I don't know why that's a bad idea. But this approach lets us
    // keep the side effects in componentDidMount().
    if (!this.state.loadPromise) {
      return null;
    }

    const failComponent = <StatusMessage
      title="Unable to load documents">
        It looks like Caseflow was unable to load this case.<br />
        Please <a href="">refresh the page</a> and try again.
    </StatusMessage>;

    const loadingDataDisplay = <LoadingDataDisplay
      loadPromise={this.state.loadPromise}
      promiseStartTimeMs={this.state.promiseStartTimeMs}
      loadingScreenProps={{
        spinnerColor: Constants.READER_COLOR,
        message: 'Loading claims folder in Reader...'
      }}
      successComponent={this.props.children}
      failureComponent={failComponent}
    />;

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
