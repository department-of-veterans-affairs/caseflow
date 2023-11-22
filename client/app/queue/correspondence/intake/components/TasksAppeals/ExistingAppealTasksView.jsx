import React from 'react';
import PropTypes from 'prop-types';
import { ExternalLinkIcon } from '../../../../../components/icons/ExternalLinkIcon';
import { ICON_SIZES, COLORS } from '../../../../../constants/AppConstants';

export const ExistingAppealTasksView = (props) => {
  return (
    <div>
      <strong>
        Tasks:&nbsp;Appeal&nbsp;
        <a href={`/queue/appeals/${props.appeal.externalId}`} target="_blank">
          #{props.appeal.docketNumber}
          <span className="cf-pdf-external-link-icon" style={{ display: "inline-block", verticalAlign: "middle" }}>
            <ExternalLinkIcon color={COLORS.PRIMARY} size={ICON_SIZES.SMALL} />
          </span>
        </a>
      </strong>
    </div>
  );
};

ExistingAppealTasksView.propTypes = {
  appeal: PropTypes.object.isRequired
};

export default ExistingAppealTasksView;
