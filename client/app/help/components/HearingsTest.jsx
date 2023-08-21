import React, { useState } from 'react';
import { useQuery, gql } from '@apollo/client';

import ApiUtil from 'app/util/ApiUtil';
import Button from 'app/components/Button';

const HearingsTest = () => {
  const [restValue, setRestValue] = useState('');
  const [graphqlValue, setGraphqlValue] = useState('');

  const [restExecutionTime, setRestExecutionTime] = useState(0);
  const [graphqlExecutionTime, setGraphqlExecutionTime] = useState(0);

  const HEARING_DAY_ID = 35;

  const { data, refetch } = useQuery(gql`
      query GetHearingDayLocationInfo {
        hearingDay(id: ${HEARING_DAY_ID})
        {
          id,
          scheduledFor,
          room,
          regionalOffice,
          requestType,
          notes,
          judge {
            firstName,
            lastName
          }
        }
      }
    `, { enabled: false });

  const performRestRequest = async () => {
    const requestUrl = `/hearings/hearing_day/${HEARING_DAY_ID}`;

    return ApiUtil.get(requestUrl).then((response) => {
      setRestValue(JSON.stringify(response.body));
    });
  };

  const performGraphQLRequest = async () => {
    refetch();

    setGraphqlValue(JSON.stringify(data));
  };

  const benchmarkRequest = async (reqFn) => {
    const startTime = performance.now();

    await reqFn.apply(this);

    const endTime = performance.now();

    const execTime = endTime - startTime;

    return reqFn.name === 'performRestRequest' ? setRestExecutionTime(execTime) : setGraphqlExecutionTime(execTime);
  };

  const requestTypes = [
    {
      name: 'REST',
      time: restExecutionTime,
      value: restValue,
      requestMethod: performRestRequest
    },
    {
      name: 'GraphQL',
      time: graphqlExecutionTime,
      value: graphqlValue,
      requestMethod: performGraphQLRequest
    }
  ];

  return (
    <>
      <h1>REST vs. GraphQL</h1>
      <p>Use the buttons below to compare request times between our REST
        HearingDayController#index route and using GraphQL</p>
      <p>For these tests, we want to be able to pull information related to
        where and when a hearing will be head, and the presiding judge.</p>
      <table>
        <tbody className="query-test-table">
          {requestTypes.map((reqType) =>
            <tr>
              <td>
                <h3>{reqType.name}</h3>
              </td>
              <td>
                <Button
                  name={`start-${reqType.name}-query`}
                  onClick={
                    () => benchmarkRequest(reqType.requestMethod)
                  }
                >
                  Start {reqType.name} Request
                </Button>
              </td>
              <td>
                <div style={{ maxWidth: '800px', maxHeight: '600px', overflowX: 'scroll', overflowY: 'scroll' }}>
                  {reqType.value}
                </div>
              </td>
              <td>
                {reqType.time} ms
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </>
  );
};

export default HearingsTest;
