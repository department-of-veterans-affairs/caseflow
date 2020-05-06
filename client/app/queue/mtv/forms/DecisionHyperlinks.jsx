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
    type: 'draft of the motion',
    link: ''
  },
  {
    type: 'draft of the %s',
    link: ''
  }
];

const notGrantType = (disposition) => ['denied', 'dismissed'].includes(disposition);

export const DecisionHyperlinks = ({ onChange, disposition }) => {
  const [hyperlinks, setHyperlinks] = useState([...defaultHyperlinks]);
  const [showModal, setShowModal] = useState(false);

  useEffect(() => {
    // Ensure that we remove unused link if disposition changes
    if (!notGrantType(disposition)) {
      hyperlinks[1].link = '';
    }

    onChange(hyperlinks);
  }, [hyperlinks, disposition]);

  const addHyperlink = (item) => {
    const updated = [...hyperlinks, item];

    setHyperlinks(updated);
    setShowModal(false);
  };
  const editHyperlink = ({ idx, type, link }) => {
    setHyperlinks((prev) =>
      prev.map((item) => {
        if (item === hyperlinks[idx]) {
          return { type, link };
        }

        return item;
      })
    );
  };
  const removeHyperlink = (idx) => {
    const updated = [...hyperlinks];

    updated.splice(idx, 1);
    setHyperlinks(updated);
  };

  const [motion, decision, ...otherLinks] = hyperlinks;

  return (
    <>
      {notGrantType(disposition) && (
        <TextField
          name="decisionDraft"
          label={sprintf(MOTIONS_ATTORNEY_REVIEW_MTV_DRAFT_HYPERLINK_LABEL, dispositionStrings[disposition])}
          value={decision.link}
          onChange={(link) => editHyperlink({ idx: 1, type: decision.type, link })}
          strongLabel
          className={['mtv-review-hyperlink', 'cf-margin-bottom-2rem']}
        />
      )}

      <TextField
        name="motionFile"
        label={sprintf(MOTIONS_ATTORNEY_REVIEW_MTV_MOTION_HYPERLINK_LABEL, dispositionStrings[disposition])}
        value={motion.link}
        onChange={(link) => editHyperlink({ idx: 0, type: motion.type, link })}
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
            <Button linkStyling onClick={() => removeHyperlink(idx + 2)}>
              Remove
            </Button>
          </div>
        </div>
      ))}

      <Button onClick={() => setShowModal(true)}>+ Add hyperlink</Button>

      {showModal && (
        <AddHyperlinkModal onSubmit={(value) => addHyperlink(value)} onCancel={() => setShowModal(false)} />
      )}
    </>
  );
};

DecisionHyperlinks.propTypes = {
  disposition: PropTypes.string,
  onChange: PropTypes.func
};
