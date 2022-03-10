module WarRoom
    class ChangeNonRatingIssue
      def run(uuid_pass_in)
        uuid = uuid_pass_in
        rsc=SupplementalClaim.find_by(uuid: uuid)
        rsc.decision_review_remanded # not nil
        v=rsc.veteran
        rs=v.ratings
        rating_issues=rs.map(&:issues).flatten
        rscris=rsc.request_issues
        rsc_nr_ris=rscris.select(&:nonrating?)
  
        # In this example, there are two issues that need to be moved,
        # one for "left knee" and one for "right_knee"
        # These are the request issues on the remand supplemental claim
        left_knee_ri=rsc_nr_ris.first
        right_knee_ri=rsc_nr_ris.second
  
        # These are the decision issues the request issues are contesting, from an Appeal
        left_cdi=left_knee_ri.contested_decision_issue
        right_cdi=right_knee_ri.contested_decision_issue
  
        # These are the original nonrating request issues that were added on the appeal
        left_ori=left_cdi.request_issues.first
        right_ori=right_cdi.request_issues.first
  
        # These are the "matching" rating issues found, found by comparing issue descriptions
        # and dates and finding the closest match, if available. If not available,
        # then one can look at a workaround using the "decisions" on ratings
        # (which are from disabilities).  If nothing is available, then this may be
        # blocked until more is developed on Edit EP claim labels.
        left_rating_issue_id="31739922"
        right_rating_issue_id="31739921"
        left_rating_issue=rating_issues.find{|i| i.reference_id == left_rating_issue_id}
        right_rating_issue=rating_issues.find{|i| i.reference_id == right_rating_issue_id}
  
        # Update the data on the request issue to connect them to the matching rating issues,
        # then also add the diagnostic code to the decision issue
        left_ori.update!(
          decision_date: left_rating_issue.promulgation_date,
          contested_rating_issue_diagnostic_code: left_rating_issue.diagnostic_code,
          contested_rating_issue_reference_id: left_rating_issue.reference_id,
          contested_rating_issue_profile_date: left_rating_issue.profile_date,
          contested_issue_description: left_rating_issue.decision_text,
          nonrating_issue_description: nil,
          nonrating_issue_category: nil,
        )
        left_cdi.update!(
          diagnostic_code: left_rating_issue.diagnostic_code
        )
  
        right_ori.update!(
          decision_date: right_rating_issue.promulgation_date,
          contested_rating_issue_diagnostic_code: right_rating_issue.diagnostic_code,
          contested_rating_issue_reference_id: right_rating_issue.reference_id,
          contested_rating_issue_profile_date: right_rating_issue.profile_date,
          contested_issue_description: right_rating_issue.decision_text,
          nonrating_issue_description: nil,
          nonrating_issue_category: nil,
        )
        right_cdi.update!(
          diagnostic_code: right_rating_issue.diagnostic_code
        )
  
        # Check if the remand supplemental claim issues now register as rating issues
        left_knee_ri.rating?
        right_knee_ri.rating?
  
        # Save the original EPE, so we can cancel it when we're done, it's the same for both request issues
        original_epe=left_knee_ri.end_product_establishment
  
        left_new_epe=left_knee_ri.decision_review.end_product_establishment_for_issue(left_knee_ri)
        right_new_epe=right_knee_ri.decision_review.end_product_establishment_for_issue(right_knee_ri)
  
        # it's the same for both request issues
        new_epe=left_new_epe
  
        # Update the request issues to be connected to the rating end product establishment
        left_knee_ri.update!(
          contention_reference_id: nil,
          end_product_establishment_id: new_epe.id,
          contested_rating_issue_diagnostic_code: left_rating_issue.diagnostic_code,
          nonrating_issue_category: nil
        )
        right_knee_ri.update!(
          contention_reference_id: nil,
          end_product_establishment_id: new_epe.id,
          contested_rating_issue_diagnostic_code: right_rating_issue.diagnostic_code,
          nonrating_issue_category: nil
        )
  
        # Adds the contentions to the rating EP
        new_epe.establish!
  
        # There shouldn't be any request issues connected to the original end product anymore
        original_epe.request_issues.any?
  
        # Check that the contentions are now on the rating EP
        new_epe.contentions
  
        # Cancel the nonrating EP, now that those issues are moved to the rating EP
        original_epe.send(:cancel!)
      end
    end
  end