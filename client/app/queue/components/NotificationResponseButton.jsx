import React from 'react';
import { PlusIcon } from '../../components/icons/PlusIcon';
import { MinusIcon } from '../../components/icons/MinusIcon';
import { COLORS } from '../../constants/AppConstants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const NotificationResponseButton = (props) => {

  console.log(props)

  const showResponseDetails = () => {
    return (
      <>
        <Link onClick={() => toggleResponseDetails()}><MinusIcon size={12} color={COLORS.BASE} className="MinusIcon" /></Link>
      </>
    );
  };

  return (
    <>
      <Link onClick={() => props.toggleResponseDetails()}><PlusIcon size={12} color={COLORS.BASE} className="PlusIcon" /></Link>
    </>
  );
};

export default NotificationResponseButton;
