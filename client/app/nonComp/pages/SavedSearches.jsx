import React from 'react';
import { connect, useSelector } from 'react-redux';

import Link from '../../components/Link';
import { LeftChevronIcon } from 'app/components/icons/LeftChevronIcon';

import PropTypes from 'prop-types';

import NonCompLayout from '../components/NonCompLayout';
import { COLORS } from 'app/constants/AppConstants';

const SavedSearches = () => {

  const BACK_LINK_TEXT = 'Back to Generate task report';
  const businessLineUrl = useSelector((state) => state.nonComp.businessLineUrl);

  return (
    <div className="saved-search-content-spacing">
      <div className="saved-search-back-link">
        <Link to={`/${businessLineUrl}/report`}>
          <div className="saved-search-link-text">
            <LeftChevronIcon size={21} color={COLORS.PRIMARY} />&nbsp;<b>{BACK_LINK_TEXT}</b>
          </div>
        </Link>
      </div>

      <NonCompLayout >
        <h1>Saved Searches</h1>
      Select a search you previously saved or look for ones others have saved by switching between the tabs.
      </NonCompLayout>
    </div>

  );
};

SavedSearches.propTypes = {
};

export default SavedSearches;
