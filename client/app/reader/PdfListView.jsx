import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import BackToQueueLink from './BackToQueueLink';
import LastRetrievalAlert from './LastRetrievalAlert';
import LastRetrievalInfo from './LastRetrievalInfo';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import DocumentListHeader from './DocumentListHeader';
import ClaimsFolderDetails from './ClaimsFolderDetails';
import DocumentsTable from './DocumentsTable';
import CommentsTable from './CommentsTable';
import { getFilteredDocuments } from './selectors';
import NoSearchResults from './NoSearchResults';
import { fetchAppealDetails, onReceiveAppealDetails } from '../reader/PdfViewer/PdfViewerActions';
import { shouldFetchAppeal } from '../reader/utils';
import { DOCUMENTS_OR_COMMENTS_ENUM } from './DocumentList/actionTypes';

export class PdfListView extends React.Component {
  componentDidMount() {
    if (shouldFetchAppeal(this.props.appeal, this.props.match.params.vacolsId)) {
      // if the appeal is fetched through case selected appeals, re-use that existing appeal
      // information.
      if (this.props.caseSelectedAppeal &&
        (this.props.caseSelectedAppeal.vacols_id === this.props.match.params.vacolsId)) {
        this.props.onReceiveAppealDetails(this.props.caseSelectedAppeal);
      } else {
        this.props.fetchAppealDetails(this.props.match.params.vacolsId);
      }

      // if appeal is loaded from the assignments and it matches the vacols id
      // in the url
    } else if (this.props.appeal.vacols_id === this.props.match.params.vacolsId) {
      this.props.onReceiveAppealDetails(this.props.appeal);
    }
  }

  render() {
    const noDocuments = !_.size(this.props.documents) && _.size(this.props.docFilterCriteria.searchQuery) > 0;
    let tableView;

    if (noDocuments) {
      tableView = <NoSearchResults />;
    } else if (this.props.viewingDocumentsOrComments === DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS) {
      tableView = <CommentsTable
        documents={this.props.documents}
        onJumpToComment={this.props.onJumpToComment}
      />;
    } else {
      tableView = <DocumentsTable
        documents={this.props.documents}
        documentPathBase={this.props.documentPathBase}
        onJumpToComment={this.props.onJumpToComment}
        sortBy={this.props.sortBy}
        docFilterCriteria={this.props.docFilterCriteria}
        showPdf={this.props.showPdf}
      />;
    }

    return <div>
      {this.props.queueRedirectUrl && <BackToQueueLink
        queueRedirectUrl={this.props.queueRedirectUrl}
        queueTaskType={this.props.queueTaskType}
        veteranFullName={this.props.appeal.veteran_full_name}
        vbmsId={this.props.appeal.vbms_id} />}
      <AppSegment filledBackground>
        <div className="section--document-list">
          <ClaimsFolderDetails appeal={this.props.appeal} documents={this.props.documents} />
          <LastRetrievalAlert efolderExpressUrl={this.props.efolderExpressUrl} appeal={this.props.appeal} />
          <DocumentListHeader
            documents={this.props.documents}
            noDocuments={noDocuments}
          />
          {tableView}
        </div>
      </AppSegment>
      <LastRetrievalInfo appeal={this.props.appeal} />
    </div>;
  }
}

const mapStateToProps = (state, props) => {
  return {
    documents: getFilteredDocuments(state),
    ..._.pick(state.documentList, 'docFilterCriteria', 'viewingDocumentsOrComments'),
    appeal: _.find(state.caseSelect.assignments, { vacols_id: props.match.params.vacolsId }) ||
      state.pdfViewer.loadedAppeal,
    caseSelectedAppeal: state.caseSelect.selectedAppeal,
    manifestVbmsFetchedAt: state.documentList.manifestVbmsFetchedAt,
    manifestVvaFetchedAt: state.documentList.manifestVvaFetchedAt,
    queueRedirectUrl: state.documentList.queueRedirectUrl,
    queueTaskType: state.documentList.queueTaskType
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    onReceiveAppealDetails,
    fetchAppealDetails
  }, dispatch)
);

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfListView);

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  efolderExpressUrl: PropTypes.string,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string,
  appeal: PropTypes.object,
};
