import React, { useState } from 'react';
import { PlusIcon } from '../../components/icons/PlusIcon';
import { MinusIcon } from '../../components/icons/MinusIcon';
import { COLORS } from '../../constants/AppConstants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const ResponseDetailsButton = () => {
  const [hide, setHide] = useState(true);

  return (
    <Link onClick={() => setHide(!hide)} >
      {hide ? <PlusIcon size={12} color={COLORS.BASE} className="PlusIcon" /> :
        <MinusIcon size={12} color={COLORS.BASE} className="MinusIcon" />}
    </Link>
  );
};

export default ResponseDetailsButton;
