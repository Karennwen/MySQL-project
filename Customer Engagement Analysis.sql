-- 1. Initialize the CTE that calculates the total minutes watched and the total number of students for each course.
WITH
title_total_minutes AS
(
   SELECT 
         365_course_info.course_id,
         365_course_info.course_title,
         round(sum(365_student_learning.minutes_watched),2) as total_minutes_watched,
         count(distinct 365_student_learning.student_id ) as num_students
  FROM 365_course_info 
  left join 365_student_learning on 365_course_info.course_id = 365_student_learning.course_id
  Group by course_id
),
-- 2. Initialize the CTE that calculates the average minutes watched for each course.
title_average_minutes as
(
   SELECT 
         course_id,
         course_title,
         total_minutes_watched,
         round(total_minutes_watched/num_students,2) as Average_minutes
   FROM
   title_total_minutes
),
-- 3. Initialize the CTE that calculates the average minutes watched for each course.
title_rating AS
(
   SELECT 
         365_course_info.course_id,
         365_course_info.course_title,
         title_total_minutes.total_minutes_watched,
         title_average_minutes.average_minutes,
         IFNULL(count(course_rating), 0) as number_of_ratings,
         IFNULL(round(avg(course_rating),2),0) as average_rating
  FROM 365_course_info
  Left join 365_course_ratings on 365_course_info.course_id = 365_course_ratings.course_id
  LEFT JOIN title_total_minutes ON 365_course_info.course_id = title_total_minutes.course_id
  LEFT JOIN title_average_minutes ON 365_course_info.course_id = title_average_minutes.course_id
  

  Group by course_id
)

SELECT * FROM title_rating;

-- 4. Dropping the purchases_info table before creating it
DROP VIEW IF EXISTS purchases_info;
-- 5. Retrieving Purchases Information that specity the start & end date of the subscription.
CREATE VIEW purchases_info AS
SELECT 
      purchase_id,
      student_id,
      purchase_type,
      date_purchased AS date_start,
 CASE
            WHEN purchase_type = 'Monthly' THEN DATE_ADD(date_purchased, INTERVAL 1 MONTH)
            WHEN purchase_type = 'Quarterly' THEN DATE_ADD(date_purchased, INTERVAL 3 MONTH)
            WHEN purchase_type = 'Annual' THEN DATE_ADD(date_purchased, INTERVAL 12 MONTH)
        END AS date_end
FROM 365_student_purchases;

-- 6. Retrieving information on how many minutes students watches each course
SELECT
    b.student_id,
    b.student_country,
    b.minutes_watched,
    b.onboarded,
    b.date_registered,
    b.date_watched,
    MAX(b.paid) AS paid
FROM
    (
SELECT
    a.*,
    IF(a.date_watched BETWEEN p.date_start AND p.date_end, 1, 0) AS paid
FROM
    (
SELECT
      365_student_info.student_id,
      365_student_info.student_country,
      365_student_info.date_registered,
      365_student_learning.date_watched,
      IFNULL(sum(365_student_learning.minutes_watched),0) as minutes_watched,
      IF(count(365_student_learning.student_id) > 0,1,0) as Onboarded
FROM 365_student_info
Left join 365_student_learning on 365_student_info.student_id = 365_student_learning.student_id
Group by 365_student_info.student_id,
      365_student_info.student_country,
      365_student_info.date_registered,
      365_student_learning.date_watched
      ) a
LEFT JOIN
    purchases_info p USING (student_id)
    ) b
GROUP BY
    b.student_id,
    b.student_country,
    b.minutes_watched,
    b.onboarded,
    b.date_registered,
    b.date_watched;



         