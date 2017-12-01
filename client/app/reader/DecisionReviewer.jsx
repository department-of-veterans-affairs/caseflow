import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import { getQueryParams } from '../util/QueryParamsUtil';

import PageRoute from '../components/PageRoute';
import PdfViewer from './PdfViewer';
import PdfListView from './PdfListView';
import ReaderLoadingScreen from './ReaderLoadingScreen';
import CaseSelect from './CaseSelect';
import CaseSelectLoadingScreen from './CaseSelectLoadingScreen';
import * as ReaderActions from './actions';
import { CATEGORIES } from './analytics';
import { documentCategories } from './constants';
import _ from 'lodash';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';

const fireSingleDocumentModeEvent = _.memoize(() => {
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'single-document-mode');
});

export class DecisionReviewer extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      isCommentLabelSelected: false
    };

    this.routedPdfListView.displayName = 'RoutedPdfListView';
    this.routedPdfViewer.displayName = 'RoutedPdfViewer';
    this.routedCaseSelect.displayName = 'RoutedCaseSelect';
  }

  showPdf = (history, vacolsId) => (docId) => () => {
    if (!this.props.storeDocuments[docId]) {
      return;
    }

    history.push(`/${vacolsId}/documents/${docId}`);
  }

  clearPlacingAnnotationState = () => {
    if (this.props.pdf.isPlacingAnnotation) {
      this.props.stopPlacingAnnotation('from-click-outside-doc');
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

  determineInitialCategoryFilter = (props) => {
    const queryParams = getQueryParams(props.location.search);
    const category = queryParams.category;

    if (documentCategories[category]) {
      this.props.setCategoryFilter(category, true);
    }
  };

  routedPdfListView = (props) => {
    const { vacolsId } = props.match.params;

    this.determineInitialCategoryFilter(props);

    return <ReaderLoadingScreen
      appealDocuments={this.props.appealDocuments}
      annotations={this.props.annotations}
      vacolsId={vacolsId}>
        <PdfListView
          showPdf={this.showPdf(props.history, vacolsId)}
          sortBy={this.state.sortBy}
          selectedLabels={this.state.selectedLabels}
          isCommentLabelSelected={this.state.isCommentLabelSelected}
          documentPathBase={`/${vacolsId}/documents`}
          onJumpToComment={this.onJumpToComment(props.history, vacolsId)}
          {...props}
        />
      </ReaderLoadingScreen>;
  }

  routedPdfViewer = (props) => {
    const { vacolsId } = props.match.params;

    return <ReaderLoadingScreen
      appealDocuments={this.props.appealDocuments}
      annotations={this.props.annotations}
      vacolsId={vacolsId}>
        <PdfViewer
          addNewTag={this.props.addNewTag}
          removeTag={this.props.removeTag}
          allDocuments={_.values(this.props.storeDocuments)}
          pdfWorker={this.props.pdfWorker}
          showPdf={this.showPdf(props.history, vacolsId)}
          onJumpToComment={this.onJumpToComment(props.history, vacolsId)}
          documentPathBase={`/${vacolsId}/documents`}
          {...props}
        />
      </ReaderLoadingScreen>
    ;
  }

  routedCaseSelect = (props) => <CaseSelectLoadingScreen assignments={this.props.assignments}>
      <CaseSelect history={props.history}
          feedbackUrl={this.props.feedbackUrl}/>
    </CaseSelectLoadingScreen>

  render() {
    const Router = this.props.router || BrowserRouter;

    return <Router basename="/reader/appeal" {...this.props.routerTestProps}>
        <div>
          <NavigationBar
            appName="Reader"
            userDisplayName={this.props.userDisplayName}
            dropdownUrls={this.props.dropdownUrls}
            defaultUrl="/">
            <div className="cf-wide-app section--document-list">
              <PageRoute
                exact
                path="/"
                title="Assignments | Caseflow Reader"
                render={this.routedCaseSelect}/>
              <PageRoute
                exact
                title="Claims Folder | Caseflow Reader"
                breadcrumb="Claims Folder"
                path="/:vacolsId/documents"
                render={this.routedPdfListView}/>
              <PageRoute
                exact
                title="Document Viewer | Caseflow Reader"
                breadcrumb="Document Viewer"
                path="/:vacolsId/documents/:docId"
                render={this.routedPdfViewer}
              />
            </div>
          </NavigationBar>
          <Footer
            appName="Reader"
            feedbackUrl={this.props.feedbackUrl}
            buildDate={this.props.buildDate}/>
        </div>
      </Router>;
  }
}

DecisionReviewer.propTypes = {
  pdfWorker: PropTypes.string,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
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
    documentFilters: state.readerReducer.ui.pdfList.filters,
    storeDocuments: state.readerReducer.documents,
    pdf: state.readerReducer.ui.pdf
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators(ReaderActions, dispatch),
  handleSelectCurrentPdf: (docId) => dispatch(ReaderActions.selectCurrentPdf(docId))
});

export default connect(mapStateToProps, mapDispatchToProps)(DecisionReviewer);
