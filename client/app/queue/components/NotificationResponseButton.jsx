import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { PlusIcon } from '../../components/icons/PlusIcon';
import { MinusIcon } from '../../components/icons/MinusIcon';
import { COLORS } from '../../constants/AppConstants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const NotificationResponseButton = (props) => {
  const [showingDetails, setShowingDetails] = useState(false);

  // base styles for icons
  const styles = {
    size: 14,
    color: COLORS.BASE
  };

  // toggle icons and details
  const handleToggle = () => {
    props.toggleResponseDetails({
      response: props.response || '—',
      date: props.responseDate || '—',
      time: props.responseTime || '—'
    });
    setShowingDetails(!showingDetails);
  };

  return (
    <>
      <Link onClick={() => handleToggle()}>
        {showingDetails ? <MinusIcon size={styles.size} color={styles.color} className="MinusIcon" /> :
          <PlusIcon size={styles.size} color={styles.color} className="PlusIcon" />}</Link>
    </>
  );
};

NotificationResponseButton.propTypes = {
  toggleResponseDetails: PropTypes.func,
  response: PropTypes.string,
  responseDate: PropTypes.string,
  responseTime: PropTypes.string
};

export default NotificationResponseButton;
