import React from 'react';
import { useSelector } from 'react-redux';

import Link from 'app/components/Link';
import { LeftChevronIcon } from 'app/components/icons/LeftChevronIcon';

import NonCompLayout from '../components/NonCompLayout';
import { COLORS } from 'app/constants/AppConstants';
import SAVED_SEARCHES_COPY from 'constants/SAVED_SEARCHES_COPY';
import TabWindow from 'app/components/TabWindow';
import SearchTable from 'app/queue/components/SearchTable';
import savedSearchesData from 'test/data/nonComp/savedSearchesData';

const SavedSearches = () => {

  const businessLineUrl = useSelector((state) => state.nonComp.businessLineUrl);
  const currentUserCssId = useSelector((state) => state.nonComp.currentUserCssId);

  const ALL_TABS = [
    {
      key: 'my_saved',
      label: 'My saved searches',
      // this section will later changed to backend call
      page: <SearchTable
        eventRows={savedSearchesData.savedSearches.all.filter((rows) => rows.userCssId === currentUserCssId)}
        searchPageApiEndPoint
      />
    },
    {
      key: 'all_saved',
      label: 'All saved searches',
      page: <SearchTable
        eventRows={savedSearchesData.savedSearches.all}
        searchPageApiEndPoint
      />
    }
  ];

  return (
    <div className="saved-search-content-spacing">
      <div className="saved-search-back-link">
        <Link to={`/${businessLineUrl}/report`}>
          <div className="saved-search-link-text">
            <LeftChevronIcon size={21} color={COLORS.PRIMARY} />&nbsp;<b>{SAVED_SEARCHES_COPY.BACK_LINK_TEXT}</b>
          </div>
        </Link>
      </div>

      <NonCompLayout>
        <h1>Saved Searches</h1>
        <div>
          Select a search you previously saved or look for ones others have saved by switching between the tabs.
        </div>
        <TabWindow name="saved-search-queue" tabs={ALL_TABS} />
      </NonCompLayout>
    </div>

  );
};

export default SavedSearches;
