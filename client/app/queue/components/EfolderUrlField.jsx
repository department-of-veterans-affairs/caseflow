import React, { useEffect, useState, useRef } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';

import COPY from '../../../COPY';
import Button from '../../components/Button';
import TextField from '../../components/TextField';
import ApiUtil from '../../util/ApiUtil';

const EfolderUrlField = (props) => {

  const [url, setUrl] = useState('');
  const [valid, setValid] = useState(false);
  const [loading, setloading] = useState(false);
  const [error, setError] = useState('');
  const valueRef = useRef(url);

  const extractRequestType = () => (
    props.requestType.replace('Hearing', '').replace('RequestMailTask', '').
      toLowerCase()
  );

  const efolderLinkRegexMatch = (inputValue) => {
    return inputValue.match(/https:\/\/vefs-claimevidence.*\.bip\.va\.gov\/file\/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0] === inputValue.split('?')[0];
  };

  const captureDocumentSeriesId = (validUrl) => {
    return validUrl.match(/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0];
  };

  const checkIfDocumentExists = () => {
    setloading(true);
    const seriesId = captureDocumentSeriesId(url);
    const appealId = props.appealId;

    ApiUtil.get(`/appeals/${appealId}/document/${seriesId}`).
      then((response) => {
        if (response.body.document_presence === true) {
          console.log('valid')
          setValid(true);
          setError('');
        } else {
          setValid(false);
          setError(COPY.EFOLDER_DOCUMENT_NOT_FOUND);
        }
      }).
      catch(() => {
        setValid(false);
        setError(COPY.EFOLDER_CONNECTION_ERROR);
      }).
      finally(() => {
        console.log('stop loading spinner')
        setloading(false);
        console.log('update ref and parent onchange')
        valueRef.current = url;
        props?.onChange?.(url, valid);
      });
  };

  const handleDebounce = debounce((value) => {
    console.log('debounced');
    if (valueRef.current === value) {
      console.log(valid)
      props?.onChange?.(url, valid);
      console.log('same value')
      return;
    }

    if (efolderLinkRegexMatch(value)) {
      console.log('api call')
      checkIfDocumentExists();
    } else {
      setValid(false);
      setError(COPY.EFOLDER_INVALID_LINK_FORMAT);
      valueRef.current = value;
      props?.onChange?.(url, valid);
    }


    // console.log('update ref and parent onchange')
  }, 500);

  useEffect(() => {
    console.log('useEffect');
    props?.onChange?.(url, false);
    handleDebounce(url);

    return () => {
      handleDebounce.cancel();
    };
  }, [url, valid]);

  return <>
    <TextField
      label={`Include eFolder document hyperlink to request a hearing ${extractRequestType()}`}
      name="eFolderUrlField"
      value={url}
      onChange={(newUrl) => setUrl(newUrl)}
      errorMessage={error}
      loading={loading}
    />

    {
      error === COPY.EFOLDER_CONNECTION_ERROR &&
      <Button
        onClick={() => checkIfDocumentExists()}
        linkStyling
        classNames={['cf-push-right', 'cf-retry']}>
          Retry
      </Button>
    }
  </>;
};

EfolderUrlField.propTypes = {
  appealId: PropTypes.string.isRequired,
  requestType: PropTypes.string,
  value: PropTypes.string,
  errorMessage: PropTypes.string,
  valid: PropTypes.bool
};

export default EfolderUrlField;
