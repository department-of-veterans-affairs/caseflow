import { after, css, merge } from 'glamor';
import React from 'react';
import PropTypes from 'prop-types';

import { COLORS } from '../../constants/AppConstants';

const definitionListStyling = css({
  margin: '0',
  '& dt': merge(
    after({ content: ':' }),
    {
      color: COLORS.GREY_MEDIUM,
      float: 'left',
      fontSize: '1.5rem',
      marginRight: '0.5rem',
      textTransform: 'uppercase'
    }
  )
});

const CaseDetailsDescriptionList = (props) => <dl {...definitionListStyling}>{props.children}</dl>;

CaseDetailsDescriptionList.propTypes = {
  children: PropTypes.node
};

export default CaseDetailsDescriptionList;
