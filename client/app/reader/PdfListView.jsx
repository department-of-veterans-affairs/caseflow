import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import _ from 'lodash';
import { clearSearch } from './actions';
import DocumentsTable from './DocumentsTable';

import { getFilteredDocuments } from './selectors';
import NoSearchResults from './NoSearchResults';

export class PdfListView extends React.Component {

  render() {
    const noDocuments = !_.size(this.props.documents) &&
      _.size(this.props.docFilterCriteria.searchQuery);

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <DocumentListHeader
            documents={this.props.documents}
            clearSearch={this.props.clearSearch}
            noDocuments={noDocuments}
          />
          <div>
            { noDocuments ?
            <NoSearchResults
              clearSearch={this.props.clearSearch}
              searchQuery={this.props.docFilterCriteria.searchQuery}
              /> :
            <DocumentsTable
              documents={this.props.documents}
              onJumpToComment={this.props.onJumpToComment}
              sortBy={this.props.sortBy}
              docFilterCriteria={this.props.docFilterCriteria}
              showPdf={this.props.showPdf}
            />}
          </div>
        </div>
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  documents: getFilteredDocuments(state),
  ..._.pick(state, 'tagOptions'),
  ..._.pick(state.ui, 'docFilterCriteria')
});

const mapDispatchToProps = (dispatch) => ({
  clearSearch() {
    dispatch(clearSearch());
  }
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(PdfListView);

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string
};
