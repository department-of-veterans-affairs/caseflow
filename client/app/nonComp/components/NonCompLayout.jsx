import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

const NonCompLayout = ({ buttons, children }) => {
  return (
    <div>
      <AppSegment filledBackground>
        <div>
          {children}
        </div>
      </AppSegment>
      {buttons ? buttons : null}
    </div>
  );
};

NonCompLayout.propTypes = {
  buttons: PropTypes.node,
  children: PropTypes.node,
};

export default NonCompLayout;
