import React from 'react';
import { useHistory } from 'react-router-dom';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { COLORS } from 'app/constants/AppConstants';

import COPY from 'app/../COPY';
import Button from 'app/components/Button';

const containerStyling = css({
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderRadius: '.4rem',
  padding: '1.5rem 4rem 2.75rem',
  marginTop: '2rem!important',
  boxShadow: `0 8px 6px -6px ${COLORS.GREY_LIGHT}`,
});

const titleStyling = css({
  marginBottom: '1.25rem',
});

const buttonContainer = css({
  '& > *:not(:last-child)': {
    marginRight: '2rem',
  },
});

/**
 *
 * @param {Object} props
 *  - @param {string} appealId The external id of the dispatched appeal we are taking action on
 *  - @param {Object} history  Provided with react router to be able to route to another page
 */
export const CaseDetailsPostDispatchActions = (props) => {
  const { appealId, includeCavcRemand, includeSubstitute } = props;
  const { push } = useHistory();

  return (
    <div {...containerStyling}>
      <h2 {...titleStyling}>{COPY.POST_DISPATCH_TITLE}</h2>
      <div className={buttonContainer}>
        {includeCavcRemand && (
          <Button
            name={COPY.ADD_CAVC_BUTTON}
            onClick={() => push(`/queue/appeals/${appealId}/add_cavc_remand`)}
          />
        )}

        {includeSubstitute && (
          <Button
            onClick={() =>
              push(`/queue/appeals/${appealId}/substitute_appellant`)
            }
          >
            {COPY.SUBSTITUTE_APPELLANT_BUTTON}
          </Button>
        )}
      </div>
    </div>
  );
};

CaseDetailsPostDispatchActions.propTypes = {
  appealId: PropTypes.string.isRequired,
  includeCavcRemand: PropTypes.bool,
  includeSubstitute: PropTypes.bool,
};

export default CaseDetailsPostDispatchActions;
