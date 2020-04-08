import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import TextField from '../../../components/TextField';
import { dispositionStrings } from '../mtvConstants';
import { sprintf } from 'sprintf-js';
import {
  MOTIONS_ATTORNEY_REVIEW_MTV_DRAFT_HYPERLINK_LABEL,
  MOTIONS_ATTORNEY_REVIEW_MTV_MOTION_HYPERLINK_LABEL
} from '../../../../COPY';
import Button from '../../../components/Button';
import { AddHyperlinkModal } from './AddHyperlinkModal';

const defaultHyperlinks = [
  {
    type: '%s Draft',
    link: ''
  },
  {
    type: 'Motion File',
    link: ''
  }
];

const notGrantType = (disposition) => ['denied', 'dismissed'].includes(disposition);

export const DecisionHyperlinks = ({ onChange, disposition }) => {
  const [hyperlinks, setHyperlinks] = useState([...defaultHyperlinks]);
  const [showModal, setShowModal] = useState(false);

  useEffect(() => onChange(hyperlinks), [hyperlinks]);

  const addHyperlink = (item) => {
    const updated = [...hyperlinks, item];

    setHyperlinks(updated);
    setShowModal(false);
  };
  const editHyperlink = ({ idx, type, link }) => setHyperlinks([...hyperlinks].splice(idx, 1, { type, link }));
  const removeHyperlink = (idx) => {
    const updated = [...hyperlinks];

    updated.splice(idx, 1);
    setHyperlinks(updated);
  };

  const [decision, motion, ...otherLinks] = hyperlinks;

  return (
    <>
      {notGrantType(disposition) && (
        <TextField
          name="decisionDraft"
          label={sprintf(MOTIONS_ATTORNEY_REVIEW_MTV_DRAFT_HYPERLINK_LABEL, dispositionStrings[disposition])}
          value={decision.link}
          onChange={(link) => editHyperlink({ idx: 0, type: decision.type, link })}
          optional
          strongLabel
          className={['mtv-review-hyperlink', 'cf-margin-bottom-2rem']}
        />
      )}

      <TextField
        name="motionFile"
        label={sprintf(MOTIONS_ATTORNEY_REVIEW_MTV_MOTION_HYPERLINK_LABEL, dispositionStrings[disposition])}
        value={motion.link}
        onChange={(link) => editHyperlink({ idx: 1, type: motion.type, link })}
        optional
        strongLabel
        className={['mtv-review-hyperlink', 'cf-margin-bottom-2rem']}
      />

      {otherLinks.map((item, idx) => (
        <div className={['cf-margin-bottom-2rem']} key={idx}>
          <div>
            <strong>{item.type}</strong>
          </div>
          <div>
            <span>{item.link}</span>{' '}
            <Button linkStyling="link" onClick={() => removeHyperlink(idx + 2)}>
              Remove
            </Button>
          </div>
        </div>
      ))}

      <Button onClick={() => setShowModal(true)}>+ Add hyperlink</Button>

      {showModal && <AddHyperlinkModal onSubmit={(value) => addHyperlink(value)} />}
    </>
  );
};

DecisionHyperlinks.propTypes = {
  disposition: PropTypes.string,
  onChange: PropTypes.func
};
