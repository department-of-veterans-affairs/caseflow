
import React from 'react';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import RadioField from '../../../components/RadioField';
import { css } from 'glamor';

const ExclusionTable = () => {
  // const { leverList, leverStore } = props;

  // const exclusionLevers = leverList.map((item) => {
  //   return leverStore.getState().levers.find((lever) => lever.item === item);
  // });

  // const [_, setLever] = useState(exclusionLevers);
  // const updateLever = (index) => (e) => {
  //   const levers = exclusionLevers.map((lever, i) => {
  //     if (index === i) {
  //       lever.value = e;

  //       return lever;
  //     } else {
  //       return lever;
  //     }
  //   });
  //   setLever(levers);
  // };

  // const toggleLever = (index) => () => {
  //   const levers = exclusionLevers.map((lever, i) => {
  //     if (index === i) {
  //       lever.is_active = !lever.is_active
  //       return lever;
  //     } else {
  //       return lever;
  //     }
  //   });
  //   setLever(levers);
  // };

  const headerStyling = css({
    color: 'lightgray',
    paddingTop: '0',
    paddingBottom: '0',
    marginTop: '0',
    marginBottom: '0'
  });

  const containerStyling = css({
    paddingTop: '0',
    paddingBottom: '0',
  });

  const tableStyling = css({
    paddingTop: '0',
    marginTop: '0',
    paddingBottom: '0',
    borderLeft: '0',
    borderRight: '0',
    borderTop: '0',
    borderColor: '#d6d7d9;',
    verticalAlign: 'text-top',
    fontFamily: 'Source Sans Pro',
    fontWeight: '400',
    fontSize: '19px',
    lineHeight: '1.3em/25px',
    width: '20%'
  });

  const tableHeaderStyling = css({
    borderLeft: '0',
    borderRight: '0',
    borderTop: '0',
    borderColor: '#d6d7d9;',
    fontFamily: 'Source Sans Pro',
    fontWeight: '700',
    fontSize: '19px',
    lineHeight: '1.3em/25px'
  });

  let options = [
    { displayText: 'On',
      value: '1',
      disabled: true
    },
    { displayText: 'Off',
      value: '2',
      disabled: true
    }
  ];

  return (
    <div {...containerStyling}>
      <table>
        <tbody>
          <th {...tableHeaderStyling}>{' '}</th>
          <th {...tableHeaderStyling}>All Legacy Hearings</th>
          <th {...tableHeaderStyling}>All AMA Hearings</th>
          <th {...tableHeaderStyling}>All AMA Direct Review Cases</th>
          <th {...tableHeaderStyling}>All AMA Evidence Submission Cases</th>
        </tbody>
        <tbody>
          <tr>
            <td {...tableStyling}>
              <h4 {...headerStyling}>All Non-priority</h4>
              <ToggleSwitch
                id = "All Non-priority"
                selected = {false}
                disabled
              />
            </td>
            <td {...tableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...tableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...tableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...tableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
          </tr>
          <tr>
            <td {...tableStyling}>
              <h4 {...headerStyling}>All Priority</h4>
              <ToggleSwitch
                id = "All Priority"
                selected = {false}
                disabled
              />
            </td>
            <td {...tableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...tableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...tableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...tableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

  );
};

export default ExclusionTable;
