import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Route, BrowserRouter } from 'react-router-dom';
import Perf from 'react-addons-perf';

import PageRoute from '../components/PageRoute';
import PdfViewer from './PdfViewer';
import PdfListView from './PdfListView';
import LoadingScreen from './LoadingScreen';
import CaseSelect from './CaseSelect';
import * as ReaderActions from './actions';
import _ from 'lodash';

export const documentPath = (id) => `/document/${id}/pdf`;

export class DecisionReviewer extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      isCommentLabelSelected: false
    };

    this.isMeasuringPerf = false;

    this.routedPdfListView.displayName = 'RoutedPdfListView';
    this.routedPdfViewer.displayName = 'RoutedPdfViewer';
    this.documentsRoute.displayName = 'DocumentsRoute';
  }

  showPdf = (history, vacolsId) => (docId) => (event) => {
    if (!this.props.storeDocuments[docId]) {
      return;
    }

    if (event) {
      // If the user is trying to open the link in a new tab/window
      // then follow the link. Otherwise if they just clicked the link
      // keep them contained within the SPA.
      // ctrlKey for windows
      // shift key for opening in new window
      // metaKey for Macs
      // button for middle click
      if (event.ctrlKey ||
          event.shiftKey ||
          event.metaKey ||
          (event.button &&
          event.button === 1)) {

        // For some reason calling this synchronosly prevents the new
        // tab from opening. Move it to an asynchronus call.
        setTimeout(() =>
          this.props.handleSelectCurrentPdf(docId)
        );

        return true;
      }

      event.preventDefault();
    }

    history.push(`/${vacolsId}/documents/${docId}`);
  }

  onShowList = (history, vacolsId) => () => {
    history.push(`/${vacolsId}/documents`);
  }

  // eslint-disable-next-line max-statements
  handleStartPerfMeasurement = (event) => {
    if (!(event.altKey && event.code === 'KeyP')) {
      return;
    }
    /* eslint-disable no-console */

    // eslint-disable-next-line no-negated-condition
    if (!this.isMeasuringPerf) {
      Perf.start();
      console.log('Started React perf measurements');
      this.isMeasuringPerf = true;
    } else {
      Perf.stop();
      this.isMeasuringPerf = false;

      const measurements = Perf.getLastMeasurements();

      console.group('Stopped measuring React perf. (If nothing re-rendered, nothing will show up.) Results:');
      Perf.printInclusive(measurements);
      Perf.printWasted(measurements);
      console.groupEnd();
    }
    /* eslint-enable no-console */
  }

  clearPlacingAnnotationState = () => {
    if (this.props.pdf.isPlacingAnnotation) {
      this.props.stopPlacingAnnotation();
    }
  }

  componentWillUnmount() {
    window.removeEventListener('click', this.clearPlacingAnnotationState);
    window.removeEventListener('keydown', this.handleStartPerfMeasurement);
  }

  componentDidMount = () => {
    window.addEventListener('keydown', this.handleStartPerfMeasurement);
    window.addEventListener('click', this.clearPlacingAnnotationState);
  }

  onJumpToComment = (history, vacolsId) => (comment) => () => {
    this.showPdf(history, vacolsId)(comment.documentId)();
    this.props.onScrollToComment(comment);
  }

  routedPdfListView = (props) => {
    const { vacolsId } = props.match.params;

    return <PdfListView
        showPdf={this.showPdf(props.history, vacolsId)}
        sortBy={this.state.sortBy}
        selectedLabels={this.state.selectedLabels}
        isCommentLabelSelected={this.state.isCommentLabelSelected}
        documentPathBase={`/reader/appeal/${vacolsId}/documents`}
        onJumpToComment={this.onJumpToComment(props.history, vacolsId)}
        {...props}
      />;
  }

  routedPdfViewer = (props) => {
    const { vacolsId } = props.match.params;

    return <PdfViewer
        addNewTag={this.props.addNewTag}
        removeTag={this.props.removeTag}
        allDocuments={_.values(this.props.storeDocuments)}
        pdfWorker={this.props.pdfWorker}
        onShowList={this.onShowList(props.history, vacolsId)}
        showPdf={this.showPdf(props.history, vacolsId)}
        onJumpToComment={this.onJumpToComment(props.history, vacolsId)}
        documentPathBase={`/reader/appeal/${vacolsId}/documents`}
        {...props}
      />
    ;
  }

  routedCaseSelect = () => <CaseSelect />

  documentsRoute = (props) => {
    const { vacolsId } = props.match.params;

    return <LoadingScreen
      appealDocuments={this.props.appealDocuments}
      annotations={this.props.annotations}
      vacolsId={vacolsId}>
      <div>

        <PageRoute
          exact
          title="Claims Folder | Caseflow Reader"
          path="/:vacolsId/documents"
          render={this.routedPdfListView}
        />
        <PageRoute
          title ="Document Viewer | Caseflow Reader"
          path="/:vacolsId/documents/:docId"
          render={this.routedPdfViewer}
        />
      </div>
    </LoadingScreen>;
  }

  render() {
    const Router = this.props.router || BrowserRouter;

    return <Router basename="/reader/appeal" {...this.props.routerTestProps}>
      <div className="section--document-list">
        <Route
          path="/:vacolsId/documents"
          render={this.documentsRoute}
        />
        <PageRoute
          exact
          title="Assignments | Caseflow Reader"
          path="/"
          render={this.routedCaseSelect}
        />
      </div>
    </Router>;
  }
}

DecisionReviewer.propTypes = {
  pdfWorker: PropTypes.string,
  onScrollToComment: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  handleSetLastRead: PropTypes.func.isRequired,

  // These two properties are exclusively for testing purposes
  router: PropTypes.func,
  routerProps: PropTypes.object
};

const mapStateToProps = (state) => {
  return {
    documentFilters: state.ui.pdfList.filters,
    storeDocuments: state.documents,
    pdf: state.ui.pdf
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators(ReaderActions, dispatch),
  handleSelectCurrentPdf: (docId) => dispatch(ReaderActions.selectCurrentPdf(docId))
});

export default connect(mapStateToProps, mapDispatchToProps)(DecisionReviewer);
