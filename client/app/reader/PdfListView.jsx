import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import BackToQueueLink from './BackToQueueLink';
import LastRetrievalAlert from './LastRetrievalAlert';
import LastRetrievalInfo from './LastRetrievalInfo';
import BandwidthAlert from './BandwidthAlert';
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
import { SizeWarningIcon } from '../components/icons/SizeWarningIcon';

export class PdfListView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      clearAllFiltersCallbacks: [],
    };
  }

  setClearAllFiltersCallbacks = (callbacks) => {
    this.setState((prevState) => ({
      clearAllFiltersCallbacks: [...prevState.clearAllFiltersCallbacks, ...callbacks],
    }));
  };

  componentDidMount() {
    const { appeal, match, caseSelectedAppeal, fetchAppealDetails, onReceiveAppealDetails } = this.props;

    if (shouldFetchAppeal(appeal, match.params.vacolsId)) {
      if (caseSelectedAppeal && caseSelectedAppeal.vacols_id === match.params.vacolsId) {
        onReceiveAppealDetails(caseSelectedAppeal);
      } else {
        fetchAppealDetails(match.params.vacolsId);
      }
    } else if (appeal?.vacols_id === match.params.vacolsId) {
      onReceiveAppealDetails(appeal);
    }
  }

  render() {
    const { documents, docFilterCriteria, viewingDocumentsOrComments, featureToggles } = this.props;
    const noDocuments = !_.size(documents) && _.size(docFilterCriteria?.searchQuery) > 0;

    let tableView;
    if (noDocuments) {
      tableView = <NoSearchResults />;
    } else if (viewingDocumentsOrComments === DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS) {
      tableView = <CommentsTable {...this.props} />;
    } else {
      tableView = <DocumentsTable {...this.props} setClearAllFiltersCallbacks={this.setClearAllFiltersCallbacks} />;
    }

    return (
      <div>
        {this.props.queueRedirectUrl && (
          <BackToQueueLink
            queueRedirectUrl={this.props.queueRedirectUrl}
            queueTaskType={this.props.queueTaskType}
            veteranFullName={this.props.appeal?.veteran_full_name}
            vbmsId={this.props.appeal?.vbms_id}
          />
        )}
        {featureToggles?.isWarningIconAndBannerEnabled && (
          <SizeWarningIcon size={32} className="size-warning-icon" />
        )}
        <LastRetrievalAlert {...this.props} />
        <AppSegment filledBackground>
          <div className="section--document-list">
            <ClaimsFolderDetails {...this.props} />
            {featureToggles?.bandwidthBanner && <BandwidthAlert />}
            <DocumentListHeader
              documents={documents}
              noDocuments={noDocuments}
              clearAllFiltersCallbacks={this.state.clearAllFiltersCallbacks}
            />
            {tableView}
          </div>
        </AppSegment>
        <LastRetrievalInfo {...this.props} />
      </div>
    );
  }
}

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string,
  appeal: PropTypes.object,
  efolderExpressUrl: PropTypes.string,
  userHasEfolderRole: PropTypes.bool,
  featureToggles: PropTypes.object,
  match: PropTypes.object.isRequired,
  caseSelectedAppeal: PropTypes.object,
  onReceiveAppealDetails: PropTypes.func.isRequired,
  fetchAppealDetails: PropTypes.func.isRequired,
  docFilterCriteria: PropTypes.object,
  viewingDocumentsOrComments: PropTypes.oneOf(Object.values(DOCUMENTS_OR_COMMENTS_ENUM)),
  documentPathBase: PropTypes.string,
  showPdf: PropTypes.func,
  queueRedirectUrl: PropTypes.string,
  queueTaskType: PropTypes.node,
  readerPreferences: PropTypes.object,
};

const mapStateToProps = (state, props) => ({
  documents: getFilteredDocuments(state),
  ..._.pick(state.documentList, 'docFilterCriteria', 'viewingDocumentsOrComments'),
  appeal: _.find(state.caseSelect.assignments, { vacols_id: props.match.params.vacolsId }) || state.pdfViewer.loadedAppeal,
  caseSelectedAppeal: state.caseSelect.selectedAppeal,
  queueRedirectUrl: state.documentList.queueRedirectUrl,
  queueTaskType: state.documentList.queueTaskType,
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      onReceiveAppealDetails,
      fetchAppealDetails,
    },
    dispatch
  );

export default connect(mapStateToProps, mapDispatchToProps)(PdfListView);
