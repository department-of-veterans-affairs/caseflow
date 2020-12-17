import PropTypes from 'prop-types';
import * as React from 'react';
import { css, nthLastChild } from 'glamor';
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

// class FnodBadge extends React.PureComponent {
//   render = () => {
//     const { appeal } = this.props;
//     console.log('PROPS', this.props)

//     const tooltipText = <div>
//       <strong>First Notice of Death</strong>
//       <ul {...listStyling}>
//         <li><strong>Source: </strong>BGS</li>
//         <li><strong>Date of Death: </strong>{appeal.date_of_death}</li>
//       </ul>
//     </div>;

//     return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={appeal.id} />;
//   }
// }
const FnodBadge = (props) => {
  const { appeal } = props;

  console.log('PROPS', props);

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

  return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={appeal.id} />;
};

FnodBadge.propTypes = {
  appeal: PropTypes.object
};

export default FnodBadge;
