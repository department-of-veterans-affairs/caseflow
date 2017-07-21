import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import ClaimsFolderDetails from './ClaimsFolderDetails';
import { fetchAppealDetails } from './actions';

import _ from 'lodash';
import DocumentsTable from './DocumentsTable';

import { getFilteredDocuments } from './selectors';
import NoSearchResults from './NoSearchResults';

export class PdfListView extends React.Component {
  componentDidMount() {
    if (_.isEmpty(this.props.appeal) ||
      (this.props.appeal.vacols_id !== this.props.match.params.vacolsId)) {
      this.props.fetchAppealDetails(this.props.match.params.vacolsId);
    }
  }

  render() {
    const noDocuments = !_.size(this.props.documents) && _.size(this.props.docFilterCriteria.searchQuery) > 0;

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <ClaimsFolderDetails appeal={this.props.appeal}/>
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
    state.loadedAppeal
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
