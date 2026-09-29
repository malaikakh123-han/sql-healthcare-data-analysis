USE hospital_management;

SELECT r.room_no, r.capacity
FROM rooms r
JOIN departments d
    ON r.department_id = d.department_id
WHERE d.name = 'Neurology';

SELECT *
FROM appointments
WHERE appointment_date >= CURDATE()
ORDER BY appointment_date;

SELECT
    p.patient_id,
    p.name,
    COUNT(a.appointment_id) AS appointment_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.name
HAVING COUNT(a.appointment_id) > 3
ORDER BY appointment_count DESC;

SELECT
    a.appointment_id,
    a.appointment_date,
    a.reason,
    p.name AS patient_name,
    d.name AS doctor_name
FROM appointments a
JOIN patients p
    ON a.patient_id = p.patient_id
JOIN doctors d
    ON a.doctor_id = d.doctor_id
ORDER BY a.appointment_date;

SELECT
    p.name AS patient_name,
    p.phone,
    a.appointment_date
FROM appointments a
JOIN patients p
    ON a.patient_id = p.patient_id
WHERE a.appointment_date >= '2026-08-01'
  AND a.appointment_date < '2026-09-01'
ORDER BY a.appointment_date, p.name;


SELECT
    medication_id,
    name,
    description
FROM medications
WHERE LOWER(description) LIKE '%pain%'
   OR LOWER(description) LIKE '%infection%';
   
   
   SELECT
    d.doctor_id,
    d.name,
    d.specialty,
    d.hospital_id
FROM doctors d
LEFT JOIN prescriptions pr
    ON d.doctor_id = pr.doctor_id
WHERE pr.prescription_id IS NULL
ORDER BY d.doctor_id;


SELECT
    h.hospital_id,
    h.name AS hospital_name,
    YEAR(a.appointment_date) AS appointment_year,
    MONTH(a.appointment_date) AS appointment_month,
    COUNT(a.appointment_id) AS appointment_count
FROM hospitals h
JOIN doctors d
    ON h.hospital_id = d.hospital_id
JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY
    h.hospital_id,
    h.name,
    YEAR(a.appointment_date),
    MONTH(a.appointment_date)
ORDER BY appointment_year, appointment_month, h.hospital_id;

WITH doctor_appointments AS (
    SELECT
        h.hospital_id,
        h.name AS hospital_name,
        d.doctor_id,
        d.name AS doctor_name,
        COUNT(a.appointment_id) AS appointment_count
    FROM hospitals h
    JOIN doctors d
        ON h.hospital_id = d.hospital_id
    LEFT JOIN appointments a
        ON d.doctor_id = a.doctor_id
    GROUP BY
        h.hospital_id,
        h.name,
        d.doctor_id,
        d.name
)
SELECT
    hospital_id,
    hospital_name,
    doctor_id,
    doctor_name,
    appointment_count,
    DENSE_RANK() OVER (
        PARTITION BY hospital_id
        ORDER BY appointment_count DESC
    ) AS doctor_rank
FROM doctor_appointments
ORDER BY hospital_id, doctor_rank, doctor_name;



SELECT
    d.doctor_id,
    d.name AS doctor_name,
    d.specialty,
    h.name AS hospital_name
FROM doctors d
JOIN hospitals h
    ON d.hospital_id = h.hospital_id
LEFT JOIN appointments a
    ON d.doctor_id = a.doctor_id
WHERE a.appointment_id IS NULL
ORDER BY h.hospital_id, d.doctor_id;


WITH ranked_appointments AS (
    SELECT
        a.appointment_id,
        a.patient_id,
        a.doctor_id,
        a.appointment_date,
        a.reason,
        ROW_NUMBER() OVER (
            PARTITION BY a.patient_id
            ORDER BY a.appointment_date DESC, a.appointment_id DESC
        ) AS rn
    FROM appointments a
)
SELECT
    ra.patient_id,
    p.name AS patient_name,
    ra.appointment_id,
    ra.appointment_date,
    ra.reason,
    d.name AS doctor_name
FROM ranked_appointments ra
JOIN patients p
    ON ra.patient_id = p.patient_id
JOIN doctors d
    ON ra.doctor_id = d.doctor_id
WHERE ra.rn <= 2
ORDER BY ra.patient_id, ra.appointment_date DESC;



SELECT
    p.name AS patient_name,
    p.dob,
    a.appointment_date,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, p.dob, a.appointment_date) <= 18
            THEN 'Pediatric'
        WHEN TIMESTAMPDIFF(YEAR, p.dob, a.appointment_date) BETWEEN 19 AND 64
            THEN 'Adult'
        ELSE 'Geriatric'
    END AS age_group
FROM appointments a
JOIN patients p
    ON a.patient_id = p.patient_id
WHERE a.reason = 'Emergency'
ORDER BY a.appointment_date, p.name;


SELECT
    p.name AS patient_name,
    p.phone,
    COUNT(a.appointment_id) AS appointment_count
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.name, p.phone
ORDER BY appointment_count DESC;



SELECT
    p.patient_id,
    p.name AS patient_name,
    COUNT(pr.prescription_id) AS prescription_count
FROM patients p
JOIN prescriptions pr
    ON p.patient_id = pr.patient_id
GROUP BY p.patient_id, p.name
ORDER BY prescription_count DESC;



SELECT
    d.doctor_id,
    d.name AS doctor_name,
    d.specialty,
    COUNT(pr.prescription_id) AS prescription_count
