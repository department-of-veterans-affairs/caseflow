import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import { getMinutesToMilliseconds } from '../util/DateUtil';
import { onReceiveManifests } from './DocumentList/DocumentListActions';
import { onReceiveDocs } from '../reader/Documents/DocumentsActions';
import { onReceiveAnnotations } from './AnnotationLayer/AnnotationActions';
import { connect } from 'react-redux';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';

export class ReaderLoadingScreen extends React.Component {
  createLoadPromise = () => {
    if (this.props.loadedAppealId && this.props.loadedAppealId === this.props.vacolsId) {
      return Promise.resolve();
    }

    const reqOptions = {
      timeout: { response: getMinutesToMilliseconds(5) }
    };

    return ApiUtil.get(`/reader/appeal/${this.props.vacolsId}/documents?json`, reqOptions, ENDPOINT_NAMES.DOCUMENTS).
      then((response) => {
        const returnedObject = response.body;
        const documents = returnedObject.appealDocuments;
        const { annotations, manifestVbmsFetchedAt, manifestVvaFetchedAt } = returnedObject;

        this.props.onReceiveDocs(documents, this.props.vacolsId);
        this.props.onReceiveManifests(manifestVbmsFetchedAt, manifestVvaFetchedAt);
        this.props.onReceiveAnnotations(annotations);
      }).
      catch((err) => {
        // allow HTTP errors to fall on the floor via the console.
        console.error(new Error(`Problem with GET /reader/appeal/${this.props.vacolsId}/documents?json ${err}`));
      });
  }

  render() {
    const failStatusMessageChildren = <div>
        It looks like Caseflow was unable to load this case.<br />
        Please <a href="">refresh the page</a> and try again.
    </div>;

    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.READER.ACCENT,
        message: 'Loading claims folder in Reader...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load documents'
      }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.props.children}
    </LoadingDataDisplay>;

    return loadingDataDisplay;
  }
}

ReaderLoadingScreen.propTypes = {
  children: PropTypes.node,
  loadedAppealId: PropTypes.string,
  onReceiveAnnotations: PropTypes.func,
  onReceiveDocs: PropTypes.func,
  onReceiveManifests: PropTypes.func,
  vacolsId: PropTypes.string
};

const mapStateToProps = (state) => ({
  loadedAppealId: state.pdfViewer.loadedAppealId
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onReceiveDocs,
    onReceiveManifests,
    onReceiveAnnotations
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(ReaderLoadingScreen);
