import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import CopyTextButton from '../../../components/CopyTextButton';
import Modal from '../../../components/Modal';
import { closeAnnotationShareModal } from '../../../reader/AnnotationLayer/AnnotationActions';
import { modalInfoSelector } from '../../selectors';

const ShareModal = () => {
  const dispatch = useDispatch();
  const { shareAnnotationModalIsOpenFor } = useSelector(modalInfoSelector);

  if (!shareAnnotationModalIsOpenFor) {
    return null;
  }

  return (
    <Modal
      buttons={[
        {
          classNames: ['usa-button', 'usa-button-secondary'],
          name: 'Close',
          onClick: () => dispatch(closeAnnotationShareModal()),
        },
      ]}
      closeHandler={() => dispatch(closeAnnotationShareModal())}
      title="Share Comment"
    >
      <CopyTextButton
        text={`${location.origin}${location.pathname}?annotation=${shareAnnotationModalIsOpenFor}`}
        // textToCopy={`${location.origin}${location.pathname}?annotation=${shareAnnotationModalIsOpenFor}`}
        label="Link to annotation"
      />
    </Modal>
  );
};

export default ShareModal;
