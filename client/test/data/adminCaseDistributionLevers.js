export const levers = [
    {
      "item": "lever_1",
      "title": "Lever 1",
      "description": "This is the first lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is active so it should be in the active lever section",
      "data_type": "boolean",
      "value": true,
      "unit": "",
      "is_active": true
    },
    {
      "item": "lever_2",
      "title": "Lever 2",
      "description": "This is the second lever. It is a boolean with the default value of false. Therefore there should be a two radio buttons that display true and false as the example with false being the default option chosen. This lever is active so it should be in the active lever section",
      "data_type": "boolean",
      "value": false,
      "unit": "",
      "is_active": true
    },
    {
      "item": "lever_3",
      "title": "Lever 3",
      "description": "This is the third lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is inactive so it should be in the inactive lever section",
      "data_type": "boolean",
      "value": true,
      "unit": "",
      "is_active": false
    },
    {
      "item": "lever_4",
      "title": "Lever 4",
      "description": "This is the fourth lever. It is a boolean with the default value of false. Therefore there should be a two radio buttons that display true and false as the example with false being the default option chosen. This lever is inactive so it should be in the inactive lever section",
      "data_type": "boolean",
      "value": false,
      "unit": "",
      "is_active": true
    },
    {
      "item": "lever_5",
      "title": "Lever 5",
      "description": "This is the fifth lever. It is a number data type with the default value of 42. Therefore there should be a number input that displays 42 and 'days' as the unit. This lever is active so it should be in the active lever section",
      "data_type": "number",
      "value": 42,
      "unit": "days",
      "is_active": true
    },
    {
      "item": "lever_6",
      "title": "Lever 6",
      "description": "This is the fifth lever. It is a number data type with the default value of 15. Therefore '15 days' should be displayed. This lever is inactive so it should be in the inactive lever section",
      "data_type": "number",
      "value": 15,
      "unit": "days",
      "is_active": false
    },
      {
      "item": "lever_7",
      "title": "Lever 7",
      "description": "This is the seventh lever. It is a number data type with the default value of 35. Therefore there should be a number input that displays 35 and 'cases' as the unit. This lever is active so it should be in the active lever section",
      "data_type": "number",
      "value": 35,
      "unit": "cases",
      "is_active": true
    },
    {
      "item": "lever_8",
      "title": "Lever 8",
      "description": "This is the eigth lever. It is a number data type with the default value of 200. Therefore '200 cases' should be displayed. This lever is inactive so it should be in the inactive lever section",
      "data_type": "number",
      "value": 200,
      "unit": "cases",
      "is_active": false
    },
    {
      "item": "lever_9",
      "title": "Lever 9",
      "description": "This is the ninth lever. It is a radio data type with the default value of option_1. Therefore there should be a radio options displayed and option_1 is selected by default. If the option is text only the text is displayed, but if it is a different data type then the appropriate input and unit are displayed and the value stored. This lever is active so it should be in the active lever section",
      "data_type": "radio",
      "value": "option_1",
      "unit": "cases",
      "options": [
          {
          "item": "option_1",
          "data_type": "text",
          "value": "option_1",
          "text": "Option 1",
          "unit": ""
          },
          {
          "item": "option_2",
          "data_type": "number",
          "value": 68,
          "text": "Option 2",
          "unit": "days"
          }
      ],
      "is_active": true
    },
    {
        "item": "lever_10",
        "title": "Lever 10",
        "description": "This is the ninth lever. It is a radio data type with the default value of option_1. Therefore there should be a radio options displayed and option_1 is selected by default. If the option is text only the text is displayed, but if it is a different data type then the appropriate input and unit are displayed and the value stored. This lever is active so it should be in the active lever section",
        "data_type": "combination",
        "value": 78,
        "unit": "cases",
        "options": [
            {
            "item": "option_1",
            "data_type": "boolean",
            "value": true,
            "text": "This feature is turned on or off",
            "unit": ""
            }
        ],
        "is_active": true
      }
  ]

export const history = [
  {
    "user": "john_smith",
    "created_at": "2023-07-01 10:10:01",
    "title": 'Lever 1',
    "original_value": 10,
    "current_value": 23,
    "unit": "cases"
  },
  {
    "user": "john_smith",
    "created_at": "2023-07-01 10:10:01",
    "title": 'Lever 2',
    "original_value": false,
    "current_value": true,
    "unit": ""
  },
  {
    "user": "jane_smith",
    "created_at": "2023-07-01 12:10:01",
    "title": 'Lever 1',
    "original_value": 5,
    "current_value": 42,
    "unit": "cases"
  }
]
