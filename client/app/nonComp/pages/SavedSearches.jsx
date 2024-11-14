import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import Alert from 'app/components/Alert';
import Link from 'app/components/Link';
import { LeftChevronIcon } from 'app/components/icons/LeftChevronIcon';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';
import { COLORS } from 'app/constants/AppConstants';
import SAVED_SEARCHES_COPY from 'constants/SAVED_SEARCHES_COPY';
import TabWindow from 'app/components/TabWindow';
import SearchTable from 'app/queue/components/SearchTable';
import DeleteModal from 'app/nonComp/components/DeleteModal';
import { fetchedSearches, selectSavedSearch } from '../../nonComp/actions/savedSearchSlice';
import { isEmpty } from 'lodash';

const SavedSearches = () => {
  const businessLineUrl = useSelector((state) => state.nonComp.businessLineUrl);
  const savedSearchRows = useSelector((state) => state.savedSearch.fetchedSearches);
  const selectedSearch = useSelector((state) => state.savedSearch.selectedSearch);
  const saveSearchStatus = useSelector((state) => state.savedSearch.status);
  const deleteSearchDescription = useSelector((state) => state.savedSearch.message);

  const userSearches = savedSearchRows.userSearches;
  const allSearches = savedSearchRows.allSearches;

  const isDisabled = isEmpty(selectedSearch);
  const [selectedTab, setSelectedTab] = useState(0);
  const [showDeleteModal, setShowDeleteModal] = useState(false);

  const dispatch = useDispatch();

  const handleApply = () => {
    // this will come from another story.
  };

  const buttonStyling = {
    float: 'right',
    marginTop: '20px',
    display: 'flex',
    justifyContent: 'space-between',
    gap: '2em'
  };

  useEffect(() => {
    dispatch(fetchedSearches({ organizationUrl: businessLineUrl }));
  }, []);

  const ALL_TABS = [
    {
      key: 'my_saved_searches',
      label: 'My saved searches',
      page: <SearchTable
        eventRows={userSearches}
      />
    },
    {
      key: 'all_saved_searches',
      label: 'All saved searches',
      page: <SearchTable
        eventRows={allSearches}
      />
    }
  ];

  const onTabSelected = (tabNumber) => {
    setSelectedTab(tabNumber);
    dispatch(selectSavedSearch({}));
  };

  return (
    <div className="saved-search-content-spacing">
      { saveSearchStatus === 'succeeded' ?
        <Alert
          type="success"
          title={deleteSearchDescription}
          scrollOnAlert /> :
        null
      }
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
        <TabWindow name="saved-search-queue" tabs={ALL_TABS} onChange={onTabSelected} />
      </NonCompLayout>
      { showDeleteModal ? <DeleteModal setShowDeleteModal={setShowDeleteModal} /> : null }
      <div style = {buttonStyling}>
        { (selectedTab === 0) ? <Button
          label="delete"
          name="delete"
          onClick={() => setShowDeleteModal(true)}
          disabled={isDisabled}
        >
           Delete
        </Button> : null }
        <Button
          label="apply"
          name="apply"
          onClick={()=> handleApply()}
          disabled={isDisabled}
        >
           Apply
        </Button>
      </div>
    </div>

  );
};

export default SavedSearches;
