import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { axe } from "jest-axe";
import { BrowserRouter as Router } from "react-router-dom";
import { Provider } from "react-redux";
import { createStore } from "redux";
import { dailyDocketReducer } from "../../../../data/hearings/dailyDocket/reducer/dailyDocketReducer";
import { dailyDokcetProps } from "../../../../data/hearings/dailyDocket/dailyDocketProps";
import DailyDocketRow from "../../../../../app/hearings/components/dailyDocket/DailyDocketRow";

import COPY from "../../../../../COPY";

let store;

describe('DailyDocketRow', () => {
  beforeEach(() => {
    store = createStore(dailyDocketReducer);
  });

  it('renders correctly', () => {
    const { container } = render(
      <Provider store={store}>
        <Router>
          <DailyDocketRow {...dailyDokcetProps} />
        </Router>
      </Provider>
    );

    expect(container).toMatchSnapshot();
  });
});
