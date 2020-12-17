import PropTypes from 'prop-types';
import * as React from 'react';
import { css } from 'glamor';
import _ from 'lodash';
import { DateString } from '../../util/DateUtil';

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

class FnodBadge extends React.PureComponent {
  render = () => {
    const { appeal } = this.props;
    
      //added a call here for testing purposes, actual logic to come later
      if (!appeal.veteran_is_deceased) {
        //commenting out the next line will make FNOD badge show everywhere
        //return null;
      }

      //left tooltip here but without data because the badge.jsx component is expecting a tooltip
      const tooltipText = <div>
        <strong>Date of Death Reported</strong>
        {/* <ul {...listStyling}>
          <li><strong>Source: </strong>BGS</li>
          <li><strong>Date of Death: </strong></li>
          <li><strong>Reported on: </strong></li>
        </ul> */}
      </div>;

      return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={appeal.id} />;
  }
}

FnodBadge.propTypes = {
  appeal: PropTypes.object
};

export default FnodBadge;
