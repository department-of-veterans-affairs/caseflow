import React from 'react';
import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';

const EditDisabledBanner = () => {
  return (
    <Alert type="info" title="HLR and SC permissions updates">
      {COPY.INTAKE_EDIT_DISABLED_COMP_AND_PEN}
    </Alert>
  );
};

export default EditDisabledBanner;
