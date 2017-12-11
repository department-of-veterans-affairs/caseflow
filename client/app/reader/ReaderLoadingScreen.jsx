import React from 'react';
import { bindActionCreators } from 'redux';
import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { onReceiveDocs, onInitialDataLoadingFail
} from './LoadingScreen/LoadingScreenActions';
import { onReceiveManifests } from './DocumentList/DocumentListActions';
import { onReceiveAnnotations } from './AnnotationLayer/AnnotationActions';
import { connect } from 'react-redux';
import StatusMessage from '../components/StatusMessage';
import LoadingScreen from '../components/LoadingScreen';
import * as Constants from './constants';
import _ from 'lodash';

export class ReaderLoadingScreen extends React.Component {

  componentDidMount = () => {
    if (this.props.loadedAppealId && this.props.loadedAppealId === this.props.vacolsId) {
      return;
    }

    // We clear any loading failures before trying to load.
    this.props.onInitialDataLoadingFail(false);

    ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents`, {}, ENDPOINT_NAMES.DOCUMENTS).then((response) => {
      const returnedObject = JSON.parse(response.text);
      const documents = returnedObject.appealDocuments;
      const { annotations, manifestVbmsFetchedAt, manifestVvaFetchedAt } = returnedObject;

      this.props.onReceiveDocs(documents, this.props.vacolsId);
      this.props.onReceiveManifests(manifestVbmsFetchedAt, manifestVvaFetchedAt);
      this.props.onReceiveAnnotations(annotations);
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
            message="Loading claims folder in Reader..." />
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
