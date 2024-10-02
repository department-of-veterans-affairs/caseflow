import React from 'react';
import Button from '../../../components/Button';

const ResetButton = ({ onClick, loading }) => {
  return (
    <Button
      id="clear-appeals"
      data-testid="clear-appeals"
      onClick={onClick}
      name="Clear Ready-to-Distribute Appeals"
      loading={loading}
      loadingText="Clearing Ready-to-Distribute Appeals"
    />
  );
};

export default ResetButton;
