import React from 'react';

const SPECIAL_ISSUES = [
  {
    display: 'Contaminated Water at Camp LeJeune',
    specialIssue: 'contaminatedWaterAtCampLejeune',
    stationOfJurisdiction: {
      key: '327',
      location: 'Louisville, KY'
    },
    unhandled: null
  },
  {
    display: 'DIC - death, or accrued benefits - United States',
    specialIssue: 'dicDeathOrAccruedBenefitsUnitedStates',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: `Education - GI Bill, dependents educational assistance, ` +
      `scholarship, transfer of entitlement`,
    specialIssue: `educationGiBillDependentsEducationalAssistanceScholarship` +
      `TransferOfEntitlement`,
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: 'education',
      regionalOffice: 'education'
    }
  },
  {
    display: 'Foreign claim - compensation claims, dual claims, appeals',
    specialIssue: 'foreignClaimCompensationClaimsDualClaimsAppeals',
    stationOfJurisdiction: {
      key: '311',
      location: 'Pittsburgh, PA'
    },
    unhandled: null
  },
  {
    display: 'Foreign pension, DIC - Mexico, Central and South America, Caribbean',
    specialIssue: 'foreignPensionDicMexicoCentralAndSouthAmericaCaribb',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: ['PMC/PMCIPC.VAVBASPL@va.gov', 'Hillary.Hernandez@va.gov'],
      regionalOffice: 'RO83'
    }
  },
  {
    display: 'Foreign pension, DIC - all other foreign countries',
    specialIssue: 'foreignPensionDicAllOtherForeignCountries',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddess: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: 'Hearing - including travel board & video conference',
    specialIssue: 'hearingIncludingTravelBoardVideoConference',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Home Loan Guaranty',
    specialIssue: 'homeLoanGuaranty',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: ['jennifer.Tillery@va.gov'],
      regionalOffice: 'RO88'
    }
  },
  {
    display: 'Incarcerated Veterans',
    specialIssue: 'incarceratedVeterans',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Insurance',
    specialIssue: 'insurance',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: ['nancy.encarnado@va.gov'],
      regionalOffice: 'RO80'
    }
  },
  {
    display: 'Manlincon Compliance',
    node: <span><i>Manlincon</i> Compliance</span>,
    specialIssue: 'manlinconCompliance',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Mustard Gas',
    specialIssue: 'mustardGas',
    stationOfJurisdiction: {
      key: '351',
      location: 'Muskogee, OK'
    },
    unhandled: null
  },
  {
    display: 'National Cemetery Administration',
    specialIssue: 'nationalCemeteryAdministration',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: ['richard.byersII@va.gov'],
      regionalOffice: 'RO98'
    }
  },
  {
    display: 'Non-rating issue',
    specialIssue: 'nonratingIssue',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Pension - United States',
    specialIssue: 'pensionUnitedStates',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: 'PMC',
      regionalOffice: 'PMC'
    }
  },
  {
    display: 'Private Attorney or Agent',
    specialIssue: 'privateAttorneyOrAgent',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Radiation',
    specialIssue: 'radiation',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Rice Compliance',
    node: <span><i>Rice</i> Compliance</span>,
    specialIssue: 'riceCompliance',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: 'Spina Bifida',
    specialIssue: 'spinaBifida',
    stationOfJurisdiction: 'regional',
    unhandled: null
  },
  {
    display: `U.S. Territory claim - American Samoa, Guam, Northern ` +
      `Mariana Islands (Rota, Saipan & Tinian)`,
    specialIssue: `usTerritoryClaimAmericanSamoaGuamNorthern` +
      `MarianaIslandsRotaSaipanTinian`,
    stationOfJurisdiction: {
      key: '459',
      location: 'Honolulu, HI'
    },
    unhandled: null
  },
  {
    display: 'U.S. Territory claim - Philippines',
    specialIssue: 'usTerritoryClaimPhilippines',
    stationOfJurisdiction: {
      key: '358',
      location: 'Manila, Philippines'
    },
    unhandled: null
  },
  {
    display: 'U.S. Territory claim - Puerto Rico and Virgin Islands',
    specialIssue: 'usTerritoryClaimPuertoRicoAndVirginIslands',
    stationOfJurisdiction: {
      key: '355',
      location: 'San Juan, Puerto Rico'
    },
    unhandled: null
  },
  {
    display: 'VAMC',
    specialIssue: 'vamc',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: ['Travis.Richardson@va.gov'],
      regionalOffice: 'RO99'
    }
  },
  {
    display: 'Vocational Rehab',
    specialIssue: 'vocationalRehab',
    stationOfJurisdiction: 'regional'
  },
  {
    display: 'Waiver of Overpayment',
    specialIssue: 'waiverOfOverpayment',
    stationOfJurisdiction: null,
    unhandled: {
      emailAddress: 'COWC',
      regionalOffice: 'COWC'
    }
  }
];

export default SPECIAL_ISSUES;
