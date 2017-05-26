import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import DocumentListHeader from '../components/reader/DocumentListHeader';
import _ from 'lodash';
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
            noDocuments={noDocuments}
          />
          { noDocuments ?
          <NoSearchResults /> :
          <DocumentsTable
            documents={this.props.documents}
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

const mapStateToProps = (state) => ({
  documents: getFilteredDocuments(state),
  ..._.pick(state.ui, 'docFilterCriteria')
});

export default connect(
  mapStateToProps, null
)(PdfListView);

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  onJumpToComment: PropTypes.func,
  sortBy: PropTypes.string
};
