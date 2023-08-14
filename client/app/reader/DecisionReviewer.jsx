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
import { onScrollToComment } from '../reader/Pdf/PdfActions';
import { setCategoryFilter } from '../reader/DocumentList/DocumentListActions';
import { stopPlacingAnnotation } from '../reader/AnnotationLayer/AnnotationActions';
import { CATEGORIES } from './analytics';
import { documentCategories } from './constants';
import _ from 'lodash';
import NavigationBar from '../components/NavigationBar';
import CaseSearchLink from '../components/CaseSearchLink';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { LOGO_COLORS } from '../constants/AppConstants';
import { formatNameShort } from '../util/FormatUtil';

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
        efolderExpressUrl={this.props.efolderExpressUrl}
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

  getClaimsFolderPageTitle = (appeal) => appeal && appeal.veteran_first_name ?
    `${formatNameShort(appeal.veteran_first_name, appeal.veteran_last_name)}'s Claims Folder` :
    'Claims Folder | Caseflow Reader';

  render = () => <React.Fragment>
    <NavigationBar
      wideApp
      appName="Queue"
      logoProps={{
        accentColor: LOGO_COLORS.QUEUE.ACCENT,
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP
      }}
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      applicationUrls={this.props.applicationUrls}
      rightNavElement={<CaseSearchLink />}
      defaultUrl="/queue"
      outsideCurrentRouter>
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
          breadcrumb="Reader"
          path="/:vacolsId/documents"
          render={this.routedPdfListView} />
      </AppFrame>
    </NavigationBar>
    <Footer
      wideApp
      appName="Reader"
      feedbackUrl={this.props.feedbackUrl}
      buildDate={this.props.buildDate} />
  </React.Fragment>;
}

DecisionReviewer.propTypes = {
  annotations: PropTypes.any,
  appeal: PropTypes.any,
  appealDocuments: PropTypes.any,
  applicationUrls: PropTypes.any,
  buildDate: PropTypes.any,
  dropdownUrls: PropTypes.array,
  featureToggles: PropTypes.any,
  feedbackUrl: PropTypes.any,
  efolderExpressUrl: PropTypes.any,
  isPlacingAnnotation: PropTypes.any,
  onScrollToComment: PropTypes.func,
  setCategoryFilter: PropTypes.func,
  singleDocumentMode: PropTypes.bool,
  stopPlacingAnnotation: PropTypes.func,
  storeDocuments: PropTypes.any,
  userDisplayName: PropTypes.string
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
