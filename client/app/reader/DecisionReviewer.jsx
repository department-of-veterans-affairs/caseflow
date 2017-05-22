import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Route, BrowserRouter } from 'react-router-dom';
import Perf from 'react-addons-perf';

import PdfViewer from './PdfViewer';
import PdfListView from './PdfListView';
import LoadingScreen from './LoadingScreen';
import * as ReaderActions from './actions';
import _ from 'lodash';

export const documentPath = (id) => `/document/${id}/pdf`;

export class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isCommentLabelSelected: false
    };

    this.isMeasuringPerf = false;

    this.routedPdfListView.displayName = 'RoutedPdfListView';
    this.routedPdfViewer.displayName = 'RoutedPdfViewer';
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
          this.props.handleSetLastRead(docId)
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

  onCommentScrolledTo = () => {
    this.props.onScrollToComment(null);
  }

  documents = () => {
    return this.props.filteredDocIds ?
      _.map(this.props.filteredDocIds, (docId) => this.props.storeDocuments[docId]) :
      _.values(this.props.storeDocuments);
  }

  routedPdfListView = (routerProps) => {
    const { vacolsId } = routerProps.match.params;

    return <LoadingScreen vacolsId={vacolsId}>
      <PdfListView
        documents={this.documents()}
        showPdf={this.showPdf(routerProps.history, vacolsId)}
        sortBy={this.state.sortBy}
        selectedLabels={this.state.selectedLabels}
        isCommentLabelSelected={this.state.isCommentLabelSelected}
        documentPathBase={`/reader/appeal/${vacolsId}/documents`}
        onJumpToComment={this.onJumpToComment(routerProps.history, vacolsId)}
        {...routerProps}
      />
    </LoadingScreen>;
  }

  routedPdfViewer = (routerProps) => {
    const { vacolsId } = routerProps.match.params;

    return <LoadingScreen vacolsId={vacolsId}>
      <PdfViewer
        addNewTag={this.props.addNewTag}
        removeTag={this.props.removeTag}
        documents={this.documents()}
        allDocuments={_.values(this.props.storeDocuments)}
        pdfWorker={this.props.pdfWorker}
        onShowList={this.onShowList(routerProps.history, vacolsId)}
        showPdf={this.showPdf(routerProps.history, vacolsId)}
        onJumpToComment={this.onJumpToComment(routerProps.history, vacolsId)}
        onCommentScrolledTo={this.onCommentScrolledTo}
        documentPathBase={`/reader/appeal/${vacolsId}/documents`}
        {...routerProps}
      />
    </LoadingScreen>;
  }

  render() {
    const Router = this.props.router || BrowserRouter;

    return <Router basename="/reader/appeal" {...this.props.routerTestProps}>
        <div className="section--document-list">
          <Route exact path="/:vacolsId/documents"
            component={this.routedPdfListView}
          />
          <Route path="/:vacolsId/documents/:docId"
            component={this.routedPdfViewer}
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
    filteredDocIds: state.ui.filteredDocIds,
    storeDocuments: state.documents,
    pdf: state.ui.pdf
  };
};

const mapDispatchToProps = (dispatch) => {
  return bindActionCreators(ReaderActions, dispatch);
};

export default connect(mapStateToProps, mapDispatchToProps)(DecisionReviewer);
