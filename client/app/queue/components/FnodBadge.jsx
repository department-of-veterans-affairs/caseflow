import PropTypes from 'prop-types';
import * as React from 'react';
import { css } from 'glamor';

import { COLORS } from '../../constants/AppConstants';
import Badge from './Badge';
import { setFeatureToggles } from '../uiReducer/uiActions';


/**
 * Component to display a FNOD badge if Veteran.date_of_death is not null and 
 * the Veteran is the appellant.
 */

const listStyling = css({
  listStyle: 'none',
  textAlign: 'left',
  marginBottom: 0,
  padding: 0,
  '& > li': {
    marginBottom: 0,
    '& > strong': {
      color: COLORS.WHITE
    }
  }
});

const FnodBadge = (props) => {
  const { appeal } = props;

  if (!appeal.veteran_appellant_deceased) {
    return null
  }

  const tooltipText = <div>
    <strong>First Notice of Death</strong>
    <ul {...listStyling}>
      <li><strong>Source: </strong>BGS</li>
      <li><strong>Date of Death: </strong>{appeal.date_of_death}</li>
    </ul>
  </div>;

  return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={`fnod-${appeal.id}`} />;
};

FnodBadge.propTypes = {
  appeal: PropTypes.object
};

export default FnodBadge;
