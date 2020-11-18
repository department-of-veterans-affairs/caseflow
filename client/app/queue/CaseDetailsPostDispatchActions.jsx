import React from 'react';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';

import COPY from '../../COPY';
import Button from '../components/Button';

const containerStyling = css({
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderRadius: '.4rem',
  padding: '1.5rem 4rem 2.75rem',
  marginTop: '2rem!important',
  boxShadow: `0 8px 6px -6px ${COLORS.GREY_LIGHT}`
});

const titleStyling = css({
  marginBottom: '1.25rem'
});

/**
 *
 * @param {Object} props
 *  - @param {string} appealId The external id of the dispatched appeal we are taking action on
 *  - @param {Object} history  Provided with react router to be able to route to another page
 */
const CaseDetailsPostDispatchActions = (props) => {

  const routeToCavcRemand = () => {
    const { history, appealId } = props;

    history.push(`/queue/appeals/${appealId}/add_cavc_remand`);
  };

  return (
    <div {...containerStyling}>
      <h2 {...titleStyling}>{COPY.POST_DISPATCH_TITLE}</h2>
      <Button name={COPY.ADD_CAVC_BUTTON} onClick={routeToCavcRemand} />
    </div>
  );
};

CaseDetailsPostDispatchActions.propTypes = {
  appealId: PropTypes.string.isRequired,
  history: PropTypes.object
};

export default withRouter(
  (CaseDetailsPostDispatchActions)
);
