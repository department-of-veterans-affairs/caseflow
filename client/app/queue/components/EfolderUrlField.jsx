import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';

import TextField from '../../components/TextField';
import ApiUtil from '../../util/ApiUtil';

const EfolderUrlField = (props) => {

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

  const handleDebounce = debounce((value) => {
    console.log('Debounced!');

    if (efolderLinkRegexMatch(value)) {
      console.log('Valid regex match');
      // start loading spinner
      const seriesId = captureDocumentSeriesId(value);
      const appealId = props.appealId;

      ApiUtil.get(`/appeals/${appealId}/document/${seriesId}`).
        then((response) => {
          // stop loading spinner

          // if true
          // set own valid prop to true
          // if false
          // set own valid prop to false
          // show error message (doen't exist in efolder)
        }).
        catch((response) => {
          // stop loading spinner
          // handle errors
        });

      // stop loading spinner
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
