# frozen_string_literal: true

require "rails_helper"

describe Api::V3::HigherLevelReviewProcessor::RequestIssueParams do
  context ".api_key_to_intakes_controller_key" do
    [
      ["changes :category to :nonrating_issue_category", :category, :nonrating_issue_category],
      ["does not change :notes", :notes, :notes],
      ["does not change :root_beer", :root_beer, :root_beer]
    ].each do |(should, input, output)|
      it(should) do
        expect(
          Api::V3::HigherLevelReviewProcessor::RequestIssueParams.api_key_to_intakes_controller_key(
            input
          )
        ).to eq(output)
      end
    end
  end

  context "::ApiShape.to_intakes_controller_shape" do
    benefit_type = "Some benefit type."

    notes = "Some notes."
    decision_issue_id = "A decision issue ID."
    rating_issue_id = "A rating issue ID."
    legacy_appeal_id = "A legacy appeal ID."
    legacy_appeal_issue_id = "A legacy appeal issue ID."
    category = "A category."
    decision_date = "A decision date."
    decision_text = "Some decision text."
    bogus_key = "BOGUS"

    api_style_request_issue_params = ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        notes: notes,
        decision_issue_id: decision_issue_id,
        rating_issue_id: rating_issue_id,
        legacy_appeal_id: legacy_appeal_id,
        legacy_appeal_issue_id: legacy_appeal_issue_id,
        category: category,
        decision_date: decision_date,
        decision_text: decision_text,
        bogus_key: bogus_key
      }
    )

    intakes_controller_style_request_issue_params = ActionController::Parameters.new(
      is_unidentified: false,
      benefit_type: benefit_type,
      notes: notes,
      contested_decision_issue_id: decision_issue_id,
      rating_issue_reference_id: rating_issue_id,
      vacols_id: legacy_appeal_id,
      vacols_sequence_id: legacy_appeal_issue_id,
      nonrating_issue_category: category,
      decision_date: decision_date,
      decision_text: decision_text
    )

    it("should return an IntakesController-style request issue params object ") do
      expect(
        Api::V3::HigherLevelReviewProcessor::RequestIssueParams::ApiShape.to_intakes_controller_shape(
          api_style_request_issue_params, benefit_type
        )
      ).to eq(intakes_controller_style_request_issue_params)
    end
  end

  context "::IntakesControllerShape" do
    context ".unidentified?" do
      context do
        output = false
        [
          { contested_decision_issue_id: true },
          { rating_issue_reference_id: 1 },
          { vacols_id: "a" },
          { vacols_sequence_id: [2] },
          { nonrating_issue_category: { b: 3 } },
          { vacols_id: nil, vacols_sequence_id: :c }
        ].each do |input|
          it(
            [
              "a hash with at least one non-blank ID field or nonrating_issue_category is non-blank",
              "should return #{output}. hash: <#{input}>"
            ].join(" ")
          ) do
            expect(
              Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape.unidentified?(
                ActionController::Parameters.new(input)
              )
            ).to be(output)
          end
        end
      end

      context do
        output = true
        [
          {},
          { contested_decision_issue_id: false },
          { rating_issue_reference_id: nil },
          { vacols_id: "  ", decision_date: "Hello!" },
          { vacols_sequence_id: [] },
          { nonrating_issue_category: {}, notes: true },
          { vacols_id: nil, vacols_sequence_id: "" },
          { category: 44, bogus_key: "BOGUS" }
        ].each do |input|
          it(
            [
              "a hash with only blank or missing ID (or nonrating_issue_category) fields should",
              "return #{output}. hash: <#{input}>"
            ].join(" ")
          ) do
            expect(
              Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape.unidentified?(
                ActionController::Parameters.new(input)
              )
            ).to be(output)
          end
        end
      end

      context "::Validate" do
        context ".all_fields_are_blank" do
          context do
            output = :request_issue_cannot_be_empty
            [
              {},
              { contested_decision_issue_id: false },
              { rating_issue_reference_id: nil },
              { notes: "  " },
              { decision_date: [] },
              { nonrating_issue_category: {} },
              { vacols_id: nil, decision_text: "" }
            ].each do |input|
              it(
                [
                  "an empty hash or a hash with only blank fields should return error code:",
                  "#{output.inspect}.  hash: <#{input}>"
                ].join(" ")
              ) do
                expect(
                  Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape::Validate
                    .all_fields_are_blank(ActionController::Parameters.new(input))
                ).to eq(output)
              end
            end
          end

          context do
            output = nil
            [
              { contested_decision_issue_id: true },
              { rating_issue_reference_id: "a" },
              { notes: 22 },
              { decision_date: ["b"] },
              { nonrating_issue_category: { c: 77 } },
              { vacols_id: "", decision_text: 99 },
              { vacols_id: [], decision_text: :a_symbol }
            ].each do |input|
              it(
                "a hash with at least one non-blank field should return: #{output.inspect}.  hash: <#{input}>"
              ) do
                expect(
                  Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape::Validate
                    .all_fields_are_blank(ActionController::Parameters.new(input))
                ).to eq(output)
              end
            end
          end
        end

        context ".invalid_category" do
          context do
            benefit_type = "compensation"
            [
              ["category blank (false), should return nil", false, nil],
              ["category blank (nil), should return nil", nil, nil],
              ["category blank (\" \"), should return nil", "  ", nil],
              [
                "category \"banana\" should return error code: :unknown_category_for_benefit_type",
                "banana",
                :unknown_category_for_benefit_type
              ],
              [
                "category \"Apportionment\" should return nil",
                "Apportionment",
                nil
              ]
            ].each do |(should, category, output)|
              it("#{should} (benefit_type: #{benefit_type})") do
                expect(
                  Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape::Validate
                    .invalid_category(
                      ActionController::Parameters.new(
                        benefit_type: benefit_type, nonrating_issue_category: category
                      )
                    )
                ).to eq(output)
              end
            end
          end

          context do
            benefit_type = "bogus type"
            category = "Apportionment"
            it("category \"#{category}\" for invalid benefit_type (#{benefit_type}) should raise ArgError") do
              expect do
                Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape::Validate
                  .invalid_category(
                    ActionController::Parameters.new(
                      benefit_type: benefit_type, nonrating_issue_category: category
                    )
                  )
              end.to raise_error(ArgumentError)
            end
          end
        end

        context ".no_ids" do
          context do
            output = nil
            [
              { contested_decision_issue_id: true },
              { rating_issue_reference_id: 1 },
              { vacols_id: "a" },
              { vacols_sequence_id: [2] },
              { vacols_id: nil, vacols_sequence_id: :c }
            ].each do |input|
              it("a hash with no ID fields should return #{output}. hash: <#{input}>") do
                expect(
                  Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape::Validate
                    .no_ids(ActionController::Parameters.new(input))
                ).to be(output)
              end
            end
          end

          context do
            output = :request_issues_without_an_id_are_invalid
            [
              {},
              { contested_decision_issue_id: false },
              { rating_issue_reference_id: nil },
              { vacols_id: "  ", decision_date: "Hello!" },
              { vacols_sequence_id: [] },
              { nonrating_issue_category: {}, notes: true },
              { vacols_id: nil, vacols_sequence_id: "" },
              { category: 44, bogus_key: "BOGUS" }
            ].each do |input|
              it("a hash with only blank or missing ID fields should return #{output}. hash: <#{input}>") do
                expect(
                  Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape::Validate
                    .no_ids(ActionController::Parameters.new(input))
                ).to be(output)
              end
            end
          end
        end

        context ".valid_legacy_fields" do
          [
            [[false, nil, ""], true],
            [[nil, " ", "a"], true],
            [["", 2, []], false],
            [[{}, "a", :a], false],
            [[true, {}, false], false],
            [[2, false, true], false],
            [["a", :a, nil], false],
            [[:a, true, 2], true]
          ].each do |(id, seq, legacy_opt_in_approved), output|
            it do
              expect(
                Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape::Validate
                  .valid_legacy_fields?(id, seq, legacy_opt_in_approved)
              ).to be(output)
            end
          end
        end

        context ".invalid_legacy_fields_or_no_opt_in" do
          [
            ["present ids and opt in returns nil", { vacols_id: 76, vacols_sequence_id: "abc" }, true, nil],
            [
              "blank vacols_id returns :if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id",
              { vacols_id: "  ", vacols_sequence_id: "abc" },
              true,
              :if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id
            ],
            [
              [
                "blank vacols_sequence_id returns",
                ":if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id"
              ].join(" "),
              { vacols_id: 76, vacols_sequence_id: false },
              true,
              :if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id
            ],
            [
              "present ids but not opted in returns :adding_legacy_issue_without_opting_in",
              { vacols_id: 76, vacols_sequence_id: "abc" },
              false,
              :adding_legacy_issue_without_opting_in
            ]
          ].each do |should, hash, legacy_opt_in_approved, output|
            it(should) do
              expect(
                Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape::Validate
                  .invalid_legacy_fields_or_no_opt_in(
                    ActionController::Parameters.new(hash), legacy_opt_in_approved
                  )
              ).to be(output)
            end
          end
        end
      end

      context ".validate" do
        [
          [
            "A valid IntakesController-style request issue params, that's opted-in legacy issues, returns nil",
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "I'd like this to be reviewed again, but by someone higher-up the ladder.",
              contested_decision_issue_id: 2637,
              rating_issue_reference_id: nil,
              vacols_id: 236_718_172,
              vacols_sequence_id: "0001",
              nonrating_issue_category: nil,
              decision_date: "2013-05-30",
              decision_text: "right knee. 50% disabled"
            ),
            true,
            nil
          ],
          [
            "An empty IntakesController-style request issue params returns error: request_issue_cannot_be_empty",
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "",
              notes: "",
              contested_decision_issue_id: nil,
              rating_issue_reference_id: false,
              vacols_id: "  ",
              vacols_sequence_id: [],
              nonrating_issue_category: {},
              decision_date: "",
              decision_text: nil
            ),
            true,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(:request_issue_cannot_be_empty)
          ],
          [
            [
              "An IntakesController-style request issue params with vacols_sequence_id but not vacols__id",
              "returns error: if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id"
            ].join(" "),
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "",
              contested_decision_issue_id: nil,
              rating_issue_reference_id: false,
              vacols_id: [],
              vacols_sequence_id: 2,
              nonrating_issue_category: {},
              decision_date: "",
              decision_text: nil
            ),
            true,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(
              :if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id
            )
          ],
          [
            [
              "An IntakesController-style request issue params with vacols_id but not vacols_sequence_id",
              "returns error: if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id"
            ].join(" "),
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "",
              contested_decision_issue_id: nil,
              rating_issue_reference_id: false,
              vacols_id: 8,
              vacols_sequence_id: [],
              nonrating_issue_category: {},
              decision_date: "",
              decision_text: nil
            ),
            true,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(
              :if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id
            )
          ],
          [
            [
              "A valid IntakesController-style request issue params, that HASN'T opted-in legacy issues,",
              "returns error: adding_legacy_issue_without_opting_in"
            ].join(" "),
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "I'd like this to be reviewed again, but by someone higher-up the ladder.",
              contested_decision_issue_id: 2637,
              rating_issue_reference_id: nil,
              vacols_id: 236_718_172,
              vacols_sequence_id: "0001",
              nonrating_issue_category: nil,
              decision_date: "2013-05-30",
              decision_text: "right knee. 50% disabled"
            ),
            false,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(:adding_legacy_issue_without_opting_in)
          ],
          [
            [
              "An IntakesController-style request issue params with an invalid cateogry",
              "returns error: unknown_category_for_benefit_type"
            ].join(" "),
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "I'd like this to be reviewed again, but by someone higher-up the ladder.",
              contested_decision_issue_id: 2637,
              rating_issue_reference_id: nil,
              vacols_id: 236_718_172,
              vacols_sequence_id: "0001",
              nonrating_issue_category: "Practical Common Lisp (Seibel)",
              decision_date: "2013-05-30",
              decision_text: "right knee. 50% disabled"
            ),
            true,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(:unknown_category_for_benefit_type)
          ],
          [
            "A valid IntakesController-style request issue params with a valid cateogry returns: nil",
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "I'd like this to be reviewed again, but by someone higher-up the ladder.",
              contested_decision_issue_id: 2637,
              rating_issue_reference_id: nil,
              vacols_id: 236_718_172,
              vacols_sequence_id: "0001",
              nonrating_issue_category: "Apportionment",
              decision_date: "2013-05-30",
              decision_text: "right knee. 50% disabled"
            ),
            true,
            nil
          ],
          [
            [
              "An IntakesController-style request issue params with no ID attributes returns error:",
              "request_issues_without_an_id_are_invalid"
            ].join(" "),
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "I'd like this to be reviewed again, but by someone higher-up the ladder.",
              contested_decision_issue_id: nil,
              rating_issue_reference_id: [],
              vacols_id: false,
              vacols_sequence_id: "    ",
              nonrating_issue_category: "Apportionment",
              decision_date: "2013-05-30",
              decision_text: "right knee. 50% disabled"
            ),
            true,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(:request_issues_without_an_id_are_invalid)
          ],

          [
            [
              "An IntakesController-style request issue params with a vacols_id but no",
              "vacols_sequence_id returns error:",
              ":if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id"
            ].join(" "),
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "I'd like this to be reviewed again, but by someone higher-up the ladder.",
              contested_decision_issue_id: nil,
              rating_issue_reference_id: [],
              vacols_id: 999,
              vacols_sequence_id: "    ",
              nonrating_issue_category: "Apportionment",
              decision_date: "2013-05-30",
              decision_text: "right knee. 50% disabled"
            ),
            true,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(
              :if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id
            )
          ],
          [
            [
              "An IntakesController-style request issue params with a vacols_sequence_id",
              "but no vacols_id returns error:",
              ":if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id"
            ].join(" "),
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "I'd like this to be reviewed again, but by someone higher-up the ladder.",
              contested_decision_issue_id: nil,
              rating_issue_reference_id: [],
              vacols_id: false,
              vacols_sequence_id: 232,
              nonrating_issue_category: "Apportionment",
              decision_date: "2013-05-30",
              decision_text: "right knee. 50% disabled"
            ),
            true,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(
              :if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id
            )
          ],
          [
            [
              "An IntakesController-style request issue params with legacy ids but hasn't opted-in",
              "legacy issues returns error: adding_legacy_issue_without_opting_in"
            ].join(" "),
            ActionController::Parameters.new(
              is_unidentified: false,
              benefit_type: "compensation",
              notes: "I'd like this to be reviewed again, but by someone higher-up the ladder.",
              contested_decision_issue_id: nil,
              rating_issue_reference_id: [],
              vacols_id: 222,
              vacols_sequence_id: 223,
              nonrating_issue_category: "Apportionment",
              decision_date: "2013-05-30",
              decision_text: "right knee. 50% disabled"
            ),
            false,
            Api::V3::HigherLevelReviewProcessor::Error.from_error_code(:adding_legacy_issue_without_opting_in)
          ]
        ].each do |should, hash, legacy_opt_in_approved, output|
          it(should) do
            expect(Api::V3::HigherLevelReviewProcessor::RequestIssueParams::IntakesControllerShape.validate(
                     hash, legacy_opt_in_approved
                   )).to eq(output)
          end
        end
      end
    end
  end
end
