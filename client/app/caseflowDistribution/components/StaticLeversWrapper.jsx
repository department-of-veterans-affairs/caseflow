import React from 'react';
import PropTypes from 'prop-types';

import StaticLever from './StaticLever';
import { css } from 'glamor';

const tableHeaderStyling = css({
  borderLeft: '0',
  borderRight: '0',
  borderTop: '0',
  borderColor: '#d6d7d9;',
  fontFamily: 'Source Sans Pro',
  fontWeight: '700',
  fontSize: '21px',
  lineHeight: '1.3em/25px'
});

const tableStyling = css({
  width: '100%',
  tablelayout: 'fixed'
});

const StaticLeversWrapper = (props) => {
  const { leverList, leverStore } = props;

  const orderedLeversList = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const WrapperList = orderedLeversList.map((lever) => (
    <StaticLever key={lever.item} lever={lever} />
  ));

  return (

    <table {...tableStyling}>
      <tbody>
        <tr>
          <th {...tableHeaderStyling}>Data Elements</th>
          <th {...tableHeaderStyling}>Values</th>
        </tr>
      </tbody>
      {WrapperList}
    </table>
  );

};

StaticLeversWrapper.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any
};

export default StaticLeversWrapper;
