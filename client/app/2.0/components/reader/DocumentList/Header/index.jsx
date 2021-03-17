// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

// Local Dependencies
import { setSearch, clearSearch } from 'app/reader/DocumentList/DocumentListActions';
import { recordSearch } from 'utils/search';

// Additional Components
import SearchBar from 'app/components/SearchBar';
import { ToggleViewButton } from 'components/reader/DocumentList/Header/ToggleViewButton';
import { FilterMessage } from 'components/reader/DocumentList/Header/FilterMessage';

/**
 * Document List Header Component
 * @param {Object} props -- React props include the appeal ID and filter criteria
 */
export const DocumentListHeader = ({ loadedAppealId, docFilterCriteria, documentList, documents }) => {
  // Create the Dispatcher
  const dispatch = useDispatch();

  // Calculate the number of documents
  const numberOfDocuments = documentList.filteredDocIds ? documentList.filteredDocIds.length : documents.length;

  return (
    <div>
      <div className="document-list-header">
        <div className="search-bar-and-doc-count cf-search-ahead-parent">
          <SearchBar
            id="searchBar"
            onChange={(value) => dispatch(setSearch(value))}
            onClearSearch={() => dispatch(clearSearch())}
            recordSearch={(query) => dispatch(recordSearch(loadedAppealId, query))}
            isSearchAhead
            placeholder="Type to search..."
            value={docFilterCriteria.searchQuery}
            size="small"
            analyticsCategory="Claims Folder"
          />
          <div className="num-of-documents">
            {numberOfDocuments} Documents
          </div>
        </div>
        <ToggleViewButton />
      </div>
      <FilterMessage docFilterCriteria={docFilterCriteria} />
    </div>
  );
};

DocumentListHeader.propTypes = {
  loadedAppealId: PropTypes.string,
  docFilterCriteria: PropTypes.object,
  documents: PropTypes.array,
  documentList: PropTypes.object
};
