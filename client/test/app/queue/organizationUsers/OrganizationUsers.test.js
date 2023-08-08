import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import OrganizationUsers from 'app/queue/OrganizationUsers';

describe('Conference Selection Visibility Feature Toggle', () => {
  it('renders the nested component when conferenceSelectionVisibility is true',async () => {
    render(
      <OrganizationUsers
        organizationName='Hearing Admin'
        conferenceSelectionVisibility={true}
      />
    );

    screen.debug();
    const nestedText = await screen.findByTestId("conference-radio-button");
      expect(nestedText).toBeInTheDocument();
  });

  // it("does not render the nested component for other conditions", () => {
  //   render(
  //     <OrganizationUsers
  //       organizationName="Hearing Management"
  //       conferenceSelectionVisibility= {true}
  //     />
  //   );

  //   const nestedTextQuery = screen.queryByText("Pexip");
  //   expect(nestedTextQuery).not.toBeInTheDocument();

  //   render(
  //     <OrganizationUsers
  //       organizationName="Hearing Admin"
  //       conferenceSelectionVisibility={false}
  //     />
  //   );

  //   const nestedTextQuery2 = screen.queryByText("Pexip");
  //   expect(nestedTextQuery2).not.toBeInTheDocument();
  // });
});
