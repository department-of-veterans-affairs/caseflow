import React, { PropTypes } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import PdfViewer from './PdfViewer';
import PdfListView from './PdfListView';
import AnnotationStorage from '../util/AnnotationStorage';
import ApiUtil from '../util/ApiUtil';
import * as ReaderActions from './actions';
import _ from 'lodash';

const PARALLEL_DOCUMENT_REQUESTS = 3;

export class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isCommentLabelSelected: false
    };

    this.props.onReceiveDocs(this.props.appealDocuments);

    this.annotationStorage = new AnnotationStorage(this.props.annotations);
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.appealDocuments !== nextProps.appealDocuments) {
      this.props.onReceiveDocs(nextProps.appealDocuments);
    }
  }

  documentUrl = (doc) => {
    return `/document/${doc.id}/pdf`;
  }

  showPdf = (pdfId) => (event) => {
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
        this.props.handleSetLastRead(pdfId)
      );

      return true;
    }

    event.preventDefault();
    this.props.selectCurrentPdf(pdfId);
  }

  onShowList = () => {
    this.props.unselectPdf();
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

  selectComments = () => {
    this.setState({
      isCommentLabelSelected: !this.state.isCommentLabelSelected
    });
  }

  onJumpToComment = (comment) => () => {
    this.props.selectCurrentPdf(comment.documentId);
    this.props.onScrollToComment(comment);
  }

  onCommentScrolledTo = () => {
    this.props.onScrollToComment(null);
  }

  render() {
    const documents = this.props.filteredDocIds ?
      _.map(this.props.filteredDocIds, (docId) => this.props.storeDocuments[docId]) :
      _.values(this.props.storeDocuments);
    const shouldRenderPdf = this.props.currentRenderedFile !== null;

    const activeDocIndex = _.findIndex(documents, { id: this.props.currentRenderedFile });
    const activeDoc = documents[activeDocIndex];

    const nextDocExists = activeDocIndex + 1 < _.size(documents);
    const nextDocId = nextDocExists && documents[activeDocIndex + 1].id;

    const previousDocExists = activeDocIndex > 0;
    const prevDocId = previousDocExists && documents[activeDocIndex - 1].id;

    return (
      <div className="section--document-list">
        {!shouldRenderPdf && <PdfListView
          annotationStorage={this.annotationStorage}
          documents={documents}
          showPdf={this.showPdf}
          sortBy={this.state.sortBy}
          selectedLabels={this.state.selectedLabels}
          selectComments={this.selectComments}
          isCommentLabelSelected={this.state.isCommentLabelSelected}
          onJumpToComment={this.onJumpToComment} />}
        {shouldRenderPdf && <PdfViewer
          addNewTag={this.props.addNewTag}
          removeTag={this.props.removeTag}
          showTagErrorMsg={this.props.ui.pdfSidebar.showTagErrorMsg}
          annotationStorage={this.annotationStorage}
          file={this.documentUrl(activeDoc)}
          doc={activeDoc}
          nextDocId={nextDocId}
          prevDocId={prevDocId}
          onShowList={this.onShowList}
          pdfWorker={this.props.pdfWorker}
          onJumpToComment={this.onJumpToComment}
          onCommentScrolledTo={this.onCommentScrolledTo} />}
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  annotations: PropTypes.arrayOf(PropTypes.object),
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired,
  pdfWorker: PropTypes.string,
  onScrollToComment: PropTypes.func,
  onCommentScrolledTo: PropTypes.func,
  handleSetLastRead: PropTypes.func.isRequired
};

const mapStateToProps = (state) => {
  return {
    ui: {
      pdfSidebar: {
        showTagErrorMsg: state.ui.pdfSidebar.showTagErrorMsg
      }
    },
    currentRenderedFile: state.ui.pdf.currentRenderedFile,
    documentFilters: state.ui.pdfList.filters,
    filteredDocIds: state.ui.filteredDocIds,
    storeDocuments: state.documents
  };
};

const mapDispatchToProps = (dispatch) => {
  return bindActionCreators(ReaderActions, dispatch);
};

export default connect(mapStateToProps, mapDispatchToProps)(DecisionReviewer);