FROM doctors d
JOIN prescriptions pr
    ON d.doctor_id = pr.doctor_id
GROUP BY d.doctor_id, d.name, d.specialty
ORDER BY prescription_count DESC;



SELECT
    p.patient_id,
    p.name AS patient_name,
    MAX(a.appointment_date) AS last_appointment_date
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.name
ORDER BY last_appointment_date DESC;


SELECT
    d.doctor_id,
    d.name AS doctor_name,
    d.specialty,
    COUNT(a.appointment_id) AS appointment_count
FROM doctors d
JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.name, d.specialty
ORDER BY appointment_count DESC;


SELECT
    h.hospital_id,
    h.name AS hospital_name,
    COUNT(a.appointment_id) AS appointment_count
FROM hospitals h
JOIN doctors d
    ON h.hospital_id = d.hospital_id
JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY h.hospital_id, h.name
ORDER BY appointment_count DESC;


SELECT
    a.reason,
    COUNT(*) AS appointment_count
FROM appointments a
GROUP BY a.reason
ORDER BY appointment_count DESC;

WITH returning_patients AS (
    SELECT
        a.patient_id,
        a.appointment_id,
        a.appointment_date,
        LAG(a.appointment_date) OVER (
            PARTITION BY a.patient_id
            ORDER BY a.appointment_date, a.appointment_id
        ) AS previous_appointment_date
    FROM appointments a
)
SELECT
    rp.patient_id,
    p.name AS patient_name,
    rp.appointment_id,
    rp.previous_appointment_date,
    rp.appointment_date,
    DATEDIFF(
        rp.appointment_date,
        rp.previous_appointment_date
    ) AS days_between_appointments
FROM returning_patients rp
JOIN patients p
    ON rp.patient_id = p.patient_id
WHERE rp.previous_appointment_date IS NOT NULL
ORDER BY rp.patient_id, rp.appointment_date;


-- TASK 18
SELECT
    p.patient_id,
    p.name AS patient_name,
    COUNT(DISTINCT d.specialty) AS specialty_count,
    GROUP_CONCAT(
        DISTINCT d.specialty
        ORDER BY d.specialty
        SEPARATOR ', '
    ) AS specialties_seen
FROM patients p
JOIN appointments a
    ON p.patient_id = a.patient_id
JOIN doctors d
    ON a.doctor_id = d.doctor_id
GROUP BY p.patient_id, p.name
HAVING COUNT(DISTINCT d.specialty) > 1
ORDER BY specialty_count DESC, p.name;


-- TASK 19
WITH department_capacity AS (
    SELECT
        h.hospital_id,
        h.name AS hospital_name,
        d.department_id,
        d.name AS department_name,
        COALESCE(SUM(r.capacity), 0) AS total_room_capacity
    FROM departments d
    JOIN hospitals h
        ON d.hospital_id = h.hospital_id
    LEFT JOIN rooms r
        ON d.department_id = r.department_id
    GROUP BY
        h.hospital_id,
        h.name,
        d.department_id,
        d.name
),
ranked_departments AS (
    SELECT
        hospital_id,
        hospital_name,
        department_id,
        department_name,
        total_room_capacity,
        DENSE_RANK() OVER (
            PARTITION BY hospital_id
            ORDER BY total_room_capacity DESC
        ) AS capacity_rank
    FROM department_capacity
)
SELECT
    hospital_id,
    hospital_name,
    department_id,
    department_name,
    total_room_capacity
FROM ranked_departments
WHERE capacity_rank = 2
ORDER BY hospital_id, department_name;

-- BONUS 1
WITH specialty_counts AS (
    SELECT
        h.hospital_id,
        h.name AS hospital_name,
        d.specialty,
        COUNT(*) AS doctor_count
    FROM doctors d
    JOIN hospitals h
        ON d.hospital_id = h.hospital_id
    GROUP BY h.hospital_id, h.name, d.specialty
),
ranked_specialties AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY specialty
            ORDER BY doctor_count DESC
        ) AS specialty_rank
    FROM specialty_counts
)
SELECT
    specialty,
    hospital_id,
    hospital_name,
    doctor_count
FROM ranked_specialties
WHERE specialty_rank = 1
ORDER BY specialty, hospital_name;

-- BONUS 2
SELECT
    d.department_id,
    d.name AS department_name,
    h.name AS hospital_name,
    ROUND(AVG(r.capacity), 2) AS average_room_capacity
FROM departments d
JOIN hospitals h
    ON d.hospital_id = h.hospital_id
JOIN rooms r
    ON d.department_id = r.department_id
GROUP BY
    d.department_id,
    d.name,
    h.name
ORDER BY average_room_capacity DESC;


-- BONUS 3
SELECT
    YEAR(appointment_date) AS appointment_year,
    MONTH(appointment_date) AS appointment_month,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY YEAR(appointment_date), MONTH(appointment_date)
ORDER BY appointment_year, appointment_month;



-- BONUS 4
SELECT
    reason,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY reason
ORDER BY appointment_count DESC;



-- BONUS 5
SELECT
    h.hospital_id,
    h.name AS hospital_name,
    COUNT(a.appointment_id) AS total_appointments
FROM hospitals h
LEFT JOIN doctors d
    ON h.hospital_id = d.hospital_id
LEFT JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY h.hospital_id, h.name
ORDER BY total_appointments DESC;