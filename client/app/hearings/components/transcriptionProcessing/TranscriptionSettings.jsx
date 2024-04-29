/* eslint-disable no-nested-ternary */
/* eslint-disable max-len */
import PropTypes from 'prop-types';
import React from 'react';

const TranscriptionSettings = (props) => {
  const {
    hearing,
  } = props;

  const headerContainerStyling = css({
    margin: '-2rem 0 0 0',
    padding: '0 0 1.5rem 0',
    '& > *': {
      display: 'inline-block',
      paddingRight: '15px',
      paddingLeft: '15px',
      verticalAlign: 'middle',
      margin: 0
    }
  });

  const headerStyling = css({
    paddingLeft: 0,
  });

  return (
    <React.Fragment>
      <div {...headerContainerStyling}>
        <h1 className="cf-margin-bottom-0" {...headerStyling}>
          {`Transcription Settings`}
        </h1>
        <div {...headerContainerStyling}>
          <h2 {...headerStyling}>
            {`Edit Current Contractors`}
          </h2>
        </div>
      </div>

    </React.Fragment>
  );
}

TranscriptionSettings.propTypes = {

};

export default TranscriptionSettings;
