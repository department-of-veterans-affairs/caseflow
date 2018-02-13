import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router';
import { getQueryParams } from '../util/QueryParamsUtil';

import AppFrame from '../components/AppFrame';
import PageRoute from '../components/PageRoute';
import PdfViewer from './PdfViewer';
import PdfListView from './PdfListView';
import ReaderLoadingScreen from './ReaderLoadingScreen';
import CaseSelect from './CaseSelect';
import CaseSelectLoadingScreen from './CaseSelectLoadingScreen';
import { onScrollToComment } from '../reader/Pdf/PdfActions';
import { setCategoryFilter } from '../reader/DocumentList/DocumentListActions';
import { stopPlacingAnnotation } from '../reader/AnnotationLayer/AnnotationActions';
import { CATEGORIES } from './analytics';
import { documentCategories } from './constants';
import _ from 'lodash';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { LOGO_COLORS } from '../constants/AppConstants';

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
    if (this.props.isPlacingAnnotation) {
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

      // Clear out the URI query string params after we determine the initial
      // category filter so that we do not continue to attempt to set the
      // category filter every time routedPdfListView renders.
      props.location.search = '';
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
        allDocuments={_.values(this.props.storeDocuments)}
        pdfWorker={this.props.pdfWorker}
        showPdf={this.showPdf(props.history, vacolsId)}
        history={props.history}
        onJumpToComment={this.onJumpToComment(props.history, vacolsId)}
        documentPathBase={`/${vacolsId}/documents`}
        featureToggles={this.props.featureToggles}
        {...props}
      />
    </ReaderLoadingScreen>
    ;
  }

  routedCaseSelect = (props) => <CaseSelectLoadingScreen assignments={this.props.assignments}>
    <CaseSelect history={props.history}
      feedbackUrl={this.props.feedbackUrl} />
  </CaseSelectLoadingScreen>

  getClaimsFolderPageTitle = (appeal) => appeal && appeal.veteran_first_name ?
    `${appeal.veteran_first_name.charAt(0)}. \
      ${appeal.veteran_last_name}'s Claims Folder` : 'Claims Folder | Caseflow Reader';

  render() {
    const queueEnabled = this.props.featureToggles.queueWelcomeGate;

    const { vacolsId } = this.props.match.params;
    const defaultUrl = queueEnabled ? `/${vacolsId}/documents/` : '/';
    const claimsFolderBreadcrumb = queueEnabled ? '' : 'Claims Folder';

    return <React.Fragment>
      <NavigationBar
        wideApp
        appName="Reader"
        logoProps={{
          accentColor: LOGO_COLORS.READER.ACCENT,
          overlapColor: LOGO_COLORS.READER.OVERLAP
        }}
        userDisplayName={this.props.userDisplayName}
        dropdownUrls={this.props.dropdownUrls}
        defaultUrl={defaultUrl}>
        <PageRoute
          exact
          title="Document Viewer | Caseflow Reader"
          breadcrumb="Document Viewer"
          path="/:vacolsId/documents/:docId"
          render={this.routedPdfViewer} />
        <AppFrame wideApp>
          <PageRoute
            exact
            title={this.getClaimsFolderPageTitle(this.props.appeal)}
            breadcrumb={claimsFolderBreadcrumb}
            path="/:vacolsId/documents"
            render={this.routedPdfListView} />
          {!queueEnabled && <PageRoute
            exact
            path="/"
            title="Assignments | Caseflow Reader"
            render={this.routedCaseSelect} />
          }
        </AppFrame>
      </NavigationBar>
      <Footer
        wideApp
        appName="Reader"
        feedbackUrl={this.props.feedbackUrl}
        buildDate={this.props.buildDate} />
    </React.Fragment>
    ;
  }
}

DecisionReviewer.propTypes = {
  pdfWorker: PropTypes.string,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  singleDocumentMode: PropTypes.bool,

  // Required actions
  onScrollToComment: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  setCategoryFilter: PropTypes.func,

  // These two properties are exclusively for testing purposes
  router: PropTypes.func,
  routerProps: PropTypes.object
};

const mapStateToProps = (state, props) => {

  const getAssignmentFromCaseSelect = (caseSelect, match) =>
    match && match.params.vacolsId ?
      _.find(caseSelect.assignments, { vacols_id: match.params.vacolsId }) :
      null;

  return {
    documentFilters: state.documentList.pdfList.filters,
    storeDocuments: state.documents,
    isPlacingAnnotation: state.annotationLayer.isPlacingAnnotation,
    appeal: getAssignmentFromCaseSelect(state.caseSelect, props.match) ||
      state.pdfViewer.loadedAppeal
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    onScrollToComment,
    setCategoryFilter,
    stopPlacingAnnotation
  }, dispatch)
});

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(DecisionReviewer));
