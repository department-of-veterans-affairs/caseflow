import React, { useState } from 'react';
import { PlusIcon } from '../../components/icons/PlusIcon';
import { MinusIcon } from '../../components/icons/MinusIcon';
import { COLORS } from '../../constants/AppConstants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const NotificationResponseButton = (props) => {
  const [showingDetails, setShowingDetails] = useState(false);

  const styles = {
    size: 14,
    color: COLORS.BASE
  };

  const handleToggle = () => {
    props.toggleResponseDetails();
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

export default NotificationResponseButton;
