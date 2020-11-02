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
export const DocumentListHeader = ({ filterCriteria, filteredDocIds, documents, search, clearSearch, recordSearch, ...props }) => {
  // Calculate the number of documents
  const numberOfDocuments = filteredDocIds ? filteredDocIds.length : documents.length;

  return (
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
            {numberOfDocuments} Documents
          </div>
        </div>
        <ToggleViewButton {...props} />
      </div>
      <FilterMessage filterCriteria={filterCriteria} />
    </div>
  );
};

DocumentListHeader.propTypes = {
  loadedAppealId: PropTypes.string,
  filterCriteria: PropTypes.object,
  documents: PropTypes.array,
  filteredDocIds: PropTypes.object,
  clearSearch: PropTypes.func,
  recordSearch: PropTypes.func,
  search: PropTypes.func
};
