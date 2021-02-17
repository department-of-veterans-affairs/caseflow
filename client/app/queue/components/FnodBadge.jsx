import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';
import { css } from 'glamor';

import { COLORS } from '../../constants/AppConstants';
import Badge from './Badge';
import { DateString } from '../../util/DateUtil';

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
  const { appeal, featureToggles } = props;

  if (!appeal.veteranAppellantDeceased || !featureToggles.fnod_badge) {
    return null;
  }

  const tooltipText = <div>
    <strong>Date of Death Reported</strong>
    <ul {...listStyling}>
      <li><strong>Source:</strong> VBMS</li>
      <li><strong>Date of Death:</strong> <DateString date={appeal.veteranDateOfDeath} /></li>
    </ul>
  </div>;

  return <Badge name="fnod" displayName="FNOD" color={COLORS.RED} tooltipText={tooltipText} id={`fnod-${appeal.id}`} />;
};

FnodBadge.propTypes = {
  appeal: PropTypes.object,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state) => ({ featureToggles: state.ui.featureToggles });

export default connect(mapStateToProps)(FnodBadge);
