import React from 'react';
import { connect } from 'react-redux';

import NonCompTabs from '../components/NonCompTabs';
import Button from '../../components/Button';
import Link from '../../components/Link';
import { SuccessAlert } from '../components/Alerts';
import { LeftChevronIcon } from 'app/components/icons/LeftChevronIcon';
import { ClockIcon } from 'app/components/icons/ClockIcon';

import { DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import NonCompLayout from '../components/NonCompLayout';
import { ICON_SIZES, COLORS } from 'app/constants/AppConstants';

const NonCompSavedSearches = (props) => {

  const BACK_LINK_TEXT = 'Back to Generate task report';

  return (
    <div className="saved-search-content-spacing">
      <div className="saved-search-back-link">
        <Link to=".">
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

NonCompSavedSearches.propTypes = {
};

const SavedSearches = connect(
  (state) => ({
    isBusinessLineAdmin: state.nonComp.isBusinessLineAdmin,
    businessLine: state.nonComp.businessLine,
    canGenerateClaimHistory: state.nonComp.businessLineConfig.canGenerateClaimHistory,
    decisionIssuesStatus: state.nonComp.decisionIssuesStatus,
    businessLineUrl: state.nonComp.businessLineUrl
  })
)(NonCompSavedSearches);

export default SavedSearches;
