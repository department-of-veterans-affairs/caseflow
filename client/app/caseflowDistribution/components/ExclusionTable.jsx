
import React from 'react';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import RadioField from 'app/components/RadioField';
import { css } from 'glamor';

const ExclusionTable = () => {

  const exclusionTableHeaderStyling = css({
    color: 'lightgray',
    paddingTop: '0',
    paddingBottom: '0',
    marginTop: '0',
    marginBottom: '0'
  });

  const exclusionTableContainerStyling = css({
    paddingTop: '0',
    paddingBottom: '0',
  });

  const exclusionTableStyling = css({
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
    <div {...exclusionTableContainerStyling}>
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
            <td {...exclusionTableStyling}>
              <h4 {...exclusionTableHeaderStyling}>All Non-priority</h4>
              <ToggleSwitch
                id = "All Non-priority"
                selected = {false}
                disabled
              />
            </td>
            <td {...exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
          </tr>
          <tr>
            <td {...exclusionTableStyling}>
              <h4 {...exclusionTableHeaderStyling}>All Priority</h4>
              <ToggleSwitch
                id = "All Priority"
                selected = {false}
                disabled
              />
            </td>
            <td {...exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td {...exclusionTableStyling}>
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
