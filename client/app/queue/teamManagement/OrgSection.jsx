import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

const tableStyling = css({
  width: '100%',
  '& td': { border: 'none' },
  '& input': { margin: 0 }
});

const divStyling = css({
  borderBottom: '1px solid #d6d7d9'
});

export const OrgSection = ({ children }) => {

  return (
    <div {...divStyling}>
      <table {...tableStyling}>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
};

OrgSection.propTypes = {
  children: PropTypes.node
};
