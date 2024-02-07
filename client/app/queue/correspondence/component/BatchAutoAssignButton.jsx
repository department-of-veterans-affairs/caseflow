import React from 'react';
import Button from '../../../components/Button';
import ApiUtil from '../../../util/ApiUtil';
import COPY from '../../../../COPY';

const BatchAutoAssignButton = () => {
  const handleAutoAssign = async () => {
    try {
      await ApiUtil.get('/queue/correspondence/auto_assign_correspondences');
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div>
      <Button
        onClick={handleAutoAssign}
        ariaLabel="Auto assign correspnodences"
      >
        {COPY.AUTO_ASSIGN_CORRESPONDENCES_BUTTON}
      </Button>
    </div>
  );
};

export default BatchAutoAssignButton;
