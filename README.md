# Miro Technical Take Home. Eugene Osminkin Submission.

## Summary

Hi all! Here is my user acquisition model, built in a dbt repository style. The queries are written in Snowflake SQL dialect and tested in my personal Snowflake environment.

### a. Modeling Methodology

The chosen modeling approach can be described as a two-step process:

- **Session-Level Data Enrichment**: The first intermediate model, `int_sessions_users`, joins session and conversion data and enriches it with calculated fields like `duration_to_registration_hr` and booleans such as `is_within_life_span`. These categorize each session based on its lifespan, rule compliance, and medium.
  
- **User-Level Aggregation**: The second intermediate model, `int_acquisitions_users`, aggregates this enriched data at the user level. It determines the `acquisition_channel` for each user based on a set of rules. This flattens the user data, providing features like `first_paid_time`,`first_paid_medium`,`first_organic_time`,`first_organic_medium`, etc. The `acquisition_channel` is determined through a readable CASE statement that is easy to modify if needed.

This layered approach was taken to make the logic easier to understand, to improve data quality, and to facilitate intermediate verification of the results.

### b. Requirements Discovery Without Rules and Examples

I built the acquisition model taking into account the rules from the Miro board and the examples provided. However, not all aspects were clear based on the information given. Outstanding questions include:
- How should we treat mediums not mentioned in the examples?
- For instance, should the major medium `INVITES` constitute a separate acquisition channel or be grouped with others mentioned on the board?
- For 5% of users no sessions happened before the registration, are they still marked as `OTHER` channel or a new label is needed?

My approach was to build logic that:
- Complies with the requirements
- Is based on my best assumptions for unspecified parts
- Is modular and easily adjustable for future updates

I would be happy to iteratively refine the model based on your feedback.

### c. Testing Methodology

To ensure data quality, the following measures were implemented:

- Dbt data tests: These check for issues like duplicates, nulls in key fields, or unexpected values.
- Record Visibility: Models were built to display all records; thus, no `WHERE` or `INNER JOIN` clauses were used. Additionally, a `FULL OUTER JOIN` was used to catch users registered without any sessions.
- Intermediate Verification: Intermediate models can be queried directly to validate data consistency and logic behavior.

### d. Broader Data Warehouse Model

This user acquisition data could be part of a larger "User" dimension table in a star schema. This would enable it to be used alongside other user features for more complex analyses like funnel or cohort analysis.

### e. Reporting and Analytics Considerations

The final model, `rpt_monthly_acquisition_channels`, serves as a data mart. It answers the assignment's question and can be used in a BI solution without needing to understand the underlying logic. Furthermore, intermediate models are built to be readable by business analysts and could also serve as BI data sources, providing more fine-grained information.

Here is the result of the model `rpt_monthly_acquisition_channels`:
| Date       | Medium        | Count  |
|------------|---------------|--------|
| 2020-06-01 | INVITES       | 255,920|
| 2020-06-01 | OTHER         | 162,898|
| 2020-06-01 | PAID SEARCH   | 67,199 |
| 2020-06-01 | ORGANIC SEARCH| 66,286 |
| 2020-06-01 | PRIVATE_BOARD | 57,764 |
| 2020-06-01 | IMPRESSION    | 28,187 |
| 2020-06-01 | DIRECT        | 23,930 |
| 2020-06-01 | REFERRAL      | 21,183 |
| 2020-06-01 | SSO           | 6,272  |
| 2020-06-01 | MOBILE_POPUP  | 6,181  |
| 2020-06-01 | PAID SOCIAL   | 4,720  |
| 2020-06-01 | SOCIAL        | 1,833  |
| 2020-06-01 | DIRECTORIES   | 691    |
| 2020-06-01 | MARKETPLACE   | 556    |
| 2020-06-01 | MAIL          | 10     |
| 2020-06-01 | DISPLAY       | 1      |

Note relatively large 'OTHER' channel, it could be split into more fine-granular buckets for cases like `NO SESSIONS BEFORE REGISTRATION`, etc.

### f. Other Comments

The dbt repository doesn't cover the materialization of models. All models are set to be fully refreshed during each execution cycle. A better long-term strategy would be to implement incremental materializations that only update or insert new information, avoiding unnecessary reprocessing.

Another important dbt feature not used in this model is MetricFlow, which was recently introduced. The reporting layer could be updated to utilize this feature and showcase metrics like "number of users," sliceable by dimensions such as "day," "month," "channel," and "first channel," among others.


Thank you for this assignment, it was a great brain teaser!




















## Instructions:

We would like you to send us:
1. A .zip or repository link with files and instructions that can be used to reproduce your
results and re-run the model with a data set containing a different time window. That
repository should include all technical deliverables in point two

2. The technical deliverables of the project:
a. A set of models which will generate a three tier data model
(raw->integrated->ready for reporting). Data loading is not in scope for the
assignment, but can be included if desired
b. The tests used to validate the correctness and completeness of the data
c. The results of the attribution by channel and by month
d. Any technical documentation relating to the data, models, tests

3. Comments related to this assignment. Specifically, we would like to explain:
a. Your modeling methodology and why this approach was taken
b. If this problem was given without rules and examples, what your approach would
be to conduct requirements discovery
c. Your testing methodology and how you ensure data quality when
modeling/integrating data
d. How you would model this attribution data into a broader data warehouse model
e. Any other considerations you would have regarding how this data could be used
for reporting or analytics and caveats associated with it
f. Any other comments to either explain your work, thought process, or engineering
process


Here are the rules we want to implement:

- PAID click has a life span of 3 hours max
- PAID impression has a life span of 1 hour max
- Organic click had a life span of 12 hours
  
- paid sessions can NOT be "hijacked" during its life span by any other sessions
- organic click can be "hijacked" during its life span by paid sessions (click or impression, during its life span)
- if a sign up doesn't have any live session (paid or organic) it will be either Direct (if the medium is direct) or Others as a last resort
