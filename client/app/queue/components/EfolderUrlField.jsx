import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';

import TextField from '../../components/TextField';
import ApiUtil from '../../util/ApiUtil';

const EfolderUrlField = (props) => {

  const [valid, setValid] = useState(false);

  const extractRequestType = () => (
    props.requestType.replace('Hearing', '').replace('RequestMailTask', '').
      toLowerCase()
  );

  const efolderLinkRegexMatch = (url) => {
    return url.match(/https:\/\/vefs-claimevidence.*\.bip\.va\.gov\/file\/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0] === url.split('?')[0];
  };

  const captureDocumentSeriesId = (url) => {
    return url.match(/\S{8}-\S{4}-\S{4}-\S{4}-\S{12}/)?.[0];
  };

  let isLoading = false;


  const handleDebounce = debounce((value) => {
    console.log('Debounced!');
    setValid(false);

    if (efolderLinkRegexMatch(value)) {
      console.log('Valid regex match');
      // start loading spinner
      isLoading = true;
      const seriesId = captureDocumentSeriesId(value);
      const appealId = props.appealId;

      ApiUtil.get(`/appeals/${appealId}/document/${seriesId}`).
        then((response) => {
          if (response.body.document_presence === true) {
            setValid(true);
          } else {
            setValid(false);
            // show error message
          }
        }).
        catch((response) => {
          // stop loading spinner
          // handle errors
        });

      isLoading = false;
    } else {
      console.log('Invalid efolder regex match');
      // https://benefits-int-delivery.slack.com/archives/C03NCPYRXK2/p1687881917481399?thread_ts=1687878651.089549&cid=C03NCPYRXK2
      // Show error message as described in thread ^^ (invalid link format)
      // Block form submission until resolved
    }
  }, 500);

  const handleChange = (value) => {
    props?.onChange?.(value);
  };

  useEffect(() => {
    handleDebounce(props.value);

    return () => {
      handleDebounce.cancel();
    };
  }, [props.value]);

  return <>
    <TextField
      label={`Include Caseflow Reader document hyperlink to request a hearing ${extractRequestType()}`}
      name="eFolderUrlField"
      value={props.value}
      onChange={handleChange}
      errorMessage={props.errorMessage}
      loading={isLoading}
    />
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
