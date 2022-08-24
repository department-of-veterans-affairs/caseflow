import React, { useContext } from 'react';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import COPY from '../../../COPY';
import Table from '../../components/Table';

const SplitAppealConfirm = () => {
  const { reason } = useContext(StateContext);
  const columns = React.useMemo(() => (
    [
      {
        id: '1',
        Header: '',
        accessor: '',
        Footer: '',
        columns: [
          {
            id: '2',
            Header: 'Veteran',
            accessor: 'veteran',
            Footer: '',
            columns: [
              {
                id: '3',
                Header: 'Docket Number',
                accessor: 'stream_docket_number',
                Footer: '',
                columns: [
                  {
                    id: '4',
                    Header: 'Review Option',
                    accessor: 'review_option',
                    Footer: '',
                    columns: [
                      {
                        id: '5',
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
        id: '6',
        Header: 'Original Appeal Stream',
        accessor: 'original_appeal_stream',
        Footer: '',
        columns: [
          {
            id: '7',
            Header: 'Veteran Name Placeholder',
            accessor: 'veteran_name_placeholder',
            Footer: '',
            columns: [
              {
                id: '8',
                Header: 'Docket Number Value Placeholder',
                accessor: 'docket_number_value_placeholder',
                Footer: '',
                columns: [
                  {
                    id: '9',
                    Header: 'Review Option Placeholder',
                    accessor: 'review_option_placeholder',
                    Footer: '',
                    columns: [
                      {
                        id: '10',
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
        id: '11',
        Header: 'New Appeal Stream',
        accessor: 'new_appeal_stream',
        Footer: '',
        columns: [
          {
            id: '12',
            Header: 'Veteran Name Placeholder',
            accessor: 'veteran_name_placeholder',
            Footer: '',
            columns: [
              {
                id: '13',
                Header: 'Docket Number Value Placeholder',
                accessor: 'docket_number_value_placeholder',
                Footer: '',
                columns: [
                  {
                    id: '14',
                    Header: 'Review Option Placeholder',
                    accessor: 'review_option_placeholder',
                    Footer: '',
                    columns: [
                      {
                        id: '15',
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
  const rowObjects = React.useMemo(() => (
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

  let additionalRowClasses = () => {
    // no-op unless the issue banner needs to be displayed
  };

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
      <Table columns={columns} rowObjects={rowObjects} rowClassNames={additionalRowClasses} slowReRendersAreOk />
    </>
  );
};

export default SplitAppealConfirm;
