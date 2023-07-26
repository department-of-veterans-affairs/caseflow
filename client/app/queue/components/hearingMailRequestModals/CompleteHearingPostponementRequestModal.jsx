import React from 'react';
import PropTypes from 'prop-types';

import QueueFlowModal from '../QueueFlowModal';

const CompleteHearingPostponementRequestModal = (props) => {
  const validateForm = () => false;

  const submit = () => console.log(props);

  return (
    <QueueFlowModal
      title="Mark as complete"
      button="Mark as complete"
      submitDisabled={!validateForm}
      validateForm={validateForm}
      submit={submit}
      pathAfterSubmit="/organizations/hearing-admin"
    />
  );
};

export default CompleteHearingPostponementRequestModal;
