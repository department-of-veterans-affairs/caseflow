import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { ENDPOINT_NAMES } from './analytics';

import ApiUtil from '../util/ApiUtil';
import { setSearch, clearSearch, clearAllFilters } from '../reader/DocumentList/DocumentListActions';
import DocumentsCommentsButton from './DocumentsCommentsButton';
import HeaderFilterMessage from './HeaderFilterMessage';
import SearchBar from '../components/SearchBar';

class DocumentListHeader extends React.Component {
  // Record the search value for analytics purposes. Don't worry if it fails.
  recordSearch = (query) => {
    ApiUtil.post(
      `/reader/appeal/${this.props.vacolsId}/claims_folder_searches`,
      { data: { query } },
      ENDPOINT_NAMES.CLAIMS_FOLDER_SEARCHES
    ).
      then(() => {
        // no op
      }).
      catch((error) => {
        // we don't care reporting via Raven.
        console.error(error);
      });
  }

  render() {
    const props = this.props;

    return <div>
      <div className="document-list-header">
        <div className="search-bar-and-doc-count cf-search-ahead-parent">
          <SearchBar
            id="searchBar"
            onChange={props.setSearch}
            onClearSearch={props.clearSearch}
            recordSearch={this.recordSearch}
            isSearchAhead
            placeholder="Type to search..."
            value={props.docFilterCriteria.searchQuery}
            size="small"
          />
          <div className="num-of-documents">
            {props.numberOfDocuments} Documents
          </div>
        </div>
        <DocumentsCommentsButton />
      </div>
      <HeaderFilterMessage docFilterCriteria={props.docFilterCriteria} />
    </div>;
  }
}

DocumentListHeader.propTypes = {
  setSearch: PropTypes.func.isRequired,
  noDocuments: PropTypes.bool,
  clearAllFilters: PropTypes.func,
  clearSearch: PropTypes.func,
  docFilterCriteria: PropTypes.object,
  numberOfDocuments: PropTypes.number.isRequired,
  vacolsId: PropTypes.string
};

const mapStateToProps = (state) => ({
  numberOfDocuments: state.documentList.filteredDocIds ?
    state.documentList.filteredDocIds.length : _.size(state.documents),
  docFilterCriteria: state.documentList.docFilterCriteria,
  vacolsId: state.pdfViewer.loadedAppealId
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setSearch,
    clearSearch,
    clearAllFilters
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);
