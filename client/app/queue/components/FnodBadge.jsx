import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';

import { COLORS } from '../../constants/AppConstants';
import Badge from './Badge';

/**
 * Component to display a FNOD badge if Veteran.date_of_death is not null and 
 * the Veteran is the appellant.
 */

class FnodBadge extends React.PureComponent {
  render = () => {
    const appeal = this.props;

    // if (!appeal.overtime || !canViewOvertimeStatus) {
    //   return null;
    // }

    // if (!fnod) {
    //   return null;
    // }

    const tooltipText = <div>
      First Notice of Death
      <ul {...listStyling}>
        <li>Source: <strong>BGS</strong></li>
        {/* <li>Date of Death: <strong>DateString date=(veteran.date_of_death)</strong></li> */}
      </ul>
    </div>;
    
    //will need to modify this line for fnod
    return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={appeal.id} />;
  }
}

FnodBadge.propTypes = {
  appeal: PropTypes.object,
  task: PropTypes.object
};
