import React, { PropTypes } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Route, BrowserRouter } from 'react-router-dom';

import PdfViewer from './PdfViewer';
import PdfListView from './PdfListView';
import AnnotationStorage from '../util/AnnotationStorage';
import ApiUtil from '../util/ApiUtil';
import * as ReaderActions from './actions';
import _ from 'lodash';

const PARALLEL_DOCUMENT_REQUESTS = 3;

export const documentPath = (id) => `/document/${id}/pdf`;

export class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isCommentLabelSelected: false
    };

    this.props.onReceiveDocs(this.props.appealDocuments);
    this.props.onReceiveAnnotations(this.props.annotations);

    this.annotationStorage = new AnnotationStorage(this.props.annotations);
    this.props.setAnnotationStorage(this.annotationStorage);
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.appealDocuments !== nextProps.appealDocuments) {
      this.props.onReceiveDocs(nextProps.appealDocuments);
    }

    if (this.props.annotations !== nextProps.annotations) {
      this.props.onReceiveAnnotations(nextProps.annotations);
    }
  }

  documentUrl = (doc) => {
    return `/document/${doc.id}/pdf`;
  }

  showPdf = (history, vacolsId) => (docId) => (event) => {
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

  componentDidMount = () => {
    let downloadDocuments = (documentUrls, index) => {
      if (index >= documentUrls.length) {
        return;
      }

      ApiUtil.get(documentUrls[index], { cache: true }).
        then(() => {
          downloadDocuments(documentUrls, index + PARALLEL_DOCUMENT_REQUESTS);
        });
    };

    for (let i = 0; i < PARALLEL_DOCUMENT_REQUESTS; i++) {
      downloadDocuments(this.props.appealDocuments.map((doc) => {
        return this.documentUrl(doc);
      }), i);
    }
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
    const vacolsId = routerProps.match.params.vacolsId;

    return <PdfListView
      documents={this.documents()}
      showPdf={this.showPdf(routerProps.history, vacolsId)}
      sortBy={this.state.sortBy}
      selectedLabels={this.state.selectedLabels}
      isCommentLabelSelected={this.state.isCommentLabelSelected}
      documentPathBase={`/reader/appeal/${vacolsId}/documents`}
      onJumpToComment={this.onJumpToComment(routerProps.history, vacolsId)}
      {...routerProps}
    />;
  }

  routedPdfViewer = (routerProps) => {
    const vacolsId = routerProps.match.params.vacolsId;

    return <PdfViewer
      addNewTag={this.props.addNewTag}
      removeTag={this.props.removeTag}
      showTagErrorMsg={this.props.ui.pdfSidebar.showTagErrorMsg}
      annotationStorage={this.annotationStorage}
      documents={this.documents()}
      allDocuments={_.values(this.props.storeDocuments)}
      pdfWorker={this.props.pdfWorker}
      onShowList={this.onShowList(routerProps.history, vacolsId)}
      showPdf={this.showPdf(routerProps.history, vacolsId)}
      onJumpToComment={this.onJumpToComment(routerProps.history, vacolsId)}
      onCommentScrolledTo={this.onCommentScrolledTo}
      documentPathBase={`/reader/appeal/${vacolsId}/documents`}
      {...routerProps}
    />;
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
  annotations: PropTypes.arrayOf(PropTypes.object),
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired,
  pdfWorker: PropTypes.string,
  onScrollToComment: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  setAnnotationStorage: PropTypes.func,
  handleSetLastRead: PropTypes.func.isRequired,

  // These two properties are exclusively for testing purposes
  router: PropTypes.func,
  routerProps: PropTypes.object
};

const mapStateToProps = (state) => {
  return {
    ui: {
      pdfSidebar: {
        showTagErrorMsg: state.ui.pdfSidebar.showTagErrorMsg
      }
    },
    documentFilters: state.ui.pdfList.filters,
    filteredDocIds: state.ui.filteredDocIds,
    storeDocuments: state.documents
  };
};

const mapDispatchToProps = (dispatch) => {
  return bindActionCreators(ReaderActions, dispatch);
};

export default connect(mapStateToProps, mapDispatchToProps)(DecisionReviewer);
