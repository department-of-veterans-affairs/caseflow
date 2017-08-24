import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import ClaimsFolderDetails from './ClaimsFolderDetails';
import { fetchAppealDetails } from './actions';
import { shouldFetchAppeal } from '../reader/utils';

import _ from 'lodash';
import DocumentsTable from './DocumentsTable';

import { getFilteredDocuments } from './selectors';
import NoSearchResults from './NoSearchResults';

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
    }
  }

  render() {
    const noDocuments = !_.size(this.props.documents) && _.size(this.props.docFilterCriteria.searchQuery) > 0;

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <ClaimsFolderDetails appeal={this.props.appeal} documents={this.props.documents}/>
          <DocumentListHeader
            documents={this.props.documents}
            noDocuments={noDocuments}
          />
          { noDocuments ?
          <NoSearchResults /> :
          <DocumentsTable
            documents={this.props.documents}
            documentPathBase={this.props.documentPathBase}
            onJumpToComment={this.props.onJumpToComment}
            sortBy={this.props.sortBy}
            docFilterCriteria={this.props.docFilterCriteria}
            showPdf={this.props.showPdf}
          />}
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state, props) => {
  return { documents: getFilteredDocuments(state),
    ..._.pick(state.ui, 'docFilterCriteria'),
    appeal: _.find(state.assignments, { vacols_id: props.match.params.vacolsId }) ||
      state.loadedAppeal,
    caseSelectedAppeal: state.ui.caseSelect.selectedAppeal
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    fetchAppealDetails
  }, dispatch)
);

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfListView);

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string
};
