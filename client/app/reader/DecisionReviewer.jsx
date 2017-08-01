import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Route, BrowserRouter } from 'react-router-dom';
import Analytics from '../util/AnalyticsUtil';

import PageRoute from '../components/PageRoute';
import PdfViewer from './PdfViewer';
import PdfListView from './PdfListView';
import ReaderLoadingScreen from './ReaderLoadingScreen';
import CaseSelect from './CaseSelect';
import CaseSelectLoadingScreen from './CaseSelectLoadingScreen';
import * as ReaderActions from './actions';
import { ANALYTICS } from './constants';
import _ from 'lodash';

const fireSingleDocumentModeEvent = _.memoize(() => {
  Analytics.event(ANALYTICS.VIEW_DOCUMENT_PAGE, 'single-document-mode');
});

export class DecisionReviewer extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      isCommentLabelSelected: false
    };

    this.routedPdfListView.displayName = 'RoutedPdfListView';
    this.routedPdfViewer.displayName = 'RoutedPdfViewer';
    this.documentsRoute.displayName = 'DocumentsRoute';
  }

  showPdf = (history, vacolsId) => (docId) => () => {
    if (!this.props.storeDocuments[docId]) {
      return;
    }

    history.push(`/${vacolsId}/documents/${docId}`);
  }

  onShowList = (history, vacolsId) => () => {
    history.push(`/${vacolsId}/documents`);
  }

  clearPlacingAnnotationState = () => {
    if (this.props.pdf.isPlacingAnnotation) {
      this.props.stopPlacingAnnotation();
    }
  }

  componentWillUnmount() {
    window.removeEventListener('click', this.clearPlacingAnnotationState);
  }

  componentDidMount = () => {
    window.addEventListener('click', this.clearPlacingAnnotationState);
    if (this.props.singleDocumentMode) {
      fireSingleDocumentModeEvent();
    }
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
        documentPathBase={`/${vacolsId}/documents`}
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
        documentPathBase={`/${vacolsId}/documents`}
        {...props}
      />
    ;
  }

  routedCaseSelect = () => {
    return <CaseSelectLoadingScreen
      assignments={this.props.assignments}>
        <PageRoute
          exact
          title="Assignments | Caseflow Reader"
          path="/"
          render={() => <CaseSelect />}
        />
    </CaseSelectLoadingScreen>;
  }

  documentsRoute = (props) => {
    const { vacolsId } = props.match.params;

    return <ReaderLoadingScreen
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
    </ReaderLoadingScreen>;
  }

  render() {
    const Router = this.props.router || BrowserRouter;

    return <Router basename="/reader/appeal" {...this.props.routerTestProps}>
      <div className="section--document-list">
        <Route
          path="/:vacolsId/documents"
          render={this.documentsRoute}
        />
        <Route
          exact
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
  singleDocumentMode: PropTypes.bool,

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
