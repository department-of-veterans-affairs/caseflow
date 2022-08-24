import React, { useContext } from 'react';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import COPY from '../../../COPY';
import {
  useTable
} from 'react-table';

const SplitAppealConfirm = () => {
  const { reason } = useContext(StateContext);
  const columns = React.useMemo(() => (
    [
      {
        id: 'columnId_00.3277336290406283',
        Header: '',
        accessor: '',
        Footer: '',
        columns: [
          {
            id: 'columnId_0_00.09075515404177104',
            Header: 'Veteran',
            accessor: 'veteran',
            Footer: '',
            columns: [
              {
                id: 'columnId_0_0_00.6638957174305951',
                Header: 'Docket Number',
                accessor: 'docket_number',
                Footer: '',
                columns: [
                  {
                    id: 'columnId_0_0_0_00.6037342717183949',
                    Header: 'Review Option',
                    accessor: 'review_option',
                    Footer: '',
                    columns: [
                      {
                        id: 'columnId_0_0_0_0_00.057195930682101714',
                        Header: 'Issues(s)',
                        accessor: 'Key0',
                        Footer: '',
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        id: 'columnId_00.2958969918938521',
        Header: 'Original Appeal Stream',
        accessor: 'original_appeal_stream',
        Footer: '',
        columns: [
          {
            id: 'columnId_0_10.07053272011000855',
            Header: 'Veteran Name Placeholder',
            accessor: 'veteran_name_placeholder',
            Footer: '',
            columns: [
              {
                id: 'columnId_0_1_00.7822271072976499',
                Header: 'Docket Number Value Placeholder',
                accessor: 'docket_number_value_placeholder',
                Footer: '',
                columns: [
                  {
                    id: 'columnId_0_1_0_00.5711411575180423',
                    Header: 'Review Option Placeholder',
                    accessor: 'review_option_placeholder',
                    Footer: '',
                    columns: [
                      {
                        id: 'columnId_0_1_0_0_00.011743587193976834',
                        Header: 'Issues Placeholder',
                        Footer: '',
                        accessor: 'Key1'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        id: 'columnId_00.9225875721769246',
        Header: 'New Appeal Stream',
        accessor: 'new_appeal_stream',
        Footer: '',
        columns: [
          {
            id: 'columnId_0_20.5649273990137622',
            Header: 'Veteran Name Placeholder',
            accessor: 'veteran_name_placeholder',
            Footer: '',
            columns: [
              {
                id: 'columnId_0_2_00.5805703290131536',
                Header: 'Docket Number Value Placeholder',
                accessor: 'docket_number_value_placeholder',
                Footer: '',
                columns: [
                  {
                    id: 'columnId_0_2_0_00.4474365071881008',
                    Header: 'Review Option Placeholder',
                    accessor: 'review_option_placeholder',
                    Footer: '',
                    columns: [
                      {
                        id: 'columnId_0_2_0_0_00.4663977107535904',
                        Header: 'Issues Placeholder',
                        Footer: '',
                        accessor: 'Key2'
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  ), []);
  const data = React.useMemo(() => (
    [
      {
        Key0: 'Julian',
        Key1: 'hhs.gov',
        Key2: 'Teal'
      },
      {
        Key0: 'Ketti',
        Key1: 'desdev.cn',
        Key2: 'Turquoise'
      },
      {
        Key0: 'Fallon',
        Key1: 'elegantthemes.com',
        Key2: 'Yellow'
      },
      {
        Key0: 'Leela',
        Key1: 'oakley.com',
        Key2: 'Crimson'
      },
    ]), []);

  const {
    getTableProps,
    getTableBodyProps,
    headerGroups,
    rows,
    prepareRow,
  } = useTable(
    {
      columns,
      data,
    },
  );

  return (
    <>
      <div>
        <h1 style={{ margin: '0px' }}>{COPY.SPLIT_APPEAL_REVIEW_TITLE}</h1>
        <span>{COPY.SPLIT_APPEAL_REVIEW_SUBHEAD}</span>
      </div>
      <br /><br />
      <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'left' }}>
        <u>{COPY.SPLIT_APPEAL_REVIEW_REASONING_TITLE}</u> &ensp;
        <span style={{ flexBasis: '75%' }}>{reason}</span>
      </div>
      <br /><br />
      <p>Here we will add the table</p>
      <div>
        <table
          {...getTableProps()}
          border={1}
          style={{
            borderCollapse: 'collapse',
            width: '100%',
            margin: 'auto'
          }}
        >
          <thead>
            {headerGroups.map((group) => (
              <tr {...group.getHeaderGroupProps()}>
                {group.headers.map((column) => (
                  <th {...column.getHeaderProps()}>
                    column.render("Header")
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody {...getTableBodyProps()}>
            {rows.map((row) => {
              prepareRow(row);

              return (
                <tr {...row.getRowProps()}>
                  {row.cells.map((cell) => {
                    return (
                      <td {...cell.getCellProps()}>{cell.render('Cell')}</td>
                    );
                  })}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </>
  );
};

export default SplitAppealConfirm;
