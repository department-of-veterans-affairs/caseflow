// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Additional Components
import SearchBar from 'app/components/SearchBar';
import { ToggleViewButton } from 'components/reader/DocumentList/Header/ToggleViewButton';
import { FilterMessage } from 'components/reader/DocumentList/Header/FilterMessage';

/**
 * Document List Header Component
 * @param {Object} props -- React props include the appeal ID and filter criteria
 */
export const DocumentListHeader = ({ filterCriteria, docsCount, search, clearSearch, recordSearch, ...props }) => (
  <div>
    <div className="document-list-header">
      <div className="search-bar-and-doc-count cf-search-ahead-parent">
        <SearchBar
          id="searchBar"
          onChange={search}
          onClearSearch={clearSearch}
          recordSearch={recordSearch}
          isSearchAhead
          placeholder="Type to search..."
          value={filterCriteria.searchQuery}
          size="small"
          analyticsCategory="Claims Folder"
        />
        <div className="num-of-documents">
          {docsCount} Documents
        </div>
      </div>
      <ToggleViewButton {...props} />
    </div>
    <FilterMessage filterCriteria={filterCriteria} {...props} />
  </div>
);

DocumentListHeader.propTypes = {
  filterCriteria: PropTypes.object,
  documents: PropTypes.object,
  docsCount: PropTypes.number,
  clearSearch: PropTypes.func,
  recordSearch: PropTypes.func,
  search: PropTypes.func
};
