import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { ENDPOINT_NAMES } from './analytics';
import WellArea from '../components/WellArea';

import ApiUtil from '../util/ApiUtil';
// eslint-disable-next-line max-len
import { setSearch, clearSearch, clearAllFilters, setClaimEvidenceDocs, clearClaimEvidenceDocs } from '../reader/DocumentList/DocumentListActions';
import DocumentsCommentsButton from './DocumentsCommentsButton';
import HeaderFilterMessage from './HeaderFilterMessage';
import SearchBar from '../components/SearchBar';
import FetchSearchBar from '../components/FetchSearchBar';

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
      <div style={{ paddingBottom: '30px' }}>
        <WellArea>
          <FetchSearchBar
            setClearAllFiltersCallbacks={this.props.setClearAllFiltersCallbacks}
            clearAllFiltersCallbacks={this.props.clearAllFiltersCallbacks}
            vacolsId = {this.props.vacolsId}
            clearClaimEvidenceDocs={this.props.clearClaimEvidenceDocs}
            setClaimEvidenceDocs = {this.props.setClaimEvidenceDocs}
          />
        </WellArea>
      </div>
      <div className="document-list-header" style={{ display: 'grid', justifyContent: 'right' }}>
        <div>
          <DocumentsCommentsButton />
        </div>
        <div className="search-bar-and-doc-count cf-search-ahead-parent" style={{ paddingTop: '20px', width: '85vw' }}>
          <div className="num-of-documents" style={{ justifyContent: 'left', paddingLeft: '80px', paddingTop: '7rem', paddingBottom: '0rem'}}>
            Showing {props.numberOfDocuments} Documents
          </div>
          <div className="table-search-bar">
            <ul style={{ paddingLeft: '0px'}}>
            Filter table by receipt date, document type, issue tags, or comments
            </ul>
            <SearchBar
              id="searchBar"
              onChange={props.setSearch}
              isSearchAhead
              onClearSearch={props.clearSearch}
              recordSearch={this.recordSearch}
              placeholder="Type to search..."
              value={props.docFilterCriteria.searchQuery}
              size="small"
            />
          </div>
        </div>
      </div>
      <HeaderFilterMessage
        docFilterCriteria={props.docFilterCriteria}
        clearAllFiltersCallbacks={props.clearAllFiltersCallbacks}
      />
    </div>;
  }
}

DocumentListHeader.propTypes = {
  setSearch: PropTypes.func.isRequired,
  noDocuments: PropTypes.bool,
  clearAllFilters: PropTypes.func,
  setClaimEvidenceDocs: PropTypes.func.isRequired,
  clearClaimEvidenceDocs: PropTypes.func.isRequired,
  clearSearch: PropTypes.func,
  docFilterCriteria: PropTypes.object,
  numberOfDocuments: PropTypes.number.isRequired,
  vacolsId: PropTypes.string,
  clearAllFiltersCallbacks: PropTypes.array.isRequired,
  setClearAllFiltersCallbacks: PropTypes.func.isRequired
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
    clearAllFilters,
    setClaimEvidenceDocs,
    clearClaimEvidenceDocs
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentListHeader);
